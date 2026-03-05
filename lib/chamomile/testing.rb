# frozen_string_literal: true

module Chamomile
  # Test harness for running a Chamomile model without a real terminal.
  module Testing
    # Runs a Chamomile model without a real terminal for testing.
    class Harness
      attr_reader :model, :messages, :commands_run

      def initialize(model, width: 80, height: 24)
        @model = model
        @width = width
        @height = height
        @messages = []
        @commands_run = []
        @snapshots = {}
        @quit = false

        # Deliver initial window size
        deliver(Chamomile::WindowSizeMsg.new(width: width, height: height))

        # Run start command if any
        if (start_cmd = model.start)
          run_cmd_sync(start_cmd)
        end
      end

      # Send a key event to the model
      def send_key(key, mod: [])
        deliver(Chamomile::KeyMsg.new(key: key, mod: Array(mod)))
      end

      # Send a mouse event
      def send_mouse(x:, y:, button: :left, action: :press, mod: [])
        deliver(Chamomile::MouseMsg.new(x: x, y: y, button: button, action: action, mod: mod))
      end

      # Send any message directly
      def send_msg(msg)
        deliver(msg)
      end

      # Simulate a terminal resize
      def resize(width, height)
        @width = width
        @height = height
        deliver(Chamomile::WindowSizeMsg.new(width: width, height: height))
      end

      # Get current rendered view
      def view
        @model.view
      end

      # Assert snapshot — normalizes view through optional block
      def assert_snapshot(name, &normalize)
        rendered = view
        rendered = normalize.call(rendered.lines).join if normalize
        if @snapshots.key?(name)
          raise SnapshotMismatch.new(name, @snapshots[name], rendered) unless @snapshots[name] == rendered
        else
          @snapshots[name] = rendered
        end
        rendered
      end

      # Returns true if the model has quit
      def quit?
        @quit
      end

      private

      def deliver(msg)
        @messages << msg
        cmd = @model.update(msg)
        run_cmd_sync(cmd) if cmd
      end

      # Run a command synchronously for test determinism.
      def run_cmd_sync(cmd)
        return if cmd.nil?

        @commands_run << cmd
        result = begin
          cmd.call
        rescue StandardError => e
          ErrorMsg.new(error: e)
        end

        case result
        when Array
          if result[0] == :sequence
            result[1..].compact.each { |c| run_cmd_sync(c) }
          else
            result.compact.each { |c| run_cmd_sync(c) }
          end
        when CancelCmd
          result.token.cancel!
        when StreamCmd
          # In test mode, run stream producer synchronously with a collecting push
          push = ->(m) { deliver(m) if m && !@quit }
          result.producer.call(push, result.token)
        when QuitMsg
          @quit = true
        when ErrorMsg
          raise result.error
        when WindowTitleCmd, CursorPositionCmd, CursorShapeCmd, CursorVisibilityCmd,
             ExecCmd, PrintlnCmd,
             EnterAltScreenMsg, ExitAltScreenMsg,
             EnableMouseCellMotionMsg, EnableMouseAllMotionMsg, DisableMouseMsg,
             EnableBracketedPasteMsg, DisableBracketedPasteMsg,
             EnableReportFocusMsg, DisableReportFocusMsg,
             ClearScreenMsg, RequestWindowSizeMsg
          # Runtime commands — intercepted, not delivered to model
        when NilClass
          # no-op
        else
          deliver(result)
        end
      end
    end

    # Raised when a snapshot assertion fails.
    class SnapshotMismatch < StandardError
      def initialize(name, expected, actual)
        super("Snapshot '#{name}' mismatch.\nExpected:\n#{expected}\n\nActual:\n#{actual}")
      end
    end
  end
end
