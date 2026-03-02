# frozen_string_literal: true

module Chamomile
  # Elm Architecture contract: start, update(msg), view.
  module Model
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
  end
end
