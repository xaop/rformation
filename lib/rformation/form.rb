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
  
  module Contextual

    # Context-based programming. Simplifies these tree-walking
    # algorithms.
    def context
      Thread.current[:rformation_context] ||= {}
    end
    
    def context=(context)
      Thread.current[:rformation_context] = context
    end
    
    def with_context(map)
      old_context = self.context
      self.context = old_context.merge(map)
      yield
    ensure
      self.context = old_context
    end
    
  end
  
  class Element
    
    include Contextual
    
    def initialize(&blk)
      @class = ""
      instance_eval(&blk)
    end
    
    def register_element(element, name)
      context[:form].register_element(element, name)
    end
    
    def register_resolver(&resolver)
      context[:form].register_resolver(&resolver)
    end
    
    def fetch_value_by_trail
      get_value_by_trail(context[:data], @object_trail)
    end
    
    def get_value_by_trail(data, trail)
      res = data
      trail.each do |k|
        if res.is_a?(Hash)
          return nil unless res.has_key?(k)
          res = res[k]
        else
          return nil unless res.respond_to?(k)
          res = res.send(k)
        end
      end
      res
    end
    
    def set_value_by_trail(value)
      data = context[:result]
      @object_trail[0..-2].each do |k|
        data = data[k] ||= {}
      end
      data[@object_trail[-1]] = value
    end
    
    def field_class(*classes)
      @class << " " << classes.join(" ")
    end
    
    alias field_classes field_class
    
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
        @items << #{cl}.new(*a, &blk)
      end
    }
  end
  
  # Module for anything that can have a label.
  module Labeled
    
    def initialize(*a)
      @label = @name
      super
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
      @object_trail = ((context[:object_trail] || []) + [@name])
      if prefix = context[:object_prefix]
        @name = "#{prefix}[#{@name}]"
      end
      @name = @name + "[]" if @multivalue
      @id, @variable = register_element(self, @name)
    end
    
  end
  
  # Module for anything that can have validations.
  module Validated
    
    def initialize(*a)
      @validations = []
      @error_messages = []
      @parsed_validations = []
      @object_trail_context = context[:object_trail]
      @object_trail_root = context[:object_trail_root]
      super
      register_resolver do
        begin
          fields_of_interest = []
          with_context :object_trail => @object_trail_context, :object_trail_root => @object_trail_root do
            @parsed_validations.each do |parsed_validation|
              fields_of_interest.concat(parsed_validation.resolve)
            end
          end
          fields_of_interest.uniq!
          @actor_index = context[:actor2els].size
          context[:actor2els][self] = fields_of_interest unless fields_of_interest.empty?
          methods.each do |m|
            if /\Atranslate_validations_to_/ === m
              send(m)
            end
          end
          @parsed_validations = nil
        rescue FormError => e
          e.line_number = @line_number
          raise
        end
      end
    end
    
    def validate(condition, error_message = nil)
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
    
    def initialize(&blk)
      @mandatory = false
      @mandatory_message = "is mandatory"
      super
      validate("%s is not empty" % RFormation::ConditionAST::String.escape_back_string_syntax(@name), @mandatory_message) if @mandatory
    end
    
    def mandatory
      @mandatory = true
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
    # something that evaluates to true in Ruby) if a list of values with
    # a given name exists. This can be a hash, but also a Proc object.
    def initialize(*a, &blk)
      if a.last.is_a?(Hash)
        options = a.pop
      else
        options = {}
      end
      case a.length
      when 0
        # Will use block
      when 1
        str = a.first
        warn "block not used" if blk
      else
        raise ArgumentError, "wrong number of arguments"
      end
      lists_of_values = options.delete(:lists_of_values) || proc {}
      filename = options.delete(:filename) || "FORM_DSL"
      options.empty? or raise "unknown options #{options.keys.join(", ")}"
      
      @elements = {}
      @resolvers = []
      with_context(:lists_of_values => lists_of_values, :form => self) do
        super() do
          if str
            eval_string(str)
          else
            instance_eval(&blk)
          end
        end
      end
      @actor2els = {}
      with_context :actor2els => @actor2els, :elements => @elements do
        @resolvers.each { |resolver| resolver.call }
      end
      @resolvers = nil
    # rescue FormError => e
    #   # To generate a cleaner backtrace
    #   raise FormError.new(e.message, e.line_number)
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
    # rescue Exception => e
    #   # Raise a more readable error message containing a line number.
    #   # Always raises a FormError no matter what specific error
    #   # happened, but it does retain the message.
    #   if NoMethodError === e || NameError === e
    #     message = "unknown keyword #{e.name}"
    #   else
    #     message = e.message.dup
    #   end
    #   line_number = FormError.extract_line_number(e.backtrace)
    #   error = FormError.new(message)
    #   error.line_number = line_number
    #   raise error
    end
    
  end
  
  # A group with a caption
  class Group < ContainerElement

    def initialize(caption, &blk)
      @caption = caption
      super(&blk)
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
    def initialize(name, *a, &blk)
      @type = a.delete(:auto_number) || a.delete(:identity) || a.delete(:auto_id) || a.delete(:self)
      a.empty? or raise FormError, "unknown options #{a.inspect}"
      @name = name
      @entries = []
      @has_id = {}
      @generator = nil
      @default = nil
      case @type
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
        if @type == :identity
          def self.values ; raise FormError, "using user-defined naming so cannot use this option" ; end
        else
          def self.values(generator)
            @generator = generator
            context[:lists_of_values][generator] or raise FormError, "list of values named #{generator} not found"
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
      super(&blk)
    end
    
    def entries(lists_of_values)
      (@generator ? lists_of_values[@generator] : @entries) or raise FormError, "list of values named #{@generator} not found"
    end
    
  end
  
  class DropdownSelect < Select
    
    def initialize(name, *a, &blk)
      @multivalue = a.delete(:multi)
      super
    end
    
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
    
    def initialize(name, *a, &blk)
      @multi = a.delete(:multi)
      a.empty? or raise FormError, "unknown options #{a.inspect}"
      @name = name
      @value = nil
      super(&(blk || proc {}))
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
    
    def initialize(name, &blk)
      @name = name
      super(&(blk || proc {}))
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
    
    def initialize(text)
      @text = text
      super() {}
    end
    
  end
  
  register_type :info, Info
  
  # Insert a link to for instance more information
  class Link < Element
    
    include Labeled

    def initialize(url, &blk)
      @name = @url = url
      super(&(blk || proc {}))
    end
    
  end
  
  register_type :link, Link
  
  # A checkbox
  class CheckBox < Element
    
    include Named
    include Validated
    include Labeled
    include Requirable
    
    def initialize(name, &blk)
      @name = name
      @on_by_default = nil
      super(&(blk || proc {}))
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
    
    def initialize(name, value, &blk)
      @name = name
      @value = value
      super() {}
    end
    
    def js_setup_for_element(actors)
      # Nothing to do as a hidden field normally should not change value.
    end

  end
  
  register_type :hidden, Hidden
  
  class Object < ContainerElement
    
    def initialize(name, *options, &blk)
      @root = options.delete(:root)
      fix = options.delete(:fix)
      @name = name
      old_object_prefix = context[:object_prefix]
      old_object_trail = context[:object_trail] || []
      object_prefix = (@root || !old_object_prefix) ? name : "#{old_object_prefix}[#{name}]"
      object_trail = (old_object_trail << name)
      object_trail_root = fix ? object_trail.dup : context[:object_trail_root]
      with_context(:object_prefix => object_prefix, :object_trail => object_trail, :object_trail_root => object_trail_root) do
        super(&blk)
      end
    end
    
  end
  
  register_type :object, Object
  
  # The portion included in a condition is shown conditionally.
  class Conditional < ContainerElement
    
    def initialize(condition, &blk)
      @condition = condition
      @line_number = FormError.extract_line_number(caller)
      @object_trail_context = context[:object_trail]
      @object_trail_root = context[:object_trail_root]
      
      parser = ConditionParser.new
      unless @parsed_condition = parser.parse(@condition)
        raise FormError.new(parser.failure_reason, @line_number)
      end

      super(&blk)
      register_resolver do
        begin
          with_context :object_trail => @object_trail_context, :object_trail_root => @object_trail_root do
            context[:actor2els][self] = @parsed_condition.resolve
          end
          @actor_index = context[:actor2els].size - 1
          methods.each do |m|
            if /\Atranslate_condition_to_/ === m
              send(m)
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

  class ContainerElement
    
    def otherwise(&blk)
      if @items.last.is_a?(::RFormation::Conditional)
        condition("not (%s)" % (@items.last.instance_eval { @condition }), &blk)
      else
        raise FormError.new("'otherwise' only allowed right after 'condition'")
      end
    end
    
  end

end
