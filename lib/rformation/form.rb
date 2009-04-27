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
      instance_eval(&blk)
    end
    
    def propagate_sticky_classes
    end
    
  end
  
  # Superclass for anything that can have a list of items. Currently includes
  # Form, Group and Condition.
  class ContainerElement < Element
    
    def initialize
      @items = []
      super
    end
    
    def propagate_sticky_classes
      @items.each { |item| item.propagate_sticky_classes }
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
  
  # Module for anything for which the class can be set
  module Classy
    
    def initialize(&blk)
      @sticky_classes = {}
      @class = ""
      super
    end
    
    def field_class(*classes)
      sticky, regular = classes.partition { |cl| Hash === cl }
      @class << " " << regular.join(" ")
      sticky.each { |cls| @sticky_classes.merge!(cls) }
    end
    
    alias field_classes field_class
    
    def propagate_sticky_classes
      sticky = context[:sticky_classes].merge(@sticky_classes)
      @class << " " << sticky.values.flatten.join(" ")
      with_context :sticky_classes => sticky do
        super
      end
    end
    
  end
  
  # Module for anything that can have a label.
  module Labeled
    
    def initialize
      @label = @name
      super
    end
    
    def label(label)
      @label = label
      def self.label(*a) ; raise FormError, "specified a label twice" ; end
    end
    
  end
  
  # Module for anything that can have a name.
  module Named
    
    def initialize(name)
      @name = name
      @path = Named.name_to_trail(name, context[:object_scope])
      super()
    end
    
    def self.name_to_trail(name, object_scope)
      if name[0] == ?&
        name = name[1..-1]
        absolute = true
      end
      (absolute ? [] : object_scope) + name.split(/&/)
    end
    
  end
  
  # Module for anything that can have validations.
  module Validated
    
    def initialize
      @validations = []
      @error_messages = []
      @parsed_validations = []
      super
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
    
    def mandatory(message = "is mandatory")
      @mandatory = true
      validate("%s is not empty" % RFormation::ConditionAST::String.escape_back_string_syntax(@name), message)
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
      classes = options.delete(:element_classes) || {}
      if style = options.delete(:style)
        classes[:style] = style
      end
      options.empty? or raise "unknown options #{options.keys.join(", ")}"
      
      with_context(:lists_of_values => lists_of_values, :object_scope => []) do
        super() do
          if str
            eval_string(str)
          else
            instance_eval(&blk)
          end
        end
      end
      
      with_context(:sticky_classes => classes) do
        propagate_sticky_classes
      end
      resolve_form_references
    rescue FormError => e
      # To generate a cleaner backtrace
      raise FormError.new(e.message, e.line_number)
    end

  private

    def eval_string(str)
      eval str, nil, "FORM_DSL", 1
    rescue Exception => e
      # Raise a more readable error message containing a line number.
      # Always raises a FormError no matter what specific error
      # happened, but it does retain the message.
      if NameError === e
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

    include Classy

    def initialize(caption, &blk)
      @caption = caption
      @styled = false
      super(&blk)
    end
    
    def style(style)
      raise FormError, "duplicate style specification" if @styled
      @styled = true
      field_class(:style => style)
    end
    
  end

  register_type :group, Group

  # The generic subclass of drop-down select boxes and groups of radio buttons
  class Select < Element
    
    include Classy
    include Validated
    include Labeled
    include Requirable
    include Named
    
    # TODO: clean this up somewhat. I like the way it is set up now
    #       with the singleton methods because now it explicitly says
    #       how methods will behave once a given method is called,
    #       but at the moment it is a bit messy. Also, it is not entirely
    #       DRY.
    def initialize(name, *a, &blk)
      @type = a.delete(:auto_number) || a.delete(:identity) || a.delete(:auto_id) || a.delete(:self)
      a.empty? or raise FormError, "unknown options #{a.inspect}"
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
      super(name, &blk)
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
    
    SMALL_WIDTH = 20
    SMALL_HEIGHT = 3
    
    MEDIUM_WIDTH = 35
    MEDIUM_HEIGHT = 7
    
    LARGE_WIDTH = 50
    LARGE_HEIGHT = 15
    
    include Classy
    include Validated
    include Labeled
    include Requirable
    include Named
    
    def initialize(name, *a, &blk)
      if @multi = a.delete(:multi)
        def self.width(width)
          @width = width
          def self.width(*a) ; raise FormError, "specified a width twice" ; end
        end
        def self.height(height)
          @height = height
          def self.height(*a) ; raise FormError, "specified a height twice" ; end
        end
        def self.small
          width(SMALL_WIDTH)
          height(SMALL_HEIGHT)
        end
        def self.medium
          width(MEDIUM_WIDTH)
          height(MEDIUM_HEIGHT)
        end
        def self.large
          width(LARGE_WIDTH)
          height(LARGE_HEIGHT)
        end
      end
      a.empty? or raise FormError, "unknown options #{a.inspect}"
      @value = nil
      super(name, &(blk || proc {}))
    end
    
    def value(value)
      @value = value
      def self.value(*a) ; raise FormError, "specified a value twice" ; end
    end
    
  end
  
  register_type :text, Text
  
  # File upload field
  class File < Element
    
    include Classy
    include Validated
    include Labeled
    include Requirable
    include Named
    
    def initialize(name, &blk)
      super(name, &(blk || proc {}))
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
      elsif /\A(\d+)(|kb?|mb?|gb?)\z/i === size
        multiplier = { "" => 1, "kb" => 2**10, "mb" => 2**20, "gb" => 2**30, "k" => 2**10, "m" => 2**20, "g" => 2**30 }[$2]
        $1.to_i * multiplier
      else
        raise FormError, "unrecognize file size"
      end
    end
    
  end
  
  register_type :file, File
  
  # A field that just displays some informative text.
  class Info < Element
    
    include Classy

    def initialize(text)
      @text = text
      super() {}
    end
    
  end
  
  register_type :info, Info
  
  # Insert a link to for instance more information
  class Link < Element
    
    include Classy
    include Labeled

    def initialize(url, &blk)
      @name = @url = url
      super(&(blk || proc {}))
    end
    
  end
  
  register_type :link, Link
  
  # A checkbox
  class CheckBox < Element
    
    include Classy
    include Validated
    include Labeled
    include Requirable
    include Named
    
    def initialize(name, &blk)
      @on_by_default = nil
      super(name, &(blk || proc {}))
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
    
    def mandatory(message = "is mandatory")
      @mandatory = true
      validate("%s is on" % RFormation::ConditionAST::String.escape_back_string_syntax(@name), message)
    end
    
  end
  
  register_type :box, CheckBox
  
  class Hidden < Element
    
    include Named
    
    def initialize(name, value, &blk)
      @value = value
      super(name) {}
    end
    
  end
  
  register_type :hidden, Hidden
  
  class Object < ContainerElement
    
    def initialize(name, &blk)
      @path = Named.name_to_trail(name, context[:object_scope])
      with_context(:object_scope => @path) do
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
      
      parser = ConditionParser.new
      unless @parsed_condition = parser.parse(@condition)
        raise FormError.new(parser.failure_reason, @line_number)
      end

      super(&blk)
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

__END__

text "a" do
  mandatory
end
condition "a equals 1" do
  text "b"
  condition "b equals 2" do
    group "group" do
      text "c"
      condition "c equals 3" do
        text "d"
      end
    end
  end
end
box "e"
condition "d equals 4 and e is on" do
  radio "f" do
    value "a"
    value "b"
    value "c"
  end
end
