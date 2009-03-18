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
  puts "<div style='clear: left; ' id='rformationGlobalError'><input type='submit' value='test form'></input><span class = 'globalErrorMessage'>there are errors<span></div>"
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
