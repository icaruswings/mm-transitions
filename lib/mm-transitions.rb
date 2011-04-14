require 'mongo_mapper'
require 'transitions'

module MongoMapper
  module Plugins
    module Transitions
    
      extend ActiveSupport::Concern

      included do
        include ::Transitions
        
        # adding back after_initialize callback remove in mongomapper
        # https://github.com/jnunemaker/mongomapper/commit/f19d7725039fe352603e9809b0c47898cb9598f3
        define_model_callbacks :initialize, :only => [:after]

        after_initialize :set_initial_state

        key :state, String

        validates_presence_of :state #:required => true
        validate :state_inclusion
      end
    
      module InstanceMethods
        
        # adding back after_initialize callback remove in mongomapper
        # https://github.com/jnunemaker/mongomapper/commit/f19d7725039fe352603e9809b0c47898cb9598f3
        def initialize(attrs = {})
          super.tap { run_callbacks(:initialize) }
        end
        
        def reload
          super.tap do
            self.class.state_machines.values.each do |sm|
              remove_instance_variable(sm.current_state_variable) if instance_variable_defined?(sm.current_state_variable)
            end
          end
        end

        protected

        def write_state(state_machine, state)
          ivar = state_machine.current_state_variable
          prev_state = current_state(state_machine.name)
          instance_variable_set(ivar, state)
          self.state = state.to_s
          save!
        rescue MongoMapper::DocumentNotValid
          self.state = prev_state.to_s
          instance_variable_set(ivar, prev_state)
          raise
        end

        def read_state(state_machine)
          self.state.to_sym
        end

        def set_initial_state
          self.state ||= self.class.state_machine.initial_state.to_s
        end

        def state_inclusion
          unless self.class.state_machine.states.map{ |s| s.name.to_s }.include?(self.state.to_s)
            self.errors.add(:state, :inclusion, :value => self.state)
          end
        end
      end
    end
  end
end