begin
  $LOAD_PATH.unshift('lib')
  require 'rformation'
  require 'yaml'

  include RFormation::HTMLHelpers

  form_spec = File.read($*[0])
  form_data = YAML.load(File.read($*[1]))
  form = RFormation::Form.new(form_spec, :lists_of_values => proc { true })
  puts "<form action='test_form' method='post' enctype='multipart/form-data'>"
  puts form.to_html(:data => form_data, :lists_of_values => proc { [[1, 2]] })
  puts "<div style='clear: left; ' id='rformationGlobalError'><input type='submit' value='test form'></input><span class = 'globalErrorMessage'>there are errors<span></div>"
  puts "</form>"
rescue RFormation::FormError => e
  puts "<div style='color: red'>line %d : %s</div>" % [e.line_number, e.message]
  puts "<pre style='margin-left: 1em; '>#{form_spec}</pre>"
  puts "<pre>#{e.backtrace.join("\n")}</pre>"
rescue Exception => e
  puts "<pre>"
  puts h(e.message)
  puts e.backtrace.map { |t| h(t) }
  puts "</pre>"
end
