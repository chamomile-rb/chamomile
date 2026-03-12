# frozen_string_literal: true

module Chamomile
  module Layout
    class Raw < Base
      def initialize(string)
        @string = string.to_s
      end

      def render(width:, height:)
        @string
      end
    end
  end
end
