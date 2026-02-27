require_relative "chamomile/version"
require_relative "chamomile/messages"
require_relative "chamomile/model"
require_relative "chamomile/commands"
require_relative "chamomile/key_map"
require_relative "chamomile/renderer"
require_relative "chamomile/input_reader"
require_relative "chamomile/program"

module Chamomile
  def self.run(model, **opts)
    Program.new(model, **opts).run
  end
end
