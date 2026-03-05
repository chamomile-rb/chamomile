# frozen_string_literal: true

module Chamomile
  # Elm Architecture contract: start, update(msg), view.
  module Model
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Class-level helpers for model configuration.
    module ClassMethods
      # Opt in to enforced immutability. After calling frozen_model!:
      # - The model is frozen after initialize
      # - #with is available to return modified copies
      # - Any direct mutation raises FrozenError immediately
      def frozen_model!
        @frozen_model = true
        prepend(FrozenModelEnforcement)
      end

      def frozen_model?
        @frozen_model == true
      end
    end

    def start
      nil
    end

    def update(msg)
      raise NotImplementedError,
            "#{self.class} must implement #update(msg) returning a command or nil"
    end

    def view
      ""
    end

    # Returns a copy of the model with the given attributes changed.
    def with(**changes)
      current = instance_variables.to_h { |v| [v.to_s.delete_prefix("@").to_sym, instance_variable_get(v)] }
      self.class.new(**current, **changes)
    end

    # Freezes model after initialize for immutability enforcement.
    module FrozenModelEnforcement
      def initialize(...)
        super
        freeze
      end
    end
  end
end
