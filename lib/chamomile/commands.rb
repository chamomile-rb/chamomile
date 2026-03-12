# frozen_string_literal: true

require "concurrent"
require "open3"

module Chamomile
  # Internal command types intercepted by Program (not delivered to model)
  WindowTitleCommand      = Data.define(:title)
  WindowTitleCmd          = WindowTitleCommand # backward compat

  CursorPositionCommand   = Data.define(:row, :col)
  CursorPositionCmd       = CursorPositionCommand # backward compat

  CursorShapeCommand      = Data.define(:shape)
  CursorShapeCmd          = CursorShapeCommand # backward compat

  CursorVisibilityCommand = Data.define(:visible)
  CursorVisibilityCmd     = CursorVisibilityCommand # backward compat

  ExecCommand             = Data.define(:command, :args, :callback)
  ExecCmd                 = ExecCommand # backward compat

  PrintlnCommand          = Data.define(:text)
  PrintlnCmd              = PrintlnCommand # backward compat

  # Internal compound/control command types
  CancelCommand = Data.define(:token)
  CancelCmd     = CancelCommand # backward compat

  StreamCommand = Data.define(:token, :producer)
  StreamCmd     = StreamCommand # backward compat

  # Typed envelope for shell command results
  ShellResult = Data.define(:envelope, :stdout, :stderr, :status, :success)

  # Typed envelope for timer ticks
  TimerTick = Data.define(:envelope, :time)

  # Runtime mode-toggle messages (returned as Cmd from update, intercepted by Program)
  EnterAltScreenMsg     = Data.define
  ExitAltScreenMsg      = Data.define
  EnableMouseCellMotionMsg  = Data.define
  EnableMouseAllMotionMsg   = Data.define
  DisableMouseMsg = Data.define
  EnableBracketedPasteMsg   = Data.define
  DisableBracketedPasteMsg  = Data.define
  EnableReportFocusMsg  = Data.define
  DisableReportFocusMsg = Data.define
  ClearScreenMsg        = Data.define
  RequestWindowSizeMsg  = Data.define

  # A cancel token for cancellable commands.
  class CancelToken
    def initialize
      @cancelled = Concurrent::AtomicBoolean.new(false)
    end

    def cancel!
      @cancelled.make_true
    end

    def cancelled?
      @cancelled.true?
    end
  end

  # Helper methods for creating command lambdas (quit, batch, tick, etc.).
  module Commands
    def quit
      -> { QuitEvent.new }
    end

    def none
      nil
    end

    def batch(*cmds)
      valid = cmds.flatten.compact
      return nil if valid.empty?

      -> { valid }
    end

    def sequence(*cmds)
      valid = cmds.flatten.compact
      return nil if valid.empty?

      -> { [:sequence, *valid] }
    end

    # Run commands concurrently (Ruby-idiomatic alias for batch)
    alias parallel batch

    # Run commands in order (Ruby-idiomatic alias for sequence)
    alias serial sequence

    def tick(duration, &block)
      -> {
        sleep(duration)
        block ? block.call : TickEvent.new(time: Time.now)
      }
    end

    def every(duration, &block)
      -> {
        now = Time.now
        next_tick = (now + duration) - (now.to_f % duration)
        sleep(next_tick - Time.now)
        block ? block.call : TickEvent.new(time: Time.now)
      }
    end

    def cmd(callable)
      -> { callable.call }
    end

    # Posts a message directly to the event queue — no thread, no async.
    def deliver(msg)
      -> { msg }
    end

    # Transforms a command's result before it reaches update.
    def map(cmd, &transform)
      return nil if cmd.nil?

      -> {
        result = cmd.call
        result ? transform.call(result) : nil
      }
    end

    # Creates a cancel token and returns [token, command_wrapper].
    # The block receives the token for cooperative cancellation checking.
    def cancellable(&block)
      token = CancelToken.new
      wrapped = -> {
        return nil if token.cancelled?

        block.call(token)
      }
      [token, wrapped]
    end

    # Returns a command that cancels a running token.
    def cancel(token)
      -> { CancelCommand.new(token: token) }
    end

    # A streaming command that emits multiple messages over time.
    # The block receives a `push` callable and a `token` for cancellation.
    # Returns [cancel_token, command].
    def stream(&block)
      token = CancelToken.new
      cmd = -> {
        return nil if token.cancelled?

        StreamCommand.new(token: token, producer: block)
      }
      [token, cmd]
    end

    # Run a shell command and return a ShellResult message with the given envelope name.
    def shell(command, envelope:, dir: Dir.pwd, env: {})
      -> {
        stdout, stderr, status = Open3.capture3(env, command, chdir: dir)
        ShellResult.new(
          envelope: envelope,
          stdout: stdout.force_encoding("UTF-8"),
          stderr: stderr.force_encoding("UTF-8"),
          status: status.exitstatus,
          success: status.success?
        )
      }
    end

    # Fire a timer message with a typed envelope.
    def timer(duration, envelope:)
      -> {
        sleep(duration)
        TimerTick.new(envelope: envelope, time: Time.now)
      }
    end

    def window_title(title)
      -> { WindowTitleCommand.new(title: title) }
    end

    def cursor_position(row, col)
      -> { CursorPositionCommand.new(row: row, col: col) }
    end

    def cursor_shape(shape)
      -> { CursorShapeCommand.new(shape: shape) }
    end

    def show_cursor
      -> { CursorVisibilityCommand.new(visible: true) }
    end

    def hide_cursor
      -> { CursorVisibilityCommand.new(visible: false) }
    end

    def exec(command, *args, &callback)
      -> { ExecCommand.new(command: command, args: args, callback: callback) }
    end

    # Print a line above the rendered TUI area
    def println(text)
      -> { PrintlnCommand.new(text: text) }
    end

    # Runtime mode toggles — return these as commands from update
    def enter_alt_screen
      -> { EnterAltScreenMsg.new }
    end

    def exit_alt_screen
      -> { ExitAltScreenMsg.new }
    end

    def enable_mouse_cell_motion
      -> { EnableMouseCellMotionMsg.new }
    end

    def enable_mouse_all_motion
      -> { EnableMouseAllMotionMsg.new }
    end

    def disable_mouse
      -> { DisableMouseMsg.new }
    end

    def enable_bracketed_paste
      -> { EnableBracketedPasteMsg.new }
    end

    def disable_bracketed_paste
      -> { DisableBracketedPasteMsg.new }
    end

    def enable_report_focus
      -> { EnableReportFocusMsg.new }
    end

    def disable_report_focus
      -> { DisableReportFocusMsg.new }
    end

    def clear_screen
      -> { ClearScreenMsg.new }
    end

    def request_window_size
      -> { RequestWindowSizeMsg.new }
    end

    module_function :quit, :none, :batch, :sequence, :parallel, :serial,
                    :tick, :every, :cmd,
                    :deliver, :map, :cancellable, :cancel, :stream,
                    :shell, :timer,
                    :window_title, :cursor_position, :cursor_shape,
                    :show_cursor, :hide_cursor, :exec, :println,
                    :enter_alt_screen, :exit_alt_screen,
                    :enable_mouse_cell_motion, :enable_mouse_all_motion, :disable_mouse,
                    :enable_bracketed_paste, :disable_bracketed_paste,
                    :enable_report_focus, :disable_report_focus,
                    :clear_screen, :request_window_size
  end
end
