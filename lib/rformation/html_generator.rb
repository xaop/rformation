# This file reopens the classes inside RFormation to add the
# funtionality to generate a HTML version of the form.
# You may want to consult form.rb to find out how the classes
# and modules are related.
module RFormation

  class Form
    
    def to_html(options = {})
      list_of_values = options.delete(:lists_of_values) || proc {}
      data = options.delete(:data) || {}
      options.empty? or raise "unknown options #{options.keys.join(", ")}"
      
      with_context :list_of_values => list_of_values, :data => data do
        fields = fields_to_html
        actors = actors_to_html
        H {%{
          = fields
          = actors
        }}
      end
    end
    
    def fields_to_html
      H {%{
        - @items.each do |item|
          %div= item.to_html
      }}
    end
    
    def actors_to_html
      # The @actor2els variable contains the map of actors onto
      # the elements that influence it, but here we need the
      # inverse too, i.e., a hash that maps an element onto all
      # the actors it influences.
      el2actors = Hash.new { |h, k| h[k] = [] }
      @actor2els.each do |actor, els|
        els.each do |el|
          el2actors[el] << actor
        end
      end
      H {%{
        %script{ :type => 'text/javascript' }
          = js_error_reporting
          - @elements.each do |name, (element, variable)|
            = element.js_setup_for_element(el2actors[variable])
          - @actor2els.each do |actor, elements|
            = actor.js_setup_for_actor
      }}
    end
    
    def js_error_reporting
      <<-END
        var rformationErrorCount = 0;
        var rformationGlobalError = null;
        function rformationSetGlobalError() {
          rformationGlobalError = rformationGlobalError || document.getElementById("rformationGlobalError");
          if (rformationGlobalError) {
            if (rformationErrorCount == 0) {
              rformationGlobalError.className = rformationGlobalError.className.replace("has_errors");
            } else {
              rformationGlobalError.className = rformationGlobalError.className.replace("has_errors") + " has_errors";
            }
          }
        }
        function rformationIncreaseErrors() {
          rformationErrorCount += 1;
          rformationSetGlobalError();
        }
        function rformationDecreaseErrors() {
          rformationErrorCount -= 1;
          rformationSetGlobalError();
        }
        if (window.attachEvent) {
          window.attachEvent("onload", function () { rformationSetGlobalError(); return true; })
        } else {
          window.addEventListener("load", function () { rformationSetGlobalError(); return true; }, true)
        }
      END
    end
    
  end
  
  class Element

    def js_string_value
      raise FormError, "field #{@name.inspect} does not have a string value"
    end
    
    def js_boolean_value
      raise FormError, "field #{@name.inspect} does not have a boolean value"
    end
    
  end
  
  module Validated
    
    def to_html(content)
      if @validations.empty?
        H {%{
          %div{ :class => @class }
            = content
        }}
      else
        @container_id = "rformationActor#{@actor_index}"
        @messages_id = "rformationMessages#{@actor_index}"
        @flag_id = "rformationInError#{@actor_index}"
        H {%{
          %div{ :id => @container_id, :class => @class }
            = content
            %div.error_message{ :id => @messages_id }
        }}
      end
    end
    
    def translate_validations_to_js
      @js_conditions = @parsed_validations.map { |validation| validation.to_js }
    end
    
    def js_update
      "update_#{@container_id}();"
    end
    
    def js_setup_for_actor
      checks = @js_conditions.zip(@error_messages).map { |c, e| js_separate_validation_checks(c, e) }
      <<-END
        var #{@container_id} = document.getElementById(#{@container_id.inspect});
        var #{@messages_id} = document.getElementById(#{@messages_id.inspect});
        var #{@flag_id} = false;
        function update_#{@container_id}() {
          var errorMessages = [];
          #{checks}
          if (errorMessages.length == 0) {
            #{@container_id}.className = "valid";
            #{@messages_id}.innerHTML = "";
            if (#{@flag_id}) {
              rformationDecreaseErrors();
            }
            #{@flag_id} = false;
          } else {
            #{@container_id}.className = "invalid";
            #{@messages_id}.innerHTML = errorMessages.join(', ');
            if (!#{@flag_id}) {
              rformationIncreaseErrors();
            }
            #{@flag_id} = true;
          }
        }
        update_#{@container_id}();
      END
    end
    
    def js_separate_validation_checks(condition, message)
      message ||= "error in field"
      <<-END
        if (!(#{condition})) {
          errorMessages.push(#{message.inspect});
        }
      END
    end
    
  end

  module Named
    
  end
  
  class Group
    
    def to_html
      H {%{
        %fieldset{ :class => @class }
          %legend= h @caption
          - @items.each do |item|
            %div= item.to_html
      }}
    end
    
  end
  
  class DropdownSelect
    
    def to_html
      selected = fetch_value_by_trail
      content = H {%{
        %label.normal_label{ :for => @id }= h @label
        %div.select
          %select{ :name => @name, :id => @id, :multiple => @multivalue ? "multiple" : nil }
            - entries(context[:list_of_values]).each do |id, label, default|
              - if selected
                - default = (id == selected)
              %option{ default ? { :selected => "selected" } : {}, :value => id }= h label
      }}
      H {%{
        = super(content)
        .select_clear
      }}
    end
    
    def js_string_value
      "#{@variable}[#{@variable}.selectedIndex].value"
    end
    
    def js_setup_for_element(actors)
      unless actors.empty?
        <<-END
          var #{@variable} = document.getElementById(#{@id.inspect});
          #{@variable}.onchange = function() {
            #{actors.map { |actor| actor.js_update }}
          }
        END
      end
    end
    
  end
  
  class RadioSelect
    
    def js_setup_for_element(actors)
      unless actors.empty?
        setups = (0...@actual_values.length).map do |i|
          option_id = "%s_%d" % [@id, i]
          variable = "%s_%d" % [@variable, i]
          <<-END
            var #{variable} = document.getElementById(#{option_id.inspect});
            #{variable}.onclick = function() {
              #{actors.map { |actor| actor.js_update }}
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
    
    def html_create_value_getter
      result = '""'
      @actual_values.length.times do |i|
        variable = "%s_%d" % [@variable, i]
        result = "(%s.checked ? %s.value : %s)" % [variable, variable, result]
      end
      result
    end
    
    def to_html
      @actual_values = entries(context[:list_of_values])
      selected = fetch_value_by_trail
      content = H {%{
        .radio_label= h @label
        .radio_list
          - @actual_values.each_with_index do |(id, label, default), i|
            - option_id = "%s_%d" % [@id, i]
            - if selected
              - default = (id == selected)
            %div.radio_option
              %input.radio{ default ? { :checked => "checked" } : {}, :type => 'radio', :value => id, :id => option_id, :name => @name }
              %label.radio_text{ :for => option_id }= h label
      }}
      H {%{
        = super(content)
        .radio_list_clear
      }}      
    end

    def js_string_value
      function_name = "%s_value" % @variable
      "%s()" % function_name
    end
    
  end
  
  class File
    
    def to_html
      content = H {%{
        %label.normal_label{ :for => @id }= h @label
        %div.file
          %input{ :type => 'file', :id => @id, :name => @name }
      }}
      H {%{
        = super(content)
        .file_clear
      }}      
    end
    
    def js_string_value
      "#{@variable}.value"
    end
    
    def js_setup_for_element(actors)
      unless actors.empty?
        <<-END
          var #{@variable} = document.getElementById(#{@id.inspect});
          #{@variable}.onkeyup = function() {
            #{actors.map { |actor| actor.js_update }}
          }
          #{@variable}.onchange = function() {
            #{actors.map { |actor| actor.js_update }}
          }
        END
      end
    end
    
  end
  
  class Text
    
    def to_html
      value = fetch_value_by_trail
      content = H {%{
        %label.normal_label{ :for => @id }= h @label
        %div.text
          - if @multi
            %textarea{ :id => @id, :name => @name }= h value
          - else
            %input{ :type => 'text', :id => @id, :name => @name, :value => value }
      }}
      H {%{
        = super(content)
        .text_clear
      }}      
    end
    
    def js_string_value
      "#{@variable}.value"
    end
    
    def js_setup_for_element(actors)
      unless actors.empty?
        <<-END
          var #{@variable} = document.getElementById(#{@id.inspect});
          #{@variable}.onkeyup = function() {
            #{actors.map { |actor| actor.js_update }}
          }
        END
      end
    end
    
  end
  
  class Info
    
    def to_html
      H {%{
        %div{ :class => "info " + (@class || "") }= @text
      }}
    end
    
  end
  
  class Link
    
    def to_html
      H {%{
        %div{ :class => "link " + (@class || "") }
          %a{ :href => @url }= h @label
      }}
    end
    
  end
  
  class CheckBox
    
    def to_html
      on = fetch_value_by_trail
      content = H {%{
        %label.normal_label{ :for => @id }= h @label
        .checkbox
          %input{ on ? { :checked => "checked" } : {}, :type => 'checkbox', :id => @id, :name => @name }
      }}
      H {%{
        = super(content)
        .checkbox_clear
      }}      
    end

    def js_boolean_value
      "#{@variable}.checked"
    end

    def js_setup_for_element(actors)
      unless actors.empty?
        <<-END
          var #{@variable} = document.getElementById(#{@id.inspect});
          #{@variable}.onclick = function() {
            #{actors.map { |actor| actor.js_update }}
          }
        END
      end
    end
    
  end
  
  class Hidden
    
    def to_html
      value = fetch_value_by_trail
      H {%{
        %input{ :type => 'hidden', :value => value, :name => @name, :id => @id }
      }}
    end
    
  end
  
  class Object
    
    def to_html
      H {%{
        - @items.each do |item|
          %div= item.to_html
      }}
    end
    
  end
  
  class Conditional
    
    def to_html
      @name = "rformationActor#{@actor_index}"
      H {%{
        %div{ :style => "display: none; ", :id => @name, :class => @class }
          - @items.each do |item|
            %div= item.to_html
      }}
    end
    
    def translate_condition_to_js
      @js_condition = @parsed_condition.to_js
    end
    
    def js_setup_for_actor
      <<-END
        var #{@name} = document.getElementById(#{@name.inspect});
        function update_#{@name}() {
          if (#{@js_condition}) {
            #{@name}.style.display = "block";
          } else {
            #{@name}.style.display = "none";
          }
        }
        update_#{@name}();
      END
    end
    
    def js_update
      "update_#{@name}();"
    end
    
  end

  module ConditionAST

    class Root

      def to_js
        condition.to_js
      end

    end
  
    class Or

      def to_js
        '(%s) || (%s)' % [exp1.to_js, exp2.to_js]
      end

    end
  
    class And

      def to_js
        '(%s) && (%s)' % [exp1.to_js, exp2.to_js]
      end

    end
  
    class Not

      def to_js
        '!(%s)' % exp.to_js
      end

    end
  
    class Equals

      def to_js
        "(#{field.js_string_value}) == #{value.inspect}"
      end

    end
  
    class NotEquals

      def to_js
        "(#{field.js_string_value}) != #{value.inspect}"
      end

    end
  
    class IsOn

      def to_js
        field.js_boolean_value
      end

    end
  
    class IsOff

      def to_js
        "!(#{field.js_boolean_value})"
      end

    end
    
    class IsEmpty
      
      def to_js
        "(#{field.js_string_value}).match(new RegExp('^\s*$'))"
      end
      
    end
    
    class IsNotEmpty
      
      def to_js
        "!(#{field.js_string_value}).match(new RegExp('^\s*$'))"
      end
      
    end

  end

end
