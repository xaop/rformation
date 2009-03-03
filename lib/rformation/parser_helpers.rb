# This defines all the AST classes that will be instantiated
# by the parser. All methods that are not directly related to
# generating a particular output (HTML or Ruby) are put in
# this file.
module RFormation::ConditionAST

  class Identifier < Treetop::Runtime::SyntaxNode
    
    def to_identifier
      text_value
    end
    
    def to_string
      text_value
    end
    
  end
  
  class String < Treetop::Runtime::SyntaxNode

    # Helper method to convert string syntax to the contents of the string.
    # Escape sequences \a \t \f \n \r are converted to the respective
    # characters, all other escaped characters are retained verbatim.
    # This method is used from the condition parser.
    def convert_string_syntax(str)
      str[1..-2].gsub(/\\(.)/) do
        case $1
        when *%w[a t f n r]
          eval "\\#{$1}"
        else
          $1
        end
      end
    end

    def to_identifier
      raise RFormation::FormError, "id expected"
    end

    def to_string
      convert_string_syntax(text_value)
    end
  
  end

  class BackString < String

    def to_identifier
      convert_string_syntax(text_value)
    end
    
    def to_string
      raise RFormation::FormError, "string expected"
    end

  end
  
  class Root < Treetop::Runtime::SyntaxNode
    
    # This method is used to resolve references to form fields.
    def resolve(element_info)
      condition.resolve(element_info).keys
    end
    
  end
  
  class Or < Treetop::Runtime::SyntaxNode
    
    def resolve(element_info)
      exp1.resolve(element_info).merge(exp2.resolve(element_info))
    end
    
  end
  
  class And < Treetop::Runtime::SyntaxNode

    def resolve(element_info)
      exp1.resolve(element_info).merge(exp2.resolve(element_info))
    end
    
  end
  
  class Not < Treetop::Runtime::SyntaxNode

    def resolve(element_info)
      exp.resolve(element_info)
    end
    
  end
  
  class Parentheses < Treetop::Runtime::SyntaxNode
    
    def method_missing(m, *a, &b)
      condition.send(m, *a, &b)
    end
    
  end
  
  class Equals < Treetop::Runtime::SyntaxNode

    def resolve(element_info)
      @field, variable = element_info[f.to_identifier]
      @field or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
      { variable => true }
    end
    
    def field
      @field
    end
    
    def value
      v.to_string
    end
    
  end
  
  class NotEquals < Treetop::Runtime::SyntaxNode
    
    def resolve(element_info)
      @field, variable = element_info[f.to_identifier]
      @field or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
      { variable => true }
    end
    
    def field
      @field
    end
    
    def value
      v.to_string
    end
    
  end
  
  class IsOn < Treetop::Runtime::SyntaxNode
    
    def resolve(element_info)
      @field, variable = element_info[f.to_identifier]
      @field or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
      { variable => true }
    end
    
    def field
      @field
    end
    
  end
  
  class IsOff < Treetop::Runtime::SyntaxNode

    def resolve(element_info)
      @field, variable = element_info[f.to_identifier]
      @field or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
      { variable => true }
    end
    
    def field
      @field
    end
    
  end
  
  class IsEmpty < Treetop::Runtime::SyntaxNode
    
    def resolve(element_info)
      @field, variable = element_info[f.to_identifier]
      @field or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
      { variable => true }
    end
    
    def field
      @field
    end

  end
  
  class IsNotEmpty < Treetop::Runtime::SyntaxNode

    def resolve(element_info)
      @field, variable = element_info[f.to_identifier]
      @field or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
      { variable => true }
    end
    
    def field
      @field
    end

  end

end
