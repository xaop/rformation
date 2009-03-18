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
        validate_fields(data, result, errors)
      end
      raise ValidationError, errors unless errors.empty?
      result
    end
    
  end
  
  class Element
    
    def rb_boolean_value
      raise FormError, "field #{@name.inspect} does not have a boolean value"
    end
    
    def rb_string_value
      raise FormError, "field #{@name.inspect} does not have a string value"
    end
    
  end
  
  class ContainerElement
    
    def validate_fields(data, result, errors)
      @items.each do |item|
        item.validate_fields(data, result, errors)
      end
    end
    
  end
  
  module Named
    
    def validate_fields(data, result, errors)
      set_value_by_trail(fetch_value_by_trail)
    end
    
    def rb_string_value
      "data[#{@name.inspect}] || ''"
    end
    
  end
  
  module Validated
    
    def validate_fields(data, result, errors)
      @rb_conditions.zip(@error_messages).each do |cond, error_msg|
        errors[@name] << (error_msg || "error in field") unless eval(cond)
      end
      super
    end
    
    def translate_validations_to_rb
      @rb_conditions = @parsed_validations.map { |validation| validation.to_rb }
    end
    
  end
  
  class CheckBox
    
    def validate_fields(data, result, errors)
      set_value_by_trail(!!fetch_value_by_trail)
    end
    
    def rb_boolean_value
      "!!data[#{@name.inspect}]"
    end
    
    def rb_string_value
      raise FormError, "field #{@name.inspect} does not have a string value"
    end
    
  end
  
  class File

    def validate_fields(data, result, errors)
      if d = fetch_value_by_trail and !d.is_a?(String)
        uploaded_data = d.read
        original_file_name = d.original_filename
        content_type = d.content_type
        size = uploaded_data.size
        result[@name] = {
          :data => uploaded_data,
          :original_file_name => original_file_name,
          :content_type => content_type,
          :file_size => size
        }
        errors[@name] << "smaller than #{@min_size}" if @min_size && @min_size > size
        errors[@name] << "larger than #{@max_size}" if @max_size && @max_size < size
      else
        result[@name] = nil
      end
    end
    
  end
  
  class Info
    
    def validate_fields(data, result, errors)
    end
    
  end
  
  class Link

    def validate_fields(data, result, errors)
    end
    
  end
  
  class Conditional
    
    def validate_fields(data, result, errors)
      if eval(@rb_condition)
        super
      end
    end
    
    def translate_condition_to_rb
      @rb_condition = @parsed_condition.to_rb
    end
    
  end
  
  module ConditionAST

    class Root

      def to_rb
        condition.to_rb
      end

    end
  
    class Or

      def to_rb
        '(%s) || (%s)' % [exp1.to_rb, exp2.to_rb]
      end

    end
  
    class And

      def to_rb
        '(%s) && (%s)' % [exp1.to_rb, exp2.to_rb]
      end

    end
  
    class Not

      def to_rb
        '!(%s)' % exp.to_rb
      end

    end
  
    class Equals

      def to_rb
        "(#{field.rb_string_value}) == #{value.inspect}"
      end

    end
  
    class NotEquals

      def to_rb
        "(#{field.rb_string_value}) != #{value.inspect}"
      end

    end
  
    class IsOn

      def to_rb
        field.rb_boolean_value
      end

    end
  
    class IsOff

      def to_rb
        "!(#{field.rb_boolean_value})"
      end

    end
    
    class IsEmpty
      
      def to_rb
        "%s =~ (%s)" % [/\A\s*\z/.inspect, field.rb_string_value]
      end
      
    end
    
    class IsNotEmpty
      
      def to_rb
        "%s !~ (%s)" % [/\A\s*\z/.inspect, field.rb_string_value]
      end
      
    end

  end

end
