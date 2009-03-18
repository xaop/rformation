# This defines all the AST classes that will be instantiated
# by the parser. All methods that are not directly related to
# generating a particular output (HTML or Ruby) are put in
# this file.
module RFormation::ConditionAST

  class Node < Treetop::Runtime::SyntaxNode
    
    include ::RFormation::Contextual
    
  end

  class Identifier < Node
    
    def to_identifier
      text_value
    end
    
    def to_string
      text_value
    end
    
  end
  
  class String < Node

    # Helper method to convert string syntax to the contents of the string.
    # Escape sequences \a \t \f \n \r are converted to the respective
    # characters, all other escaped characters are retained verbatim.
    # This method is used from the condition parser.
    def unescape_string_syntax(str)
      str[1..-2].gsub(/\\(.)/) do
        case $1
        when *%w[a t f n r]
          eval "\\#{$1}"
        else
          $1
        end
      end
    end
    
    def self.escape_back_string_syntax(str)
      "`%s`" % (str.gsub(/([\\`])/) { "\\%s" % $1 })
    end

    def to_identifier
      raise RFormation::FormError, "id expected"
    end

    def to_string
      unescape_string_syntax(text_value)
    end
  
  end

  class BackString < String

    def to_identifier
      unescape_string_syntax(text_value)
    end
    
    def to_string
      raise RFormation::FormError, "string expected"
    end

  end
  
  class Root < Node
    
    # This method is used to resolve references to form fields.
    def resolve
      condition.resolve.keys
    end
    
  end
  
  class Or < Node
    
    def resolve
      exp1.resolve.merge(exp2.resolve)
    end
    
  end
  
  class And < Node

    def resolve
      exp1.resolve.merge(exp2.resolve)
    end
    
  end
  
  class Not < Node

    def resolve
      exp.resolve
    end
    
  end
  
  class Parentheses < Node
    
    def method_missing(m, *a, &b)
      condition.send(m, *a, &b)
    end
    
  end
  
  class Equals < Node

    def resolve
      @field, variable = context[:elements][f.to_identifier]
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
  
  class NotEquals < Node
    
    def resolve
      @field, variable = context[:elements][f.to_identifier]
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
  
  class IsOn < Node
    
    def resolve
      @field, variable = context[:elements][f.to_identifier]
      @field or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
      { variable => true }
    end
    
    def field
      @field
    end
    
  end
  
  class IsOff < Node

    def resolve
      @field, variable = context[:elements][f.to_identifier]
      @field or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
      { variable => true }
    end
    
    def field
      @field
    end
    
  end
  
  class IsEmpty < Node
    
    def resolve
      @field, variable = context[:elements][f.to_identifier]
      @field or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
      { variable => true }
    end
    
    def field
      @field
    end

  end
  
  class IsNotEmpty < Node

    def resolve
      @field, variable = context[:elements][f.to_identifier]
      @field or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
      { variable => true }
    end
    
    def field
      @field
    end

  end

end
