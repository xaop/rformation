module RFormation
  
  class Form
    
    def resolve_form_references
      elements = {}
      with_context :elements => elements, :conditionals => [] do
        collect_elements
      end
      @notifier_map = {}
      to_translate = []
      with_context :elements => elements, :object_scopes => [], :notifier_map => @notifier_map, :to_translate => to_translate do
        resolve_references
      end
      to_translate.each do |el, m|
        el.send(m)
      end
      elements.each do |path, element_list|
        element_list.register_notifiers(@notifier_map)
      end
      @notifier_map.each do |element, to_notify|
        to_notify.uniq!
      end
    end
    
  end

  ElementListPart = Struct.new(:elements, :conditions)
  
  class ElementListPart
    
    include Contextual
    
    def register_notifiers(notifier_map)
      self.elements.each do |element|
        (notifier_map[element] ||= []) << self
      end
      self.conditions.each do |cond, element_list|
        (notifier_map[cond] ||= []) << self
        (notifier_map[element_list] ||= []) << self
        element_list.register_notifiers(notifier_map)
      end
    end
    
  end
  
  class ElementList < ElementListPart
    
  end

  class ContainerElement
    
    def collect_elements
      @items.each { |item| item.collect_elements }
    end
    
    def resolve_references
      @items.each { |item| item.resolve_references }
    end
    
  end

  class Element
    
    def collect_elements
      # By default do nothing for an unnamed element
    end
    
    def register_element(name)
      data = context[:elements][name] ||= ElementList.new([], {})
      context[:conditionals].each do |c|
        data = data.conditions[c] ||= ElementListPart.new([], {})
      end
      data.elements << self
    end
    
    def resolve_references
    end
    
  end

  module Named
    
    def collect_elements
      register_element(@path)
    end
    
  end
  
  module Validated

    def resolve_references
      elements_of_interest = []
      @parsed_validations.each do |validation|
        elements_of_interest |= validation.resolve
      end
      elements_of_interest.each do |e|
        (context[:notifier_map][e] ||= []) << self
      end
      methods.grep(/\Atranslate_validations_to_/).each do |m|
        # send(m)
        context[:to_translate] << [self, m]
      end
    end
    
  end
  
  class Object
    
    def resolve_references
      with_context :object_scopes => context[:object_scopes] + [@path] do
        super
      end
    end
    
  end
  
  class Group
  end
  
  class Conditional
    
    def collect_elements
      with_context :conditionals => context[:conditionals] + [self] do
        super
      end
    end
    
    def resolve_references
      elements_of_interest = @parsed_condition.resolve
      elements_of_interest.each do |e|
        (context[:notifier_map][e] ||= []) << self
      end
      methods.grep(/\Atranslate_condition_to_/).each do |m|
        # send(m)
        context[:to_translate] << [self, m]
      end
      super
    end
    
  end
  
  module ConditionAST
  
    class Node
    
      include ::RFormation::Contextual
    
      def look_up_identifier(id)
        elements = context[:elements]
        if id[0] == ?&
          absolute = true
          id = id[1..-1]
        end
        id = id.split(/&/)
        unless absolute
          context[:object_scopes].reverse_each do |scope|
            full_id = scope + id
            if elements.has_key?(full_id)
              id = full_id
              break
            end
          end
        end
        elements[id]
      end
    
    end

    class Root
    
      def resolve
        condition.resolve.keys
      end
    
    end
  
    class Or
    
      def resolve
        exp1.resolve.merge(exp2.resolve)
      end
    
    end
  
    class And

      def resolve
        exp1.resolve.merge(exp2.resolve)
      end
    
    end
  
    class Not

      def resolve
        exp.resolve
      end
    
    end
  
    class Parentheses
    
      def resolve
        condition.resolve
      end
    
    end
  
    class Equals

      def resolve
        @field = look_up_identifier(f.to_identifier) or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
        { @field => true }
      end
    
    end
  
    class NotEquals
    
      def resolve
        @field = look_up_identifier(f.to_identifier) or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
        { @field => true }
      end
    
    end
  
    class IsOn
    
      def resolve
        @field = look_up_identifier(f.to_identifier) or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
        { @field => true }
      end
    
    end
  
    class IsOff

      def resolve
        @field = look_up_identifier(f.to_identifier) or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
        { @field => true }
      end
    
    end
  
    class IsEmpty
    
      def resolve
        @field = look_up_identifier(f.to_identifier) or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
        { @field => true }
      end
    
    end
  
    class IsNotEmpty

      def resolve
        @field = look_up_identifier(f.to_identifier) or raise RFormation::FormError, "field #{f.to_identifier.inspect} not found"
        { @field => true }
      end
    
    end

  end

end
