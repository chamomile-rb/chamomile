# frozen_string_literal: true

require "io/console"

module Chamomile
  # Main event loop — wires up Model, Renderer, and InputReader.
  class Program
    def initialize(model, options: nil, **kwargs)
      @options = options || Options.default(**kwargs.compact)

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
      @executor     = Concurrent::ThreadPoolExecutor.new(
        min_threads: 2,
        max_threads: 8,
        max_queue: 64,
        fallback_policy: :caller_runs
      )
      @running      = false
      @torn_down    = false
      @done_mutex   = Mutex.new
      @done_cv      = ConditionVariable.new
      @done         = false
      @stty_state   = nil
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
    rescue ClosedQueueError
      # Program has shut down
    end

    # Quit gracefully — model gets a final QuitEvent
    def quit!
      @msgs.push(QuitEvent.new)
    rescue ClosedQueueError
      # Already shut down
    end

    # Kill immediately — no final message, no cleanup render
    def kill!
      @running = false
      @msgs.push(QuitEvent.new)
    rescue ClosedQueueError
      # Already shut down
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

      # on_start hook takes precedence; fall back to start (backward compat)
      if @model.respond_to?(:on_start, true) && @model.method(:on_start).owner != Chamomile::Model
        start_cmd = @model.send(:on_start)
        run_cmd(start_cmd) if start_cmd
      elsif (start_cmd = @model.start)
        run_cmd(start_cmd)
      end

      @renderer.render(@model.view)

      event_loop

      @model
    ensure
      teardown_terminal
      shutdown_executor
    end

    def event_loop
      while @running
        msg = @msgs.pop
        break if msg.nil? # Queue was closed

        # Apply message filter if configured
        if @options.filter
          msg = @options.filter.call(@model, msg)
          next if msg.nil?
        end

        case msg
        when QuitEvent
          @running = false
          break
        when InterruptEvent
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
        when SuspendEvent
          handle_suspend
          next
        when ResizeEvent
          @renderer.resize(msg.width, msg.height)
          # Fall through -- also deliver to model
        when CancelCommand
          msg.token.cancel!
          next
        when StreamCommand
          dispatch_stream(msg)
          next
        when Array
          if msg[0] == :sequence
            run_sequence(msg[1..])
          else
            msg.each { |c| run_cmd(c) }
          end
          next
        when ErrorEvent
          raise msg.error

        # Renderer commands — intercepted, not delivered to model
        when WindowTitleCommand
          @renderer.write_window_title(msg.title)
          next
        when CursorPositionCommand
          @renderer.move_cursor(msg.row, msg.col)
          next
        when CursorShapeCommand
          @renderer.apply_cursor_shape(msg.shape)
          next
        when CursorVisibilityCommand
          msg.visible ? @renderer.show_cursor : @renderer.hide_cursor
          next
        when ExecCommand
          handle_exec(msg)
          next
        when PrintlnCommand
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
      deliver_to_model(SuspendEvent.new)

      teardown_terminal
      Process.kill("SIGSTOP", Process.pid)

      # After SIGCONT, we resume here
      setup_terminal
      send_msg(build_window_size_msg)

      deliver_to_model(ResumeEvent.new)

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
        rescue ClosedQueueError
          # Program has shut down
        rescue StandardError => e
          begin
            @msgs.push(ErrorEvent.new(error: e)) if @running
          rescue ClosedQueueError
            # discard
          end
        end
      end

      @renderer.force_render(@model.view)
    end

    def run_cmd(cmd)
      return if cmd.nil?

      @executor.post do
        result = cmd.call
        @msgs.push(result) if result && @running
      rescue ClosedQueueError
        # Program has shut down — discard result
      rescue StandardError => e
        begin
          @msgs.push(ErrorEvent.new(error: e)) if @running
        rescue ClosedQueueError
          # discard
        end
      end
    end

    def run_sequence(cmds)
      @executor.post do
        cmds.each do |cmd|
          next if cmd.nil?
          break unless @running

          begin
            result = cmd.call
            @msgs.push(result) if result && @running
          rescue ClosedQueueError
            break
          rescue StandardError => e
            begin
              @msgs.push(ErrorEvent.new(error: e)) if @running
            rescue ClosedQueueError
              # discard
            end
            break
          end
        end
      end
    end

    def running?
      @running
    end

    def dispatch_stream(stream_cmd)
      token = stream_cmd.token
      producer = stream_cmd.producer
      queue = @msgs
      running_ref = method(:running?)
      @executor.post do
        push = ->(m) {
          begin
            queue.push(m) if m && running_ref.call && !token.cancelled?
          rescue ClosedQueueError
            # Program has shut down
          end
        }
        begin
          producer.call(push, token)
        rescue ClosedQueueError
          # Program has shut down
        rescue StandardError => e
          begin
            queue.push(ErrorEvent.new(error: e)) if running_ref.call
          rescue ClosedQueueError
            # discard
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
        Signal.trap("SIGINT") { @msgs.push(InterruptEvent.new) }
        Signal.trap("SIGTERM") { @msgs.push(QuitEvent.new) }
        begin
          Signal.trap("SIGTSTP") do
            @msgs.push(SuspendEvent.new)
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

    # Final shutdown — close the message queue and drain the thread pool.
    # Separate from teardown_terminal because exec/suspend do temporary teardowns.
    def shutdown_executor
      @msgs.close
      @executor.shutdown
      @executor.wait_for_termination(2)
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
        ResizeEvent.new(width: @options.initial_width, height: @options.initial_height)
      else
        rows, cols = begin
          @output.winsize
        rescue StandardError
          [24, 80]
        end
        ResizeEvent.new(width: cols, height: rows)
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
