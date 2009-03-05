# Note: we use fields and elements interchangeably from time to time.
#       They mean the same thing: some input field in a form.
module RFormation

  # A regular exception but with a line number attached
  class FormError < Exception

    attr_accessor :line_number
    
    def initialize(message, line_number = nil)
      super(message)
      @line_number = line_number
    end

    def self.extract_line_number(trace)
      line = trace.grep(/FORM_DSL/).first
      line[/\d+/].to_i
    end

  end
  
  class Element
    
    def initialize(lists_of_values, parent, &blk)
      @lists_of_values = lists_of_values
      @parent = parent
      instance_eval(&blk)
      @lists_of_values = nil
    end
    
    def register_element(element, name)
      @parent.register_element(element, name)
    end
    
    def register_resolver(&resolver)
      @parent.register_resolver(&resolver)
    end
    
  end
  
  # Superclass for anything that can have a list of items. Currently includes
  # Form, Group and Condition.
  class ContainerElement < Element
    
    def initialize(*a)
      @items = []
      super
    end
    
  end
  
  # I'm using this for extensibility. The list of supported elements is
  # no longer hardcoded like this.
  def self.register_type(name, cl)
    ContainerElement.class_eval %{
      def #{name}(*a, &blk)
        @items << #{cl}.new(@lists_of_values, self, *a, &blk)
      end
    }
  end
  
  # Module for anything that can have a label.
  module Labeled
    
    def initialize(*a)
      @label = nil
      super
      @label ||= @name
    end
    
    def label(label)
      @label = label
      def self.label(*a) ; raise FormError, "specified a label twice" ; end
    end
    
  end
  
  # Module for anything that can have a name. These elements
  # need to be registered because they can be referred to in
  # conditions and validations.
  module Named
    
    def initialize(*a)
      super
      @id, @variable = register_element(self, @name)
    end
    
  end
  
  # Module for anything that can have validations.
  module Validated
    
    def initialize(*a)
      @validations = []
      @error_messages = []
      @parsed_validations = []
      super
      register_resolver do |element_info|
        begin
          @fields_of_interest = []
          @parsed_validations.each do |parsed_validation|
            @fields_of_interest.concat(parsed_validation.resolve(element_info))
          end
          @fields_of_interest.uniq!
          methods.each do |m|
            if /\Atranslate_validations_to_/ === m
              send(m, element_info)
            end
          end
          @parsed_validations = nil
        rescue FormError => e
          e.line_number = @line_number
          raise
        end
      end
    end
    
    def validate(condition, error_message)
      @validations << condition
      @error_messages << error_message
      @line_number = FormError.extract_line_number(caller)

      parser = ConditionParser.new
      unless parsed_condition = parser.parse(condition)
        raise FormError.new(parser.failure_reason, @line_number)
      end
      @parsed_validations << parsed_condition
    end
    
  end
  
  module Requirable
    
    def mandatory
      validate("%s is not empty" % RFormation::ConditionAST::String.escape_back_string_syntax(@name), "is mandatory")
    end
    
  end
  
  # The global form
  class Form < ContainerElement

    # The main method to compile a form DSL. This returns a Form object
    # that can be used to generate HTML from.
    # It takes the string containing the DSL definition and some options
    # as parameters.
    # The only option currently allowed is :lists_of_values which should
    # contain an object that reponds to [] and that returns true (or
    # something that evaluates as true in Ruby) if a list of values with
    # a given name exists. This can be a hash, but also a Proc object.
    def initialize(str, options = {})
      lists_of_values = options.delete(:lists_of_values) || proc {}
      options.empty? or raise "unknown options #{options.keys.join(", ")}"
      
      @elements = {}
      @resolvers = []
      super(lists_of_values, nil) do
        eval_string(str)
      end
      @resolvers.each { |resolver| resolver.call(@elements) }
      @resolvers = nil
    rescue FormError => e
      # To generate a cleaner backtrace
      raise FormError.new(e.message, e.line_number)
    end

    def register_element(element, name)
      i = @elements.length + 1
      id = "rformationElement#{i}"
      variable = "rformationElement#{i}"
      @elements[name] = [element, variable]
      [id, variable]
    end
    
    def register_resolver(&resolver)
      @resolvers << resolver
    end
    
  private

    def eval_string(str)
      eval str, nil, "FORM_DSL", 1
    rescue Exception => e
      # Raise a more readable error message containing a line number.
      # Always raises a FormError no matter what specific error
      # happened, but it does retain the message.
      if NoMethodError === e || NameError === e
        message = "unknown keyword #{e.name}"
      else
        message = e.message.dup
      end
      line_number = FormError.extract_line_number(e.backtrace)
      error = FormError.new(message)
      error.line_number = line_number
      raise error
    end
    
  end
  
  # A group with a caption
  class Group < ContainerElement

    def initialize(lists_of_values, parent, caption, &blk)
      @caption = caption
      super(lists_of_values, parent, &blk)
    end
    
  end

  register_type :group, Group

  # The generic subclass of drop-down select boxes and groups of radio buttons
  class Select < Element
    
    include Named
    include Validated
    include Labeled
    include Requirable
    
    # TODO: clean this up somewhat. I like the way it is set up now
    #       with the singleton methods because now it explicitly says
    #       how methods will behave once a given method is called,
    #       but at the moment it is a bit messy. Also, it is not entirely
    #       DRY.
    def initialize(lists_of_values, parent, name, type = nil, &blk)
      @name = name
      @entries = []
      @has_id = {}
      @generator = nil
      @default = nil
      @type = type
      case type
      when :auto_number
        def self.values ; raise FormError, "using user-defined naming so cannot use this option" ; end
        def self.value(label, *a)
          default = a.delete(:default)
          raise FormError, "unknown options #{a.inspect}" unless a.empty?
          id = (@entries.size + 1).to_s
          @entries << [id, label, default]
          raise FormError, "two defaults specified" if @default && default
          @default ||= default
        end
      when :identity, nil
        if type == :identity
          def self.values ; raise FormError, "using user-defined naming so cannot use this option" ; end
        else
          def self.values(generator)
            @generator = generator
            @lists_of_values[generator] or raise FormError, "list of values named #{generator} not found"
            def self.values ; raise FormError, "specified a list of values twice" ; end
            def self.value(*a) ; raise FormError, "using pre-defined list of values so cannot use this option" ; end
          end
        end
        def self.value(label, *a)
          default = a.delete(:default)
          raise FormError, "unknown options #{a.inspect}" unless a.empty?
          @entries << [label, label, !!default]
          raise FormError, "two defaults specified" if @default && default
          @default ||= default
          def self.values ; raise FormError, "using user-defined naming so cannot use this option" ; end
        end
      when :auto_id
        def self.values ; raise FormError, "specified user-defined naming so cannot use this option" ; end
        def self.value(label, *a)
          default = a.delete(:default)
          raise FormError, "unknown options #{a.inspect}" unless a.empty?
          id = label.downcase.gsub(/[^A-Za-z0-9_-]/, '_')
          @entries << [id, label, !!default]
          raise FormError, "two defaults specified" if @default && default
          @default ||= default
        end
      when :self
        def self.values ; raise FormError, "specified user-defined naming so cannot use this option" ; end
        def self.value(label, id, *a)
          default = a.delete(:default)
          raise FormError, "unknown options #{a.inspect}" unless a.empty?
          @entries << [id, label, !!default]
          raise FormError, "two defaults specified" if @default && default
          @default ||= default
        end
      else
        raise FormError, "illegal specifier #{type.inspect} for id generation (should be one of :auto_number, :auto_id, :self)"
      end
      super(lists_of_values, parent, &blk)
    end
    
    def entries(lists_of_values)
      (@generator ? lists_of_values[@generator] : @entries) or raise FormError, "list of values named #{@generator} not found"
    end
    
  end
  
  class DropdownSelect < Select
  end
  
  register_type :select, DropdownSelect
  
  class RadioSelect < Select
  end
  
  register_type :radio, RadioSelect
  
  # A plain text field.
  # An option turns it into a multi-line text field = a text area.
  class Text < Element
    
    include Named
    include Validated
    include Labeled
    include Requirable
    
    def initialize(lists_of_values, parent, name, *a, &blk)
      @multi = a.delete(:multi)
      a.empty? or raise FormError, "unknown options #{a.inspect}"
      @name = name
      @value = nil
      super(lists_of_values, parent, &(blk || proc {}))
    end
    
    def value(value)
      @value = value
      def self.value(*a) ; raise FormError, "specified a value twice" ; end
    end
    
  end
  
  register_type :text, Text
  
  # File upload field
  class File < Element
    
    include Named
    include Validated
    include Labeled
    include Requirable
    
    def initialize(lists_of_values, parent, name, &blk)
      @name = name
      super(lists_of_values, parent, &(blk || proc {}))
    end
    
    def min_size(min_size)
      @min_size = parse_size(min_size)
      def self.min_size(*a) ; raise FormError, "specified a minimum size twice" ; end
    end
    
    def max_size(max_size)
      @max_size = parse_size(max_size)
      def self.max_size(*a) ; raise FormError, "specified a maximum size twice" ; end
    end
    
    def parse_size(size)
      if Integer === size
        size
      elsif /\A(\d+)(kb?|mb?|gb?)\z/i === size
        multiplier = { "kb" => 2**10, "mb" => 2**20, "gb" => 2**30, "k" => 2**10, "m" => 2**20, "g" => 2**30 }[$2]
        $1.to_i * multiplier
      else
        raise FormError, "unrecognize file size"
      end
    end
    
  end
  
  register_type :file, File
  
  # A field that just displays some informative text.
  class Info < Element
    
    def initialize(lists_of_values, parent, text)
      @text = text
      super(lists_of_values, parent) {}
    end
    
  end
  
  register_type :info, Info
  
  # Insert a link to for instance more information
  class Link < Element
    
    include Labeled

    def initialize(lists_of_values, parent, url)
      @name = @url = url
      super(lists_of_values, parent)
    end
    
  end
  
  register_type :link, Link
  
  # A checkbox
  class CheckBox < Element
    
    include Named
    include Validated
    include Labeled
    
    def initialize(lists_of_values, parent, name, &blk)
      @name = name
      @on_by_default = nil
      super(lists_of_values, parent, &(blk || proc {}))
    end
    
    # These two methods are there for convenience so you can say "default on"
    # rather thab "default true"
    def on
      true
    end
    
    def off
      false
    end
    
    def default(on_by_default)
      @on_by_default = on_by_default
      def self.default(*a) ; raise FormError, "specified default state twice" ; end
    end
    
  end
  
  register_type :box, CheckBox
  
  class Hidden < Element
    
    include Named
    
    def initialize(lists_of_values, parent, name, value)
      @name = name
      @value = value
    end
    
  end
  
  register_type :hidden, Hidden
  
  # The portion included in a condition is shown conditionally.
  class Conditional < ContainerElement
    
    def initialize(lists_of_values, parent, condition, &blk)
      @condition = condition
      @line_number = FormError.extract_line_number(caller)
      
      parser = ConditionParser.new
      unless @parsed_condition = parser.parse(@condition)
        raise FormError.new(parser.failure_reason, @line_number)
      end

      super(lists_of_values, parent, &blk)
      register_resolver do |element_info|
        begin
          @fields_of_interest = @parsed_condition.resolve(element_info)
          methods.each do |m|
            if /\Atranslate_condition_to_/ === m
              send(m, element_info)
            end
          end
          @parsed_condition = nil
        rescue FormError => e
          e.line_number = @line_number
          raise
        end
      end
    end
    
  end
  
  register_type :condition, Conditional

end
