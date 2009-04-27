# This defines all the AST classes that will be instantiated
# by the parser. All methods that are not directly related to
# generating a particular output (HTML or Ruby) are put in
# this file.
module RFormation::ConditionAST

  class Node < Treetop::Runtime::SyntaxNode
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
  end

  class Or < Node
  end

  class And < Node
  end

  class Not < Node
  end

  class Equals < Node
  end

  class NotEquals < Node
  end

  class IsOn < Node
  end

  class IsOff < Node
  end
  
  class IsEmpty < Node
  end
  
  class IsNotEmpty < Node
  end

end
