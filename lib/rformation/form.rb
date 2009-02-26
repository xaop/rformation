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
    
    def register_conditional(conditional)
      @parent.register_conditional(conditional)
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
  
  def self.register_type(name, cl)
    ContainerElement.class_eval %{
      def #{name}(*a, &blk)
        @items << #{cl}.new(@lists_of_values, self, *a, &blk)
      end
    }
  end
  
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
  
  module Named
    
    def initialize(*a)
      super
      @id = register_element(self, @name)
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
      @conditionals = []
      super(lists_of_values, nil) do
        eval_string(str)
      end
      @conditionals.each { |c| c.resolve_condition(@elements) }
    end

    def register_element(element, name)
      i = @elements.length + 1
      id = "$element#{i}"
      variable = "element#{i}"
      @elements[name] = [element, variable, id]
      id
    end
    
    def register_conditional(conditional)
      @conditionals << conditional
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
    include Labeled
    
    def initialize(lists_of_values, parent, name, type = nil, &blk)
      @name = name
      @entries = []
      @has_id = {}
      @generator = nil
      @default = nil
      @type = type
      case type
      when :auto_number
        def self.values ; raise FormError, "specified auto numbering so cannot use this option" ; end
      when :auto_id
        def self.values ; raise FormError, "specified auto numbering so cannot use this option" ; end
        def self.value(label, *a)
          default = a.delete(:default)
          raise FormError, "unknown options #{a.inspect}" unless a.empty?
          id = label.downcase.gsub(/[^A-Za-z0-9_-]/, '_')
          @entries << [id, label, default]
          raise FormError, "two defaults specified" if @default && default
          @default ||= default
        end
      when :self
        def self.values ; raise FormError, "specified auto numbering so cannot use this option" ; end
        def self.value(id, label, *a)
          default = a.delete(:default)
          raise FormError, "unknown options #{a.inspect}" unless a.empty?
          @entries << [id, label]
          raise FormError, "two defaults specified" if @default && default
          @default ||= default
        end
      when nil
      else
        raise FormError, "illegal specifier #{type.inspect} for id generation (should be one of :auto_number, :auto_id, :self)"
      end
      super(lists_of_values, parent, &blk)
    end
    
    def values(generator)
      @generator = generator
      @lists_of_values[generator] or raise FormError, "list of values named #{generator} not found"
      def self.values ; raise FormError, "specified a list of values twice" ; end
      def self.value(*a) ; raise FormError, "cannot both define explicit values and use a predefined list of values" ; end
    end
    
    # The auto_numbering form
    def value(label, *a)
      default = a.delete(:default)
      raise FormError, "unknown options #{a.inspect}" unless a.empty?
      id = (@entries.size + 1).to_s
      @entries << [id, label, default]
      raise FormError, "two defaults specified" if @default && default
      @default ||= default
      def self.values(*a) ; raise FormError, "cannot both define explicit values and use a predefined list of values" ; end unless @type
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
    include Labeled
    
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
  
  class File < Element
    
    include Named
    include Labeled
    
    def initialize(lists_of_values, parent, name, &blk)
      @name = name
      super(lists_of_values, parent, &(blk || proc {}))
    end
    
  end
  
  register_type :file, File
  
  class Info < Element
    
    def initialize(lists_of_values, parent, text)
      @text = text
      super(lists_of_values, parent) {}
    end
    
  end
  
  register_type :info, Info
  
  class CheckBox < Element
    
    include Named
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
      register_conditional(self)
    end
    
    def resolve_condition(em)
      @js_condition = @parsed_condition.to_js(em)
      @parsed_condition = nil
    end
    
  end
  
  register_type :condition, Conditional

end
