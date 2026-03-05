# frozen_string_literal: true

module Chamomile
  # Declarative keymap with composable guard conditions.
  #
  # Usage:
  #   @keymap = Keymap.new
  #     .bind("q")               { quit }
  #     .bind(:tab)              { focus_next }
  #     .only(-> { !modal_open? }) do |km|
  #       km.bind("j")           { scroll_down }
  #       km.bind("k")           { scroll_up }
  #     end
  #
  # Then in update:
  #   def update(msg)
  #     return @keymap.handle(msg, self) if msg.is_a?(KeyMsg)
  #     ...
  #   end
  class Keymap
    Entry = Data.define(:key, :guard, :action)

    def initialize
      @entries = []
    end

    # Bind a key to a block. Returns self for chaining.
    def bind(key, guard: nil, &action)
      @entries << Entry.new(key: key, guard: guard, action: action)
      self
    end

    # Add a group of bindings that only fire when guard returns true.
    # Guard is a Proc that receives the model.
    def only(guard, &block)
      sub = self.class.new
      block.call(sub)
      sub.entries.each do |entry|
        combined_guard = if entry.guard
                           ->(m) { guard.call(m) && entry.guard.call(m) }
                         else
                           guard
                         end
        @entries << Entry.new(key: entry.key, guard: combined_guard, action: entry.action)
      end
      self
    end

    # Process a KeyMsg against the keymap.
    # Returns the result of the matching action, or nil if no match.
    def handle(msg, model)
      return nil unless msg.is_a?(KeyMsg)

      @entries.each do |entry|
        next unless keys_match?(entry.key, msg)
        next if entry.guard && !entry.guard.call(model)

        return model.instance_exec(&entry.action)
      end
      nil
    end

    protected

    attr_reader :entries

    private

    def keys_match?(expected, msg)
      case expected
      when Symbol, String then msg.key == expected
      when Array          then expected.include?(msg.key)
      else false
      end
    end
  end
end
