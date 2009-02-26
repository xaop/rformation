require 'yaml'
require 'webrick'
include WEBrick

form_entry = proc do |req, resp|
  resp['Content-Type'] = 'text/html'
  resp.body = <<-END
    <html>
      <body>
        <form action='render_form' method='get'>
          <div><textarea rows='15' cols='64' name='form'></textarea></div>
          <div><textarea rows='15' cols='64' name='data'></textarea></div>
          <div><input type='submit' value='render form'></input></div>
        </form>
      </body>
    </html>
  END
end

css = proc do |req, resp|
  resp['Content-Type'] = 'text/css'
  resp.body = File.read('test/test.css')
end

render_form = proc do |req, resp|
  form = req.query["form"]
  data = req.query["data"]
  File.open("/tmp/form_definition", "w") { |f| f << form }
  File.open("/tmp/form_data", "w") { |f| f << data }
  snippet = `ruby test/test_render_form.rb /tmp/form_definition /tmp/form_data`
  resp['ContentType'] = 'text/html'
  resp.body = <<-END
    <html>
      <body>
        #{snippet}
      </body>
    </html>
  END
end

test_form = proc do |req, resp|
  resp['ContentType'] = 'text/plain'
  resp.body = req.query.inject({}) { |h, (k, v)| h[k] = v.list ; h }.to_yaml
end

s = HTTPServer.new(:Port => 2000)
s.mount('/', HTTPServlet::ProcHandler.new(form_entry))
s.mount('/test.css', HTTPServlet::ProcHandler.new(css))
s.mount('/render_form', HTTPServlet::ProcHandler.new(render_form))
s.mount('/test_form', HTTPServlet::ProcHandler.new(test_form))

trap("INT") { s.shutdown }
s.start
