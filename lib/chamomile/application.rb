# frozen_string_literal: true

module Chamomile
  # Primary mixin for Chamomile applications. Combines Model + Commands
  # and provides a declarative callback DSL for handling events.
  #
  #   class Counter
  #     include Chamomile::Application
  #
  #     def initialize
  #       @count = 0
  #     end
  #
  #     on_key(:up, "k")  { @count += 1 }
  #     on_key(:down, "j") { @count -= 1 }
  #     on_key("q")        { quit }
  #
  #     def view
  #       "Count: #{@count}"
  #     end
  #   end
  module Application
    # Include Model and Commands into Application itself (not the base class)
    # so that Application's methods appear earlier in the MRO and can
    # override Model's default NotImplementedError on update.
    include Model
    include Commands
    include ViewDSL

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Default update that dispatches to DSL-registered handlers.
    # If a class defines its own `update(msg)`, that takes precedence
    # over this (standard Ruby MRO).
    def update(msg)
      self.class._dispatch_event(self, msg)
    end

    module ClassMethods
      # Register a handler for one or more key values.
      # Keys can be symbols (:up, :down, :enter, etc.) or strings ("q", "k").
      #
      #   on_key(:up, "k") { @count += 1 }
      #   on_key("q") { quit }
      def on_key(*keys, &block)
        keys.each do |key|
          _key_handlers[key] = block
        end
      end

      # Register a handler for terminal resize events.
      #
      #   on_resize { |e| @width = e.width; @height = e.height }
      def on_resize(&block)
        _event_handlers[:resize] = block
      end

      # Register a handler for tick events.
      #
      #   on_tick { refresh_data }
      def on_tick(&block)
        _event_handlers[:tick] = block
      end

      # Register a handler for mouse events.
      #
      #   on_mouse { |e| handle_click(e) if e.press? }
      def on_mouse(&block)
        _event_handlers[:mouse] = block
      end

      # Register a handler for focus events.
      #
      #   on_focus { @focused = true }
      def on_focus(&block)
        _event_handlers[:focus] = block
      end

      # Register a handler for blur events.
      #
      #   on_blur { @focused = false }
      def on_blur(&block)
        _event_handlers[:blur] = block
      end

      # Register a handler for paste events.
      #
      #   on_paste { |e| @clipboard = e.content }
      def on_paste(&block)
        _event_handlers[:paste] = block
      end

      # @api private — Key handlers hash (key_value → block)
      def _key_handlers
        @_key_handlers ||= {}
      end

      # @api private — Event handlers hash (event_type → block)
      def _event_handlers
        @_event_handlers ||= {}
      end

      # @api private — Dispatch an event to registered handlers.
      # Returns command (a callable) or nil.
      #
      # The block's return value is the command. If you need to return a command
      # (like `quit` or `tick`), ensure it is the last expression in the block:
      #
      #   on_key("q") { @cleaning_up = true; quit }   # correct — quit is last
      #   on_key("q") { quit; @cleaning_up = true }   # BUG — quit is discarded
      #
      def _dispatch_event(instance, msg)
        handler = case msg
                  when KeyEvent    then _key_handlers[msg.key]
                  when ResizeEvent then _event_handlers[:resize]
                  when TickEvent   then _event_handlers[:tick]
                  when MouseEvent  then _event_handlers[:mouse]
                  when FocusEvent  then _event_handlers[:focus]
                  when BlurEvent   then _event_handlers[:blur]
                  when PasteEvent  then _event_handlers[:paste]
                  end

        return nil unless handler

        result = instance.instance_exec(msg, &handler)
        # Only return the result if it's a callable command (Proc/Lambda).
        # Handler blocks often return non-command values (e.g., @count += 1 returns an Integer).
        result.respond_to?(:call) ? result : nil
      end

      def inherited(subclass)
        super
        # Copy handlers to subclass so parent handlers are inherited
        subclass.instance_variable_set(:@_key_handlers, _key_handlers.dup)
        subclass.instance_variable_set(:@_event_handlers, _event_handlers.dup)
      end
    end
  end
end
