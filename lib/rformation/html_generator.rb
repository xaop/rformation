# This file reopens the classes inside RFormation to add the
# funtionality to generate a HTML version of the form.
# You may want to consult form.rb to find out how the classes
# and modules are related.
module RFormation

  class ContainerElement
    
    def assign_ids
      @items.each do |item|
        item.assign_ids
      end
    end
    
    def to_html
      H {%{
        - @items.each do |item|
          = item.to_html
      }}
    end
    
    def html_update_mandatory_labels
      @items.each { |item| item.html_update_mandatory_labels }
    end

  end
  
  class Form
    
    def to_html(options = {})
      list_of_values = options.delete(:lists_of_values) || proc {}
      data = options.delete(:data) || {}
      options.empty? or raise "unknown options #{options.keys.join(", ")}"
      
      index = 0
      with_context :new_index => proc { index += 1 } do
        assign_ids
      end
      html_update_mandatory_labels
      with_context :list_of_values => list_of_values, :data => data, :group_level => 0 do
        H {%{
          = fields_to_html
          = fields_to_js
        }}
      end
    end
    
    def fields_to_html
      H {%{
        - @items.each do |item|
          = item.to_html
      }}
    end

  end
  
  class Element

    def assign_ids
    end
    
    def path_to_name
      @path[0] + @path[1..-1].map { |p| "[#{p}]" }.join
    end
    
    def html_update_mandatory_labels
    end

  end
  
  module Validated
    
    def html_update_mandatory_labels
      @label = "* " + @label if @mandatory
    end

  end

  module Named
    
    def assign_ids
      super
      @id = "element#{context[:new_index].call}"
    end

  end
  
  module Labeled
    
    def assign_ids
      index = context[:new_index].call
      @container_id = "element#{index}"
      @label_id = "#{@container_id}_label"
      super
    end
    
    def to_html(text)
      content = H {%{
        %label{ :id => @container_id, :class => @class }
          %span{ :id => @label_id }= h @label
          = text
      }}
    end
    
  end
  
  class Group
    
    def assign_ids
      @id = "element#{context[:new_index].call}"
      super
    end
    
    def to_html
      level = context[:group_level] + 1
      with_context :group_level => level do
        H {%{
          %fieldset{ :class => @class + " level#{level}", :id => @id }
            - unless @caption.to_s.strip.empty?
              %legend= h @caption
            - @items.each do |item|
              = item.to_html
        }}
      end
    end
    
  end
  
  class DropdownSelect
    
    def to_html
      selected = fetch_value_by_path
      content = H {%{
        %select{ :name => path_to_name, :id => @id, :multiple => @multivalue ? "multiple" : nil }
          - entries(context[:list_of_values]).each do |id, label, default|
            - if selected
              - default = (id == selected)
            %option{ default ? { :selected => "selected" } : {}, :value => id }= h label
      }}
      super(content)
    end
    
  end
  
  class RadioSelect
    
    def to_html
      @actual_values = entries(context[:list_of_values])
      @option_ids = []
      selected = fetch_value_by_path
      content = H {%{
        %fieldset{ :id => @container_id, :class => @class + " radio" }
          %legend{ :id => @label_id }= h @label
          - @actual_values.each_with_index do |(id, label, default), i|
            - option_id = "%s_%d" % [@id, i]
            - @option_ids << option_id
            - if selected
              - default = (id == selected)
            %label
              %input.radio{ default ? { :checked => "checked" } : {}, :type => 'radio', :value => id, :id => option_id, :name => path_to_name }
              = h label
      }}
    end

  end
  
  class File
    
    def to_html
      content = H {%{
        %input{ :type => 'file', :id => @id, :name => path_to_name }
      }}
      super(content)
    end
    
  end
  
  class Text
    
    def to_html
      value = fetch_value_by_path(@value)
      content = H {%{
        - if @multi
          %textarea{ :id => @id, :name => path_to_name, :cols => @width, :rows => @height }= h value
        - else
          %input{ :type => 'text', :id => @id, :name => path_to_name, :value => value }
      }}
      super(content)
    end
    
  end
  
  class Info
    
    def assign_ids
      super
      @id = "element#{context[:new_index].call}"
    end

    def to_html
      H {%{
        %span{ :class => "info " + (@class || ""), :id => @id }= @text
      }}
    end
    
  end
  
  class Link
    
    def assign_ids
      super
      @id = "element#{context[:new_index].call}"
    end

    def to_html
      H {%{
        %a{ :href => @url, :id => @id, :class => @class }= h @label
      }}
    end
    
  end
  
  class CheckBox
    
    def to_html
      on = fetch_value_by_path(@on_by_default)
      content = H {%{
        %input{ on ? { :checked => "checked" } : {}, :type => 'checkbox', :id => @id, :name => path_to_name, :class => "checkbox" }
      }}
      super(content)
    end

  end
  
  class Hidden
    
    def to_html
      value = fetch_value_by_path(@value)
      H {%{
        %input{ :type => 'hidden', :value => value, :name => path_to_name, :id => @id }
      }}
    end
    
  end
  
  class Object
  end
  
  class Conditional
  end

end
