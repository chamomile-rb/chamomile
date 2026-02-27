# frozen_string_literal: true

module Chamomile
  VALID_MOUSE_MODES = %i[none cell_motion all_motion].freeze

  # Immutable configuration for a Program run.
  Options = Data.define(
    :alt_screen,
    :mouse,
    :report_focus,
    :bracketed_paste,
    :fps,
    :input,
    :output,
    :filter,
    :catch_panics,
    :handle_signals,
    :input_tty,
    :without_renderer,
    :initial_width,
    :initial_height
  ) do
    def self.default(**overrides)
      opts = new(alt_screen: true,
                 mouse: :none,
                 report_focus: false,
                 bracketed_paste: true,
                 fps: 60,
                 input: $stdin,
                 output: $stdout,
                 filter: nil,
                 catch_panics: true,
                 handle_signals: true,
                 input_tty: false,
                 without_renderer: false,
                 initial_width: nil,
                 initial_height: nil, **overrides)

      opts.validate!
      opts
    end

    def validate!
      unless VALID_MOUSE_MODES.include?(mouse)
        raise ArgumentError, "invalid mouse mode: #{mouse.inspect} (valid: #{VALID_MOUSE_MODES.join(", ")})"
      end

      unless fps.is_a?(Numeric) && fps >= 0
        raise ArgumentError, "fps must be a non-negative number, got: #{fps.inspect}"
      end

      return unless filter && !filter.respond_to?(:call)

      raise ArgumentError, "filter must respond to #call, got: #{filter.class}"
    end
  end
end
