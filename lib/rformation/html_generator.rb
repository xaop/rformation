module RFormation

  class Element

    def js_string_value
      raise FormError, "field #{@name.inspect} does not have a string value"
    end
    
    def js_boolean_value
      raise FormError, "field #{@name.inspect} does not have a boolean value"
    end
    
  end
  
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
      el2actors = Hash.new { |h, k| h[k] = [] }
      actors.each { |actor, (els, _)| els.each { |el| el2actors[el] << actor } }
      H {%{
        %script{ :type => 'text/javascript' }
          - @elements.each do |name, (element, variable)|
            = element.html_setup_for_element(el2actors[variable])
          - actors.each do |id, (_, exp)|
            = setup_for_actor(id, exp)
      }}
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
  
  module Named
    
    def html_setup_for_element(actors)
      unless actors.empty?
        <<-END
          var #{@variable} = document.getElementById(#{@id.inspect});
          #{@variable}.onchange = function() {
            #{actors.map { |actor| "update_#{actor}(); " }}
          }
        END
      end
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
    
    def js_string_value
      "#{@variable}[#{@variable}.selectedIndex].value"
    end
    
  end
  
  class RadioSelect
    
    def html_setup_for_element(actors)
      unless actors.empty?
        setups = (0...@actual_values.length).map do |i|
          option_id = "%s_%d" % [@id, i]
          variable = "%s_%d" % [@variable, i]
          <<-END
            var #{variable} = document.getElementById(#{option_id.inspect});
            #{variable}.onchange = function() {
              #{actors.map { |actor| "update_#{actor}(); " }}
            }
          END
        end.join
        function_name = "%s_value" % @variable
        value_getter = <<-END
          function #{function_name}() {
            return #{html_create_value_getter}
          }
        END
        setups + value_getter
      end
    end
    
    def html_create_value_getter(indexes = (0...@actual_values.length).to_a)
      if i = indexes.shift
        variable = "%s_%d" % [@variable, i]
        "(%s.checked ? %s.value : %s)" % [variable, variable, html_create_value_getter(indexes)]
      else
        '""'  
      end
    end
    
    def to_html(list_of_values, data, actors)
      @actual_values = entries(list_of_values)
      selected = data[@name]
      H {%{
        .radio_label= h @label
        .radio_list
          - @actual_values.each_with_index do |(id, label, default), i|
            - option_id = "%s_%d" % [@id, i]
            - if selected
              - default = (id == selected)
            %div
              %input{ default ? { :checked => "checked" } : {}, :type => 'radio', :value => id, :id => option_id, :name => @name }
              %label.radio_option{ :for => option_id }= label
        .radio_list_clear
      }}
    end

    def js_string_value
      function_name = "%s_value" % @variable
      "%s()" % function_name
    end
    
  end
  
  class File
    
    def to_html(list_of_values, data, actors)
      H {%{
        %label.normal_label{ :for => @id }= h @label
        %input{ :type => 'file', :id => @id, :name => @name }
      }}
    end
    
    def js_string_value
      "#{@variable}[#{@variable}.selectedIndex].value"
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
    
    def js_string_value
      "#{@variable}[#{@variable}.selectedIndex].value"
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

    def js_boolean_value
      "#{@variable}.checked"
    end

  end
  
  class Conditional
    
    def to_html(list_of_values, data, actors)
      name = "actor#{actors.length}"
      actors << [name, [@fields_of_interest, @js_condition]]
      H {%{
        %div{ :style => "display: none; ", :id => name }
          - @items.each do |item|
            %div= item.to_html(list_of_values, data, actors)
      }}
    end
    
    def translate_condition_to_js(element_info)
      @js_condition = @parsed_condition.to_js(element_info)
    end
    
  end

  module ConditionAST

    class Root

      def to_js(element_info)
        condition.to_js(element_info)
      end

    end
  
    class Or

      def to_js(element_info)
        '(%s) || (%s)' % [atomic_condition.to_js(element_info), and_condition.to_js(element_info)]
      end

    end
  
    class And

      def to_js(element_info)
        '(%s) && (%s)' % [atomic_condition.to_js(element_info), and_condition.to_js(element_info)]
      end

    end
  
    class Not

      def to_js(element_info)
        '!(%s)' % condition.to_js
      end

    end
  
    class Equals

      def to_js(element_info)
        "(#{field.js_string_value}) == #{value.inspect}"
      end

    end
  
    class NotEquals

      def to_js(element_info)
        "(#{field.js_string_value}) != #{value.inspect}"
      end

    end
  
    class IsOn

      def to_js(element_info)
        field.js_boolean_value
      end

    end
  
    class IsOff

      def to_js(element_info)
        "!(#{field.js_boolean_value})"
      end

    end

  end

end
