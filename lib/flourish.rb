# frozen_string_literal: true

require "chamomile"

unless defined?(Flourish)
  warn "[DEPRECATION] The `flourish` gem is deprecated. Use `chamomile` instead. " \
       "Flourish is now part of Chamomile as of v1.0."
  Flourish = Chamomile
end
