# frozen_string_literal: true

require "io/console"

module Chamomile
  # Main event loop — wires up Model, Renderer, and InputReader.
  class Program
    def initialize(model, output: nil, input: nil, options: nil, **opts)
      # Build options: explicit options struct takes priority, then kwargs merge into defaults
      if options
        @options = options
      else
        overrides = {}
        overrides[:output] = output if output
        overrides[:input] = input if input
        overrides.merge!(opts.slice(:alt_screen, :mouse, :report_focus, :bracketed_paste,
                                    :fps, :filter, :catch_panics, :handle_signals,
                                    :input_tty, :without_renderer,
                                    :initial_width, :initial_height))
        @options = Options.default(**overrides)
      end

      @model        = model
      @output       = @options.output
      @input        = resolve_input
      @msgs         = Queue.new
      @renderer     = if @options.without_renderer
                        NullRenderer.new
                      else
                        Renderer.new(output: @output, fps: @options.fps)
                      end
      @input_reader = InputReader.new(@msgs, input: @input)
      @running      = false
      @torn_down    = false
      @done_mutex   = Mutex.new
      @done_cv      = ConditionVariable.new
      @done         = false
      @stty_state   = nil

      at_exit { system("stty #{@stty_state}") if @stty_state }
    end

    def run
      @running = true

      if @options.catch_panics
        begin
          run_inner
        rescue StandardError => e
          teardown_terminal
          Chamomile.log("Panic: #{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}", level: :error)
          raise
        end
      else
        run_inner
      end
    ensure
      signal_done
    end

    def send_msg(msg)
      @msgs.push(msg)
    end

    # Quit gracefully — model gets a final QuitMsg
    def quit!
      @msgs.push(QuitMsg.new)
    end

    # Kill immediately — no final message, no cleanup render
    def kill!
      @running = false
      @msgs.push(QuitMsg.new)
    end

    # Block until the program finishes running
    def wait
      @done_mutex.synchronize do
        @done_cv.wait(@done_mutex) until @done
      end
    end

    private

    def signal_done
      @done_mutex.synchronize do
        @done = true
        @done_cv.broadcast
      end
    end

    def resolve_input
      if @options.input_tty
        # Open /dev/tty directly for interactive input even when stdin is piped
        begin
          File.open("/dev/tty", "r")
        rescue Errno::ENOENT, Errno::EACCES
          Chamomile.log("Could not open /dev/tty, falling back to configured input", level: :warn)
          @options.input
        end
      else
        @options.input
      end
    end

    def run_inner
      setup_terminal

      send_msg(build_window_size_msg)

      if (start_cmd = @model.start)
        run_cmd(start_cmd)
      end

      @renderer.render(@model.view)

      event_loop

      @model
    ensure
      teardown_terminal
    end

    def event_loop
      while @running
        msg = @msgs.pop

        # Apply message filter if configured
        if @options.filter
          msg = @options.filter.call(@model, msg)
          next if msg.nil?
        end

        case msg
        when QuitMsg
          @running = false
          break
        when InterruptMsg
          begin
            cmd = @model.update(msg)
            run_cmd(cmd) if cmd
            @renderer.render(@model.view)
          rescue NotImplementedError
            # Model doesn't implement update — default to quitting on Ctrl-C
            @running = false
            break
          end
          next
        when SuspendMsg
          handle_suspend
          next
        when WindowSizeMsg
          @renderer.resize(msg.width, msg.height)
          # Fall through -- also deliver to model
        when BatchCmd
          msg.cmds.each { |c| run_cmd(c) }
          next
        when SequenceCmd
          run_sequence(msg.cmds)
          next
        when ErrorMsg
          raise msg.error

        # Renderer commands — intercepted, not delivered to model
        when WindowTitleCmd
          @renderer.write_window_title(msg.title)
          next
        when CursorPositionCmd
          @renderer.move_cursor(msg.row, msg.col)
          next
        when CursorShapeCmd
          @renderer.apply_cursor_shape(msg.shape)
          next
        when CursorVisibilityCmd
          msg.visible ? @renderer.show_cursor : @renderer.hide_cursor
          next
        when ExecCmd
          handle_exec(msg)
          next
        when PrintlnCmd
          @renderer.println_above(msg.text)
          next

        # Runtime mode toggles — intercepted, not delivered to model
        when EnterAltScreenMsg
          @renderer.enter_alt_screen
          @renderer.clear
          @renderer.render(@model.view)
          next
        when ExitAltScreenMsg
          @renderer.exit_alt_screen
          @renderer.enter_inline_mode
          @renderer.render(@model.view)
          next
        when EnableMouseCellMotionMsg
          write_escape("\e[?1002h\e[?1006h")
          next
        when EnableMouseAllMotionMsg
          write_escape("\e[?1003h\e[?1006h")
          next
        when DisableMouseMsg
          write_escape("\e[?1002l\e[?1003l\e[?1006l")
          next
        when EnableBracketedPasteMsg
          write_escape("\e[?2004h")
          next
        when DisableBracketedPasteMsg
          write_escape("\e[?2004l")
          next
        when EnableReportFocusMsg
          write_escape("\e[?1004h")
          next
        when DisableReportFocusMsg
          write_escape("\e[?1004l")
          next
        when ClearScreenMsg
          @renderer.clear
          @renderer.render(@model.view)
          next
        when RequestWindowSizeMsg
          send_msg(build_window_size_msg)
          next
        end

        cmd = @model.update(msg)

        run_cmd(cmd) if cmd

        @renderer.render(@model.view)
      end
    end

    def handle_suspend
      deliver_to_model(SuspendMsg.new)

      teardown_terminal
      Process.kill("SIGSTOP", Process.pid)

      # After SIGCONT, we resume here
      setup_terminal
      send_msg(build_window_size_msg)

      deliver_to_model(ResumeMsg.new)

      @renderer.render(@model.view)
    end

    def handle_exec(msg)
      @input_reader.stop
      teardown_terminal

      success = system(msg.command, *msg.args)

      setup_terminal
      send_msg(build_window_size_msg)

      if msg.callback
        begin
          result = msg.callback.call(success)
          @msgs.push(result) if result && @running
        rescue StandardError => e
          @msgs.push(ErrorMsg.new(error: e)) if @running
        end
      end

      @renderer.force_render(@model.view)
    end

    def run_cmd(cmd)
      return if cmd.nil?

      Thread.new do
        result = cmd.call
        @msgs.push(result) if result && @running
      rescue StandardError => e
        @msgs.push(ErrorMsg.new(error: e)) if @running
      end
    end

    def run_sequence(cmds)
      Thread.new do
        cmds.each do |cmd|
          next if cmd.nil?

          begin
            result = cmd.call
            @msgs.push(result) if result && @running
            sleep(0.001)
          rescue StandardError => e
            @msgs.push(ErrorMsg.new(error: e)) if @running
            break
          end
        end
      end
    end

    def setup_terminal
      @torn_down = false
      @stty_state = begin
        `stty -g`.chomp
      rescue StandardError
        nil
      end
      begin
        system("stty raw -echo -isig")
      rescue StandardError
        nil
      end

      if @options.alt_screen
        @renderer.enter_alt_screen
      else
        @renderer.enter_inline_mode
      end
      @renderer.hide_cursor
      @renderer.clear if @options.alt_screen

      # Enable mouse mode
      case @options.mouse
      when :cell_motion then @output.write("\e[?1002h\e[?1006h")
      when :all_motion  then @output.write("\e[?1003h\e[?1006h")
      end

      # Enable bracketed paste
      @output.write("\e[?2004h") if @options.bracketed_paste

      # Enable focus reporting
      @output.write("\e[?1004h") if @options.report_focus

      @output.flush

      # Signal handling
      if @options.handle_signals
        Signal.trap("SIGWINCH") { @msgs.push(build_window_size_msg) }
        Signal.trap("SIGINT") { @msgs.push(InterruptMsg.new) }
        Signal.trap("SIGTERM") { @msgs.push(QuitMsg.new) }
        begin
          Signal.trap("SIGTSTP") do
            @msgs.push(SuspendMsg.new)
          end
        rescue ArgumentError # rubocop:disable Lint/SuppressedException -- SIGTSTP unsupported on some platforms
        end
        begin
          Signal.trap("SIGCONT") { nil } # no-op to prevent default
        rescue ArgumentError # rubocop:disable Lint/SuppressedException -- SIGCONT unsupported on some platforms
        end
      end

      @input_reader.start
    end

    def teardown_terminal
      return if @torn_down

      @torn_down = true
      @running = false
      @input_reader.stop
      @renderer.stop

      # Disable mouse mode
      @output.write("\e[?1002l\e[?1003l\e[?1006l")

      # Disable bracketed paste
      @output.write("\e[?2004l") if @options.bracketed_paste

      # Disable focus reporting
      @output.write("\e[?1004l") if @options.report_focus

      @renderer.show_cursor
      @renderer.exit_alt_screen if @options.alt_screen

      begin
        @output.flush
      rescue StandardError
        nil
      end
      if @stty_state
        system("stty #{@stty_state}")
        @stty_state = nil
      end

      return unless @options.handle_signals

      %w[SIGWINCH SIGINT SIGTERM SIGTSTP SIGCONT].each do |sig|
        Signal.trap(sig, "DEFAULT")
      rescue ArgumentError
        # Signal unsupported on this platform
      end
    end

    def write_escape(seq)
      @output.write(seq)
      @output.flush
    end

    def deliver_to_model(msg)
      cmd = @model.update(msg)
      run_cmd(cmd) if cmd
    end

    def build_window_size_msg
      if @options.initial_width && @options.initial_height
        WindowSizeMsg.new(width: @options.initial_width, height: @options.initial_height)
      else
        rows, cols = begin
          @output.winsize
        rescue StandardError
          [24, 80]
        end
        WindowSizeMsg.new(width: cols, height: rows)
      end
    end
  end

  # No-op renderer for headless/testing mode.
  class NullRenderer
    attr_reader :width, :height

    def initialize
      @width = 80
      @height = 24
    end

    def enter_alt_screen; end
    def exit_alt_screen; end
    def enter_inline_mode; end
    def hide_cursor; end
    def show_cursor; end

    def resize(w, h)
      @width = w
      @height = h
    end

    def render(_view_string); end
    def force_render(_view_string); end
    def clear; end
    def println(_str); end
    def println_above(_str); end
    def move_cursor(_row, _col); end
    def apply_cursor_shape(_shape); end
    def write_window_title(_title); end
    def stop; end
  end
end
