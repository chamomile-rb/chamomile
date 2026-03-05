# frozen_string_literal: true

require_relative "chamomile/version"
require_relative "chamomile/messages"
require_relative "chamomile/model"
require_relative "chamomile/commands"
require_relative "chamomile/options"
require_relative "chamomile/escape_parser"
require_relative "chamomile/key_map"
require_relative "chamomile/renderer"
require_relative "chamomile/input_reader"
require_relative "chamomile/program"
require_relative "chamomile/keymap"
require_relative "chamomile/router"
require_relative "chamomile/testing"
require_relative "chamomile/logging"

# Ruby TUI framework based on the Elm Architecture.
module Chamomile
  def self.run(model, **)
    Program.new(model, **).run
  end
end
