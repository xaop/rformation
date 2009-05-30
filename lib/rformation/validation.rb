module RFormation

  class ValidationError < ::Exception
    
    attr_reader :errors
    
    def initialize(errors)
      @errors = errors
      super(errors.map { |field, error| "%s : %s" % [field, error.join(', ')] }.join("; "))
    end
    
  end
  
  class Form
    
    def validate_form(data)
      result = {}
      errors = Hash.new { |h, k| h[k] = [] }
      with_context :data => data, :result => result, :errors => errors do
        validate_fields
      end
      raise ValidationError, errors unless errors.empty?
      result
    end
    
  end
  
  class Element
    
    def fetch_value_by_path(default = nil)
      get_value_by_path(context[:data], @path, default)
    end
    
    def get_value_by_path(data, trail, default = nil)
      res = data
      trail.each do |k|
        if res.is_a?(Hash)
          return default unless res.has_key?(k)
          res = res[k]
        else
          return default unless res.respond_to?(k)
          res = res.send(k)
        end
      end
      res
    end
    
    def set_value_by_path(value)
      data = context[:result]
      @path[0..-2].each do |k|
        data = data[k] ||= {}
      end
      data[@path[-1]] = value
    end
    
    def validate_fields
    end

    def rb_boolean_value
      raise FormError, "field #{@name.inspect} does not have a boolean value"
    end
    
    def rb_string_value
      raise FormError, "field #{@name.inspect} does not have a string value"
    end
    
  end
  
  class ContainerElement
    
    def validate_fields
      @items.each do |item|
        item.validate_fields
      end
    end
    
  end
  
  class ElementListPart
    
    def rb_string_value
      elements.each do |el|
        return el.rb_string_value
      end
      result = "nil"
      conditions.to_a.reverse.each do |cond, element|
        result = "(%s ? %s : %s)" % [cond.rb_condition, element.rb_string_value, result]
      end
      result
    end
    
    def rb_boolean_value
      elements.each do |el|
        return el.rb_boolean_value
      end
      result = "nil"
      conditions.to_a.reverse.each do |cond, element|
        result = "(%s ? %s : %s)" % [cond.rb_condition, element.rb_boolean_value, result]
      end
      result
    end
    
  end
  
  module Named
    
    def validate_fields
      super
      set_value_by_path(fetch_value_by_path)
    end
    
    def rb_string_value
      "get_value_by_path(data, #{@path.inspect}) || nil"
    end
    
  end
  
  module Validated
    
    def validate_fields
      data = context[:data]
      @rb_conditions.zip(@error_messages).each do |cond, error_msg|
        context[:errors][@label] << (error_msg || "error in field") unless eval(cond)
      end
      super
    end
    
    def translate_validations_to_rb
      @rb_conditions = @parsed_validations.map { |validation| validation.to_rb }
    end
    
  end
  
  class CheckBox
    
    def validate_fields
      super
      set_value_by_path(!!fetch_value_by_path)
    end
    
    def rb_boolean_value
      "!!get_value_by_path(data, #{@path.inspect})"
    end
    
    def rb_string_value
      raise FormError, "field #{@name.inspect} does not have a string value"
    end
    
  end
  
  class File

    def validate_fields
      super
      if d = fetch_value_by_path and !d.is_a?(::String)
        uploaded_data = d.read
        original_file_name = d.original_filename
        content_type = d.content_type
        size = uploaded_data.size
        set_value_by_path({
          :data => uploaded_data,
          :original_file_name => original_file_name,
          :content_type => content_type,
          :file_size => size
        })
        errors[@name] << "smaller than #{@min_size}" if @min_size && @min_size > size
        errors[@name] << "larger than #{@max_size}" if @max_size && @max_size < size
      else
        set_value_by_path(nil)
      end
    end
    
    def rb_string_value
      "(t = get_value_by_path(data, #{@path.inspect}) ; t && !t.is_a?(::String) ? t.read[0, 1] : '')"
    end
    
  end
  
  class Info
    
    def validate_fields
    end
    
  end
  
  class Link

    def validate_fields
    end
    
  end
  
  class Conditional
    
    def validate_fields
      data = context[:data]
      if eval(@rb_condition)
        super
      end
    end
    
    def translate_condition_to_rb
      rb_condition
    end
    
    def rb_condition
      @rb_condition ||= begin
        raise FormError, "cycle detected in conditions" if @in_translation
        @in_translation = true
        res = @parsed_condition.to_rb
        @in_translation = false
        res
      end
    end
    
  end
  
  module ConditionAST

    class Root

      def to_rb
        @condition = condition
        condition.to_rb
      end

    end
  
    class Or

      def to_rb
        @exp1 = exp1
        @exp2 = exp2
        '(%s) || (%s)' % [exp1.to_rb, exp2.to_rb]
      end

    end
  
    class And

      def to_rb
        @exp1 = exp1
        @exp2 = exp2
        '(%s) && (%s)' % [exp1.to_rb, exp2.to_rb]
      end

    end
  
    class Not

      def to_rb
        @exp = exp
        '!(%s)' % exp.to_rb
      end

    end
  
    class Equals

      def to_rb
        @v = v
        "(#{@field.rb_string_value}) == #{v.to_string.inspect}"
      end

    end
  
    class NotEquals

      def to_rb
        @v = v
        "(#{@field.rb_string_value}) != #{v.to_string.inspect}"
      end

    end
  
    class IsOn

      def to_rb
        @field.rb_boolean_value
      end

    end
  
    class IsOff

      def to_rb
        "!(#{@field.rb_boolean_value})"
      end

    end
    
    class IsEmpty
      
      def to_rb
        "%s =~ (%s)" % [/\A\s*\z/.inspect, @field.rb_string_value]
      end
      
    end
    
    class IsNotEmpty
      
      def to_rb
        "%s !~ (%s)" % [/\A\s*\z/.inspect, @field.rb_string_value]
      end
      
    end

  end

end
