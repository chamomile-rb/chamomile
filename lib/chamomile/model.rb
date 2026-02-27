# frozen_string_literal: true

module Chamomile
  # Elm Architecture contract: init, update(msg), view.
  module Model
    def init
      nil
    end

    def update(msg)
      raise NotImplementedError,
            "#{self.class} must implement #update(msg) returning [model, cmd]"
    end

    def view
      ""
    end
  end
end
