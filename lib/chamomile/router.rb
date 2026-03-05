# frozen_string_literal: true

module Chamomile
  # Mixin for panel-level key routing.
  # Each panel declares its own keymap, which the parent App delegates to.
  #
  # Usage:
  #   class ServerPanel
  #     include Chamomile::Router
  #
  #     keymap do |km|
  #       km.bind("s") { start_server }
  #       km.bind("S") { stop_server }
  #     end
  #   end
  module Router
    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@panel_keymap_block, nil)
    end

    # Class-level keymap declaration.
    module ClassMethods
      def keymap(&block)
        @panel_keymap_block = block
      end

      def panel_keymap_block
        @panel_keymap_block
      end
    end

    def handle_panel_key(msg)
      block = self.class.panel_keymap_block
      return nil unless block

      km = Chamomile::Keymap.new
      block.call(km)
      km.handle(msg, self)
    end
  end
end
