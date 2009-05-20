module RFormation
  
  class Form

    # I have no idea why, but HAML seems to apply escapes to
    # Ruby code. There is no point, but there you have it.
    def fields_to_js
      derived_values = []
      @notifier_map.each do |notifier, to_notify|
        derived_values.concat(to_notify)
      end
      derived_values.uniq!
      index = 0
      with_context :new_index => proc { index += 1 } do
        derived_values.each { |v| v.js_assign_value_variable }
      end
      js_assign_value_variables
      setup_phase_variable = "setup_phase"
      @global_show_and_hide_function = "set_display_state"

      with_context :notifier_map => @notifier_map, :setup_phase_variable => setup_phase_variable, :global_show_and_hide_function => @global_show_and_hide_function do
        H {%{
          %script{ :type => "text/javascript" }
            var #{setup_phase_variable} = true;
            = js_element_references.flatten.join("\\n")
            = derived_values.map { |v| v.js_derived_value_notifier }.flatten.join("\\n")
            = js_show_or_hide_functions.flatten.join("\\n")
            = js_elementary_value_setters.flatten.join("\\n")
            = js_run_elementary_value_setters.flatten.join("\\n")
            #{setup_phase_variable} = false;
            #{@global_show_and_hide_function}();
        }}
      end
    end
    
    def js_show_or_hide_functions
      [
        "var is_first_form_element;",
        "var last_form_element;",
        "var last_form_element_stack;",
        "function #{@global_show_and_hide_function}() {",
        "  is_first_form_element = true;",
        "  last_form_element = null;",
        "  last_form_element_stack = [];",
        js_show_or_hide_function,
        "  if (last_form_element) { last_form_element.className += ' last'; };",
        "}",
        super
      ]
    end
    
  end

  class ElementListPart
    
    # This is mainly a complicated construct because we do not check yet if
    # fields with the same name are of the same type (string vs boolean) so
    # we try to do the right thing at run time.
    
    def js_assign_value_variable
      @value_variable = "notifier#{context[:new_index].call}_value"
      @update_function = "update_#{@value_variable}"
    end
    
    def js_derived_value_notifier
      to_notify = context[:notifier_map][self] || []
      [
        "var #{@value_variable} = '';",
        "function #{@update_function}() {",
        "  #{@value_variable} = #{js_cached_string_value_expression || js_cached_boolean_value_expression};",
        to_notify.map { |element| "  #{element.js_do_notify}" },
        "}"
      ]
    end
    
    def js_string_value_expression
      elements.each do |el|
        return el.js_string_value
      end
      result = "''"
      conditions.to_a.reverse.each do |cond, element|
        result = "(%s ? %s : %s)" % [cond.js_condition, element.js_string_value, result]
      end
      result
    end
    
    def js_cached_string_value_expression
        unless defined?(@boolean_string_expression)
          @boolean_string_expression = js_string_value_expression
        end
        @boolean_string_expression
      rescue FormError => e
        if e.message[/does not have a string value/]
          @boolean_string_expression = nil
        else
          raise e
        end
    end
    
    def js_boolean_value_expression
      elements.each do |el|
        return el.js_boolean_value
      end
      result = "''"
      conditions.to_a.reverse.each do |cond, element|
        result = "(%s ? %s : %s)" % [cond.js_condition, element.js_boolean_value, result]
      end
      result
    end
    
    def js_cached_boolean_value_expression
      unless defined?(@boolean_value_expression)
        @boolean_value_expression = js_boolean_value_expression
      end
      @boolean_value_expression
    rescue FormError => e
      if e.message[/does not have a boolean value/]
        @boolean_value_expression = nil
      else
        raise e
      end
    end
    
    def js_string_value
      if js_cached_string_value_expression
        @value_variable
      else
        raise FormError, "field #{@name.inspect} does not have a string value"
      end
    end
    
    def js_boolean_value
      if js_cached_boolean_value_expression
        @value_variable
      else
        raise FormError, "field #{@name.inspect} does not have a boolean value"
      end
    end
    
    def js_do_notify
      "#{@update_function}();"
    end
    
  end
  
  module Validated
  
    def js_assign_value_variable
      value_variable = "notifier#{context[:new_index].call}_value"
      @value_variables = (0...(@parsed_validations.length)).map { |i| "#{value_variable}#{i}" }
      @update_function = "update_#{value_variable}"
    end
    
    def js_derived_value_notifier
      [
        @value_variables.map { |var| "var #{var} = '';" },
        "function #{@update_function}() {",
        "  var errorMessages = [];",
        @parsed_validations.zip(@value_variables, @error_messages).map do |validation, var, message|
          [
            "  #{var} = #{validation.to_js};",
            "  if (!#{var}) {",
            "    errorMessages.push(#{message.inspect});",
            "}"
          ]
        end,
        "  if (errorMessages.length == 0) {",
        "    #{@container_variable}.className = #{@container_variable}.className.replace(/\\b(in)?valid\\b/g, '') + ' valid';",
        "    #{@label_variable}.title = ''",
        "  } else {",
        "    #{@container_variable}.className = #{@container_variable}.className.replace(/\\b(in)?valid\\b/g, '') + ' invalid';",
        "    #{@label_variable}.title = errorMessages.join(', ')",
        "  }",
        "}"
      ]
    end
    
    def js_do_notify
      "#{@update_function}();"
    end
    
  end
  
  class ContainerElement
    
    def js_element_references
      @items.map { |item| item.js_element_references }
    end
    
    def js_elementary_value_setters
      @items.map { |item| item.js_elementary_value_setters }
    end
    
    def js_assign_value_variables
      @items.map { |item| item.js_assign_value_variables }
    end
    
    def js_show_or_hide_functions
      @items.map { |item| item.js_show_or_hide_functions }
    end
    
    def js_show_or_hide_function
      @items.map { |item| item.js_show_or_hide_function }
    end
    
    def js_show_function
      @items.map { |item| item.js_show_function }
    end
    
    def js_hide_function
      @items.map { |item| item.js_hide_function }
    end
    
    def js_run_elementary_value_setters
      @items.map { |item| item.js_run_elementary_value_setters }
    end
    
  end
  
  class Element
    
    def js_element_references
      []
    end
    
    def js_elementary_value_setters
      []
    end
    
    def js_show_or_hide_functions
      []
    end
    
    def js_show_or_hide_function
      []
    end
    
    def js_run_elementary_value_setters
      []
    end
    
    def js_boolean_value
      raise FormError, "field #{@name.inspect} does not have a boolean value"
    end
    
    def js_string_value
      raise FormError, "field #{@name.inspect} does not have a string value"
    end
    
    def js_assign_value_variables
    end
    
  end
  
  module Labeled
    
    def js_element_references
      @container_variable = @container_id
      @label_variable = "#{@container_variable}_label"
      label_var = (!@parsed_validations || @parsed_validations.empty?) ? [] : "var #{@label_variable} = document.getElementById(#{@label_id.inspect});"
      [
        "var #{@container_variable} = document.getElementById(#{@container_id.inspect});",
        label_var,
        super
      ]
    end
    
    def js_hide_function
      ["  #{@container_variable}.style.display = 'none';"]
    end
    
    def js_show_function
      ["  #{@container_variable}.style.display = '';"]
    end
    
  end
  
  module Named
    
    def js_assign_value_variables
      @value_variable = @id + "_value"
      @value_setter = "set_" + @value_variable
    end
    
    def js_element_references
      @element_variable = @id
      [
        super,
        "var #{@element_variable} = document.getElementById(#{@element_variable.inspect});"
      ]
    end
    
    def js_elementary_value_setters
      to_notify = context[:notifier_map][self] || []
      [
        "var #{@value_variable} = '';",
        "function #{@value_setter}() {",
        "  #{js_calculate_value}",
        to_notify.map { |element| "  #{element.js_do_notify}" },
        "  if (!#{context[:setup_phase_variable]}) { #{context[:global_show_and_hide_function]}(); }",
        "}",
        js_wire_up_events
      ]
    end
    
    def js_wire_up_events
      js_change_events.map do |event|
        "#{@element_variable}.on#{event} = #{@value_setter};"
      end
    end
    
    def js_run_elementary_value_setters
      "#{js_update_value};"
    end
    
    def js_update_value
      "#{@value_setter}()"
    end
    
    def js_string_value
      @value_variable
    end
    
    def js_show_or_hide_function
      [
        "  #{@container_variable}.className = #{@container_variable}.className.replace(/\\b(first|last)\\b/g, '');",
        "  if (is_first_form_element) {",
        "    #{@container_variable}.className += ' first';",
        "  }",
        "  is_first_form_element = false;",
        "  last_form_element = #{@container_variable};",
      ]
    end
    
    def js_hide_function
      [
        super,
        "  #{@element_variable}.disabled = true;"
      ]
    end
    
    def js_show_function
      [
        js_show_or_hide_function,
        super,
        "  #{@element_variable}.disabled = false;"
      ]
    end
    
  end
  
  class Group

    def js_element_references
      @element_variable = @id
      [
        "var #{@element_variable} = document.getElementById(#{@element_variable.inspect});",
        super
      ]
    end
    
    def js_show_or_hide_function
      [
        "  #{@element_variable}.className = #{@element_variable}.className.replace(/\\b(first|last)\\b/g, '');",
        "  if (is_first_form_element) {",
        "    #{@element_variable}.className += ' first';",
        "  }",
        "  #{@element_variable}.style.display = '';",
        "  is_first_form_element = true;",
        "  last_form_element = null;",
        super,
        "  if (last_form_element) { last_form_element.className += ' last'; };",
        "  is_first_form_element = false;",
        "  last_form_element = #{@element_variable};"
      ]
    end
    
    def js_show_function
      [
        "  #{@element_variable}.className = #{@element_variable}.className.replace(/\\b(first|last)\\b/g, '');",
        "  if (is_first_form_element) {",
        "    #{@element_variable}.className += ' first';",
        "  }",
        "  #{@element_variable}.style.display = '';",
        "  is_first_form_element = true;",
        "  last_form_element = null;",
        super,
        "  if (last_form_element) { last_form_element.className += ' last'; };",
        "  is_first_form_element = false;",
        "  last_form_element = #{@element_variable};"
      ]
    end
    
    def js_hide_function
      [
        "  #{@element_variable}.style.display = 'none';",
        super
      ]
    end
    
  end
  
  class DropdownSelect
    
    def js_calculate_value
      "#{@value_variable} = #{@element_variable}[#{@element_variable}.selectedIndex]; if (#{@value_variable}) { #{@value_variable} = #{@value_variable}.value; }"
    end
    
    def js_change_events
      %w[change click]
    end
    
  end
  
  class RadioSelect

    def js_element_references
      @option_variables = []
      results = []
      @option_ids.each do |id|
        @option_variables << id
        results << "var #{id} = document.getElementById(#{id.inspect});"
      end
      [super, results]
    end
    
    def js_calculate_value
      result = '""'
      @option_variables.reverse_each do |variable|
        result = "(%s.checked ? %s.value : %s)" % [variable, variable, result]
      end
      "#{@value_variable} = #{result};"
    end

    def js_change_events
      %w[change click]
    end
    
    def js_wire_up_events
      js_change_events.map do |event|
        @option_variables.map { |variable| "#{variable}.on#{event} = #{@value_setter};" }
      end
    end
    
    def js_show_or_hide_function
      [
        "  #{@container_variable}.className = #{@container_variable}.className.replace(/\\b(first|last)\\b/g, '');",
        "  if (is_first_form_element) {",
        "    #{@container_variable}.className += ' first';",
        "  }",
        "  is_first_form_element = false;",
        "  last_form_element = #{@container_variable};"
      ]
    end

    def js_hide_function
      [
        "  #{@container_id}.style.display = 'none';",
        @option_variables.map { |variable| "  #{variable}.disabled = true;" }
      ]
    end
    
    def js_show_function
      [
        js_show_or_hide_function,
        "  #{@container_variable}.style.display = '';",
        @option_variables.map { |variable| "  #{variable}.disabled = false;" }
      ]
    end
    
  end
  
  class Text
    
    def js_calculate_value
      "#{@value_variable} = #{@element_variable}.value;"
    end
    
    def js_change_events
      %w[change keypress keyup]
    end
    
  end
  
  class CheckBox
    
    def js_calculate_value
      "#{@value_variable} = #{@element_variable}.checked;"
    end
    
    def js_boolean_value
      @value_variable
    end
    
    def js_string_value
      raise FormError, "field #{@name.inspect} does not have a string value"
    end
    
    def js_change_events
      %w[change click]
    end
    
  end
  
  class Info

    def js_element_references
      ["var #{@id} = document.getElementById(#{@id.inspect});"]
    end
    
    def js_show_or_hide_function
      [
        "  #{@id}.className = #{@id}.className.replace(/\\b(first|last)\\b/g, '');",
        "  if (is_first_form_element) {",
        "    #{@id}.className += ' first';",
        "  }",
        "  is_first_form_element = false;",
        "  last_form_element = #{@id};"
      ]
    end
    
    def js_show_function
      [
        js_show_or_hide_function,
        "  #{@id}.style.display = '';"
      ]
    end
    
    def js_hide_function
      ["  #{@id}.style.display = 'none';"]
    end
    
  end
  
  class Link

    def js_element_references
      ["var #{@id} = document.getElementById(#{@id.inspect});"]
    end
    
    def js_show_or_hide_function
      [
        "  #{@id}.className = #{@id}.className.replace(/\\b(first|last)\\b/g, '');",
        "  if (is_first_form_element) {",
        "    #{@id}.className += ' first';",
        "  }",
        "  is_first_form_element = false;",
        "  last_form_element = #{@id};"
      ]
    end
    
    def js_show_function
      [
        js_show_or_hide_function,
        "  #{@id}.style.display = '';"
      ]
    end
    
    def js_hide_function
      ["  #{@id}.style.display = 'none';"]
    end
    
  end
  
  class File
    
    def js_calculate_value
      "#{@value_variable} = #{@element_variable}.value;"
    end
    
    def js_change_events
      %w[change]
    end
    
  end
  
  class Hidden
    
    def js_calculate_value
      "#{@value_variable} = #{@element_variable}.value;"
    end
    
    def js_change_events
      %w[change]
    end
    
    def js_hide_function
      ["  #{@element_variable}.disabled = true;"]
    end
    
    def js_show_function
      ["  #{@element_variable}.disabled = false;"]
    end
    
    def js_show_or_hide_function
      []
    end
    
    def js_hide_function
      ["  #{@element_variable}.disabled = true;"]
    end
    
    def js_show_function
      ["  #{@element_variable}.disabled = false;"]
    end
    
  end
  
  class Conditional

    def js_assign_value_variable
      index = context[:new_index].call
      @set_display_state = "set_notifier#{index}_display_state"
      @hide = "hide_notifier#{index}"
      @show = "show_notifier#{index}"
      @value_variable = "notifier#{index}_value"
      @update_function = "update_#{@value_variable}"
    end
    
    def js_derived_value_notifier
      to_notify = context[:notifier_map][self] || []
      [
        "var #{@value_variable} = '';",
        "function #{@update_function}() {",
        "  #{@value_variable} = #{@parsed_condition.to_js};",
        to_notify.map { |element| "  #{element.js_do_notify}" },
        "}"
      ]
    end
    
    def js_condition
      @value_variable
    end
    
    def js_do_notify
      "#{@update_function}();"
    end
    
    def js_show_or_hide_functions
      [
        "function #{@set_display_state}() { if (#{js_condition}) { #{@show}(); } else { #{@hide}(); } }",
        "function #{@hide}() {",
        old_js_hide_function,
        "}",
        "function #{@show}() {",
        old_js_show_function,
        "}",
        super
      ]
    end
    
    alias old_js_hide_function js_hide_function
    alias old_js_show_function js_show_function
    
    def js_show_or_hide_function
      ["  #{@set_display_state}();"]
    end
    
    def js_hide_function
      ["  #{@hide}();"]
    end
    
    def js_show_function
      ["  #{@set_display_state}();"]
    end
    
  end
  
  module ConditionAST

    class Root

      def to_js
        @condition.to_js
      end

    end
  
    class Or

      def to_js
        '(%s) || (%s)' % [@exp1.to_js, @exp2.to_js]
      end

    end
  
    class And

      def to_js
        '(%s) && (%s)' % [@exp1.to_js, @exp2.to_js]
      end

    end
  
    class Not

      def to_js
        '!(%s)' % @exp.to_js
      end

    end
  
    class Equals

      def to_js
        "(#{@field.js_string_value}) == #{@v.to_string.inspect}"
      end

    end
  
    class NotEquals

      def to_js
        "(#{@field.js_string_value}) != #{@v.to_string.inspect}"
      end

    end
  
    class IsOn

      def to_js
        @field.js_boolean_value
      end

    end
  
    class IsOff

      def to_js
        "!(#{@field.js_boolean_value})"
      end

    end
    
    class IsEmpty
      
      def to_js
        "(#{@field.js_string_value}).match(new RegExp('^\s*$'))"
      end
      
    end
    
    class IsNotEmpty
      
      def to_js
        "!(#{@field.js_string_value}).match(new RegExp('^\s*$'))"
      end
      
    end

  end

end
