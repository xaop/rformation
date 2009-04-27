module RFormation
  class FormError < Exception
  end
  class ValidationError < Exception
  end
end
def h(s)
  s.to_s.gsub(/[&"><]/) { |special| { '&' => '&amp;', '>' => '&gt;', '<' => '&lt;', '"' => '&quot;' }[special] }
end

begin
  $LOAD_PATH.unshift('lib')
  require 'rformation'
  require 'yaml'

  include RFormation::HTMLHelpers

  form_spec = File.read($*[0])
  form_data = YAML.load(File.read($*[1]))
  form_value_lists = YAML.load(File.read($*[2]))
  form = RFormation::Form.new(form_spec, :lists_of_values => form_value_lists)
  puts "<form action='test_form' method='post' enctype='multipart/form-data'>"
  puts form.to_html(:data => form_data, :lists_of_values => form_value_lists)
  puts "<input type='submit' value='test form'></input>"
  puts "</form>"
rescue RFormation::FormError => e
  puts "<div style='color: red'>line %d : %s</div>" % [e.line_number, h(e.message)]
  puts "<pre style='margin-left: 1em; '>#{h form_spec}</pre>"
  puts "<pre>#{e.backtrace.map{ |l| h(l) }.join("\n")}</pre>"
rescue Exception => e
  puts "<pre>"
  puts h(e.message)
  puts e.backtrace.map{ |l| h(l) }
  puts "</pre>"
end
