require "io/console"

module Chamomile
  class Program
    def initialize(model, output: $stdout, input: $stdin)
      @model        = model
      @output       = output
      @input        = input
      @msgs         = Queue.new
      @renderer     = Renderer.new(output: output)
      @input_reader = InputReader.new(@msgs)
      @running      = false
    end

    def run
      @running = true
      setup_terminal

      send_msg(build_window_size_msg)

      if (init_cmd = @model.init)
        run_cmd(init_cmd)
      end

      @renderer.render(@model.view)

      event_loop

      @model
    ensure
      teardown_terminal
    end

    def send_msg(msg)
      @msgs.push(msg)
    end

    private

    def event_loop
      while @running
        msg = @msgs.pop

        case msg
        when QuitMsg
          @running = false
          break
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
        end

        next_model, cmd = @model.update(msg)
        @model = next_model if next_model

        run_cmd(cmd) if cmd

        @renderer.render(@model.view)
      end
    end

    def run_cmd(cmd)
      return if cmd.nil?
      Thread.new do
        begin
          result = cmd.call
          @msgs.push(result) if result && @running
        rescue => e
          @msgs.push(ErrorMsg.new(error: e)) if @running
        end
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
          rescue => e
            @msgs.push(ErrorMsg.new(error: e)) if @running
            break
          end
        end
      end
    end

    def setup_terminal
      @old_tty_state = `stty -g`.chomp rescue nil
      system("stty raw -echo -isig") rescue nil
      @renderer.enter_alt_screen
      @renderer.hide_cursor
      @renderer.clear

      Signal.trap("SIGWINCH") do
        @msgs.push(build_window_size_msg)
      end
      Signal.trap("SIGINT") do
        @msgs.push(QuitMsg.new)
      end
      Signal.trap("SIGTERM") do
        @msgs.push(QuitMsg.new)
      end

      @input_reader.start
    end

    def teardown_terminal
      @running = false
      @input_reader.stop
      @renderer.show_cursor
      @renderer.exit_alt_screen
      system("stty #{@old_tty_state}") if @old_tty_state
      Signal.trap("SIGWINCH", "DEFAULT") rescue nil
      Signal.trap("SIGINT",   "DEFAULT") rescue nil
      Signal.trap("SIGTERM",  "DEFAULT") rescue nil
    end

    def build_window_size_msg
      rows, cols = @output.winsize rescue [24, 80]
      WindowSizeMsg.new(width: cols, height: rows)
    end
  end
end
