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
      <<-END
        var #{name} = document.getElementById(#{id.inspect});
        #{name}.onchange = function() {
          #{el2actor.map { |actor| "update_#{actor}(); " }}
        }
      END
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
      H {%{
        %label{ :for => @name }= h @label
        %select{ :name => @name, :id => @id }
          - entries(list_of_values).each do |id, label, default|
            %option{ default ? { :selected => "selected" } : {}, :value => id }= label
      }}
    end
    
  end
  
  class RadioSelect
    
    def to_html(list_of_values, data, actors)
      H {%{
        %label{ :for => @name }= h @label
        - entries(list_of_values).each do |id, label, default|
          %input{ default ? { :selected => "selected" } : {}, :type => 'radio', :value => id, :id => @id, :name => @name }= label
      }}
    end

  end
  
  class File
    
    def to_html(list_of_values, data, actors)
      H {%{
        %label{ :for => @name }= h @label
        %input{ :type => 'file', :id => @id, :name => @name }
      }}
    end
    
  end
  
  class Text
    
    def to_html(list_of_values, data, actors)
      H {%{
        %label{ :for => @name }= h @label
        - if @multi
          %textarea{ :id => @id, :name => @name }= h @value
        - else
          %input{ :type => 'text', :id => @id, :name => @name, :value => @value }
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
      H {%{
        %label{ :for => @name }= h @label
        %input.boxes{ @on_by_default ? { :selected => "selected" } : {}, :type => 'checkbox', :id => @id, :name => @name }
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
