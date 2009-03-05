begin
  $LOAD_PATH.unshift('lib')
  require 'test/uploaded_file'
  require 'rformation'
  require 'yaml'

  include RFormation::HTMLHelpers

  form_spec = File.read($*[0])
  form_data = YAML.load(File.read($*[1]))
  form = RFormation::Form.new(form_spec, :lists_of_values => proc { true })
  result = form.validate_form(form_data)
  puts "<pre>"
  puts h(result.to_yaml)
  puts "</pre>"
rescue RFormation::FormError => e
  puts "<div style='color: red'>line %d : %s</div>" % [e.line_number, e.message]
  puts "<pre style='margin-left: 1em; '>#{form_spec}</pre>"
  puts "<pre>#{e.backtrace.join("\n")}</pre>"
rescue RFormation::ValidationError => e
  e.errors.each do |field, errors|
    puts "<div style='color: red'>%s : %s</div>" % [h(field), errors.map { |e| h(e) }.join(", ")]
  end
rescue Exception => e
  puts "<pre>"
  puts h(e.message)
  puts e.backtrace.map { |t| h(t) }
  puts "</pre>"
end
