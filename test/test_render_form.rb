$LOAD_PATH.unshift('lib')
require 'rformation'
require 'yaml'

begin
  form_spec = File.read($*[0])
  form_data = YAML.load(File.read($*[1]))
  $stderr.puts form_data.inspect
  form = RFormation::Form.new(form_spec, :lists_of_values => proc { [[1, 2]] })
  puts "<form action='test_form' method='post'>"
  puts form.to_html(:data => form_data, :lists_of_values => proc { [[1, 2]] })
  puts "<div style='clear: left; '><input type='submit' value='test form'></input></div>"
  puts "</form>"
rescue RFormation::FormError => e
  puts "<div style='color: red'>line %d : %s</div>" % [e.line_number, e.message]
  puts "<pre style='margin-left: 1em; '>#{form_spec}</pre>"
  puts "<pre>#{e.backtrace.join("\n")}</pre>"
rescue Exception => e
  puts "<pre>"
  puts e.message
  puts e.backtrace
  puts "</pre>"
end
