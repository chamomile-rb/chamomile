# frozen_string_literal: true

module Chamomile
  module Layout
    class Base
      def render(width:, height:)
        raise NotImplementedError, "#{self.class} must implement render(width:, height:)"
      end
    end
  end
end
