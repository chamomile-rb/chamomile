# frozen_string_literal: true

require_relative "chamomile/version"
require_relative "chamomile/messages"
require_relative "chamomile/model"
require_relative "chamomile/commands"
require_relative "chamomile/layout/base"
require_relative "chamomile/layout/raw"
require_relative "chamomile/layout/text"
require_relative "chamomile/layout/status_bar"
require_relative "chamomile/layout/panel"
require_relative "chamomile/layout/list"
require_relative "chamomile/layout/table"
require_relative "chamomile/layout/spinner"
require_relative "chamomile/layout/vertical"
require_relative "chamomile/layout/horizontal"
require_relative "chamomile/view_dsl"
require_relative "chamomile/application"
require_relative "chamomile/configuration"
require_relative "chamomile/options"
require_relative "chamomile/escape_parser"
require_relative "chamomile/key_map"
require_relative "chamomile/renderer"
require_relative "chamomile/input_reader"
require_relative "chamomile/program"
require_relative "chamomile/keymap"
require_relative "chamomile/router"
require_relative "chamomile/frame"
require_relative "chamomile/testing"
require_relative "chamomile/logging"

# Event-driven Ruby TUI framework.
module Chamomile
  def self.run(model, **opts, &block)
    if block
      config = Configuration.new
      block.call(config)
      opts = config.to_h.merge(opts)
    end
    Program.new(model, **opts).run
  end
end
