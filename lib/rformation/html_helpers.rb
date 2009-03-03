# A couple of helpers for generation of HTML.
# Provides escaping if HTML through the h method,
# and HAML templating through the H method.

# The H method takes a block for the simple reason
# that a block carries the binding of wherever the
# block is defined and we can have the template
# access local variables that way. Looks kinda neat
# when used together with %{} string syntax:
#   H {%{
#     ...
#   }}
#   
module RFormation
  
  module HTMLHelpers
    
    @@haml_template_cache = Hash.new do |h, str|
      cleaned_str = str.gsub(/^\s+$/, "")
      indent = cleaned_str.scan(/^[ ]+/).map { |s| s.length }.min || 0
      h[str] = Haml::Engine.new(cleaned_str.gsub(/^ {#{indent}}/, ""))
    end
    
    def H(&blk)
      require 'haml'
      @@haml_template_cache[blk.call].render(blk)
    end

    def h(s)
      s.to_s.gsub(/[&"><]/) { |special| { '&' => '&amp;', '>' => '&gt;', '<' => '&lt;', '"' => '&quot;' }[special] }
    end
  end
  
  (constants - ["HTMLHelpers"]).each do |c|
    const_get(c).send(:include, HTMLHelpers)
  end

end
