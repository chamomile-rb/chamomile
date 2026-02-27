# frozen_string_literal: true

module Chamomile
  BatchCmd    = Data.define(:cmds)
  SequenceCmd = Data.define(:cmds)

  # Internal command types intercepted by Program (not delivered to model)
  WindowTitleCmd       = Data.define(:title)
  CursorPositionCmd    = Data.define(:row, :col)
  CursorShapeCmd       = Data.define(:shape)
  CursorVisibilityCmd  = Data.define(:visible)
  ExecCmd              = Data.define(:command, :args, :callback)
  PrintlnCmd           = Data.define(:text)

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

  # Helper methods for creating command lambdas (quit, batch, tick, etc.).
  module Commands
    def quit
      -> { QuitMsg.new }
    end

    def none
      nil
    end

    def batch(*cmds)
      valid = cmds.flatten.compact
      return nil if valid.empty?

      -> { BatchCmd.new(cmds: valid) }
    end

    def sequence(*cmds)
      valid = cmds.flatten.compact
      return nil if valid.empty?

      -> { SequenceCmd.new(cmds: valid) }
    end

    def tick(duration, &block)
      -> {
        sleep(duration)
        block ? block.call : TickMsg.new(time: Time.now)
      }
    end

    def every(duration, &block)
      -> {
        now = Time.now
        next_tick = (now + duration) - (now.to_f % duration)
        sleep(next_tick - Time.now)
        block ? block.call : TickMsg.new(time: Time.now)
      }
    end

    def cmd(callable)
      -> { callable.call }
    end

    def window_title(title)
      -> { WindowTitleCmd.new(title: title) }
    end

    def cursor_position(row, col)
      -> { CursorPositionCmd.new(row: row, col: col) }
    end

    def cursor_shape(shape)
      -> { CursorShapeCmd.new(shape: shape) }
    end

    def show_cursor
      -> { CursorVisibilityCmd.new(visible: true) }
    end

    def hide_cursor
      -> { CursorVisibilityCmd.new(visible: false) }
    end

    def exec(command, *args, &callback)
      -> { ExecCmd.new(command: command, args: args, callback: callback) }
    end

    # Print a line above the rendered TUI area
    def println(text)
      -> { PrintlnCmd.new(text: text) }
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

    module_function :quit, :none, :batch, :sequence, :tick, :every, :cmd,
                    :window_title, :cursor_position, :cursor_shape,
                    :show_cursor, :hide_cursor, :exec, :println,
                    :enter_alt_screen, :exit_alt_screen,
                    :enable_mouse_cell_motion, :enable_mouse_all_motion, :disable_mouse,
                    :enable_bracketed_paste, :disable_bracketed_paste,
                    :enable_report_focus, :disable_report_focus,
                    :clear_screen, :request_window_size
  end
end
