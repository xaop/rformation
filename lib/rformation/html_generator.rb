module RFormation
  
  class Form
    
    def to_html(options = {})
      list_of_values = options.delete(:lists_of_values) || proc {}
      bare_data = options.delete(:data) || {}
      # Make sure we can always work with a hash-like interface
      if bare_data.is_a?(Hash)
        data = bare_data
      else
        data = Hash.new { |h, k| h[k] = bare_data.send(k) }
      end
      options.empty? or raise "unknown options #{options.keys.join(", ")}"
      
      actors = []
      fields = fields_to_html(list_of_values, data, actors)
      actors = actors_to_html(list_of_values, actors)
      H {%{
        = fields
        = actors
      }}
    end
    
    def fields_to_html(list_of_values, data, actors)
      H {%{
        - @items.each do |item|
          %div= item.to_html(list_of_values, data, actors)
      }}
    end
    
    def actors_to_html(list_of_values, actors)
      el2actor = Hash.new { |h, k| h[k] = [] }
      actors.each { |actor, (els, _)| els.each { |el| el2actor[el] << actor } }
      H {%{
        %script{ :type => 'text/javascript' }
          - @elements.each do |name, (_, variable, id)|
            = setup_for_element(id, variable, el2actor[variable])
          - actors.each do |id, (_, exp)|
            = setup_for_actor(id, exp)
      }}
    end
    
    def setup_for_element(id, name, el2actor)
      unless el2actor.empty?
        <<-END
          var #{name} = document.getElementById(#{id.inspect});
          #{name}.onchange = function() {
            #{el2actor.map { |actor| "update_#{actor}(); " }}
          }
        END
      end
    end
    
    def setup_for_actor(id, exp)
      <<-END
        var #{id} = document.getElementById(#{id.inspect});
        function update_#{id}() {
          if (#{exp}) {
            #{id}.style.display = "block";
          } else {
            #{id}.style.display = "none";
          }
        }
        update_#{id}();
      END
    end
    
  end
  
  class Group
    
    def to_html(list_of_values, data, actors)
      H {%{
        %fieldset
          %legend= h @caption
          - @items.each do |item|
            %div= item.to_html(list_of_values, data, actors)
      }}
    end
    
  end
  
  class DropdownSelect
    
    def to_html(list_of_values, data, actors)
      selected = data[@name]
      H {%{
        %label.normal_label{ :for => @id }= h @label
        %select{ :name => @name, :id => @id }
          - entries(list_of_values).each do |id, label, default|
            - if selected
              - default = (id == selected)
            %option{ default ? { :selected => "selected" } : {}, :value => id }= label
      }}
    end
    
  end
  
  class RadioSelect
    
    def to_html(list_of_values, data, actors)
      selected = data[@name]
      H {%{
        .radio_label= h @label
        .radio_list
          - entries(list_of_values).each_with_index do |(id, label, default), i|
            - option_id = "%s_%d" % [@id, i]
            - if selected
              - default = (id == selected)
            %div
              %input{ default ? { :checked => "checked" } : {}, :type => 'radio', :value => id, :id => option_id, :name => @name }
              %label.radio_option{ :for => option_id }= label
      }}
    end

  end
  
  class File
    
    def to_html(list_of_values, data, actors)
      H {%{
        %label.normal_label{ :for => @id }= h @label
        %input{ :type => 'file', :id => @id, :name => @name }
      }}
    end
    
  end
  
  class Text
    
    def to_html(list_of_values, data, actors)
      value = data[@name] || @value
      H {%{
        %label.normal_label{ :for => @id }= h @label
        - if @multi
          %textarea{ :id => @id, :name => @name }= h value
        - else
          %input{ :type => 'text', :id => @id, :name => @name, :value => value }
      }}
    end
    
  end
  
  class Info
    
    def to_html(list_of_values, data, actors)
      H {%{
        %div.info= @text
      }}
    end
    
  end
  
  class CheckBox
    
    def to_html(list_of_values, data, actors)
      on = @on_by_default
      on = data[@name] if data.has_key?(@name)
      H {%{
        %label.normal_label{ :for => @id }= h @label
        %input.boxes{ on ? { :checked => "checked" } : {}, :type => 'checkbox', :id => @id, :name => @name }
      }}
    end

  end
  
  class Conditional
    
    def to_html(list_of_values, data, actors)
      name = "actor#{actors.length}"
      actors << [name, @js_condition]
      H {%{
        %div{ :style => "display: none; ", :id => name }
          - @items.each do |item|
            %div= item.to_html(list_of_values, data, actors)
      }}
    end
    
  end

end
