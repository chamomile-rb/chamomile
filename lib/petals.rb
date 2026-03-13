# frozen_string_literal: true

require "chamomile"

unless defined?(Petals)
  warn "[DEPRECATION] The `petals` gem is deprecated. Use `chamomile` instead. " \
       "Petals is now part of Chamomile as of v1.0."
  Petals = Chamomile
end
