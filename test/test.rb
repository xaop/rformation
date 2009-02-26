if true
  # local test
  $LOAD_PATH.unshift('lib')
else
  # gem test
  require 'rubygems'
end
require 'rformation'

value_generator = proc do |name|
  (1..5).map { |i| [i.to_s, "%s%i" % [name, i]] }
end

form = RFormation::Form.new(<<-END, :lists_of_values => value_generator)
  group "Hardware" do
    select "computer" do
      label "Computer"
      value "Desktop"
      value "Laptop", :default
      value "Tablet PC"
    end
    select "keyboard", :auto_number do
      value "Azerty"
      value "Qwerty"
      value "Qwertz"
    end
    condition "keyboard equals 1" do
      text "abcd" do
        value "yo de mannen"
      end
      select "extra" do
        values "extras"
      end
      select "more_extra", :self do
        value 1, "tata"
        value 2, "toto"
      end
    end
    box "optical_mouse" do
      label "optical mouse"
      default off
    end
    box "kill_microsoft" do
      default on
    end
    condition 'kill_microsoft is on' do
      text "message_to_ms" do
        value "we will kill you!"
      end
    end
    condition '`kill_microsoft` is on and optical_mouse is on' do
      text "message_to_you" do
        value "you want to kill them with a mouse?"
      end
    end
    condition 'kill_microsoft is on and optical_mouse is on or computer equals "3"' do
      text "message_to_you2" do
        value "you are evil"
      end
    end
    radio "screens", :auto_id do
      label "screens"
      value "15 inches"
      value "19 inches"
    end
  end
  group "Usage info" do
    text "frequent_traveller", :multi do
      label "frequent traveller"
    end
  end
END

File.open("/tmp/form.html", "w") do |f|
  f.puts '<html><head><LINK REL=StyleSheet HREF="test.css" TYPE="text/css" MEDIA=screen></head><body>'
  f << form.to_html(:lists_of_values => value_generator)
  f.puts '</body>'
end
