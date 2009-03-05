require 'rubygems'
require 'sinatra'
require 'test/uploaded_file'

get '/' do
  content_type 'text/html'
  body <<-END
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

get '/render_form' do
  form = params["form"]
  data = params["data"]
  File.open("/tmp/form_definition", "w") { |f| f << form }
  File.open("/tmp/form_data", "w") { |f| f << data }
  snippet = `ruby test/test_render_form.rb /tmp/form_definition /tmp/form_data`
  content_type 'text/html'
  body <<-END
    <html>
      <head>
        <link rel="stylesheet" type="text/css" href="test_css" />
      </head>
      <body>
        #{snippet}
      </body>
    </html>
  END
end

get '/test_css' do
  content_type 'text/css'
  body File.read('test/test.css')
end

post '/test_form' do
  data = params.inject({}) do |h, (k, v)|
    if v.is_a?(Hash)
      h[k] = UploadedFile.new(v[:tempfile].read, v[:name], v[:type])
    else
      h[k] = v
    end
    h
  end
  File.open("/tmp/form_submitted_data", "w") { |f| f << data.to_yaml }
  snippet = `ruby test/test_submit_form.rb /tmp/form_definition /tmp/form_submitted_data`
  content_type 'text/html'
  body <<-END
    <html>
      <head>
      </head>
      <body>
        <pre>#{snippet}</pre>
      </body>
    </html>
  END
end
