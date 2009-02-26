class Treetop::Runtime::SyntaxNode
  
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
  
end
