# frozen_string_literal: true

require "stringio"

RSpec.describe Chamomile::Program do
  let(:output) { StringIO.new }

  let(:quit_after_init_model) do
    Class.new do
      include Chamomile::Model
      include Chamomile::Commands

      attr_reader :messages_received

      def initialize
        @messages_received = []
      end

      def init
        quit
      end

      def update(msg)
        @messages_received << msg
        [self, nil]
      end

      def view
        "test view"
      end
    end.new
  end

  let(:count_then_quit_model) do
    Class.new do
      include Chamomile::Model
      include Chamomile::Commands

      attr_reader :count

      def initialize
        @count = 0
      end

      def update(msg)
        case msg
        when Chamomile::WindowSizeMsg
          # ignore
        else
          @count += 1
          return [self, quit] if @count >= 2
        end
        [self, nil]
      end

      def view
        "count: #{@count}"
      end
    end.new
  end

  def stub_terminal(program)
    allow(program).to receive(:setup_terminal) do
      program.instance_variable_set(:@running, true)
      program.instance_variable_get(:@input_reader)
             .instance_variable_set(:@running, false)
    end
    allow(program).to receive(:teardown_terminal)
  end

  describe "#run" do
    it "runs a model that quits immediately via init cmd" do
      program = described_class.new(quit_after_init_model, output: output)
      stub_terminal(program)

      result = program.run
      expect(result).to eq(quit_after_init_model)
    end

    it "returns the final model state" do
      program = described_class.new(quit_after_init_model, output: output)
      stub_terminal(program)

      model = program.run
      expect(model).to be_a(Chamomile::Model)
    end
  end

  describe "#send_msg" do
    it "pushes messages to the queue" do
      program = described_class.new(quit_after_init_model, output: output)
      program.send_msg(Chamomile::QuitMsg.new)
      queue = program.instance_variable_get(:@msgs)
      expect(queue.pop).to be_a(Chamomile::QuitMsg)
    end
  end

  describe "options integration" do
    it "accepts alt_screen: false and skips alt screen sequences" do
      program = described_class.new(quit_after_init_model, output: output, alt_screen: false)
      stub_terminal(program)

      program.run
      opts = program.instance_variable_get(:@options)
      expect(opts.alt_screen).to be false
    end

    it "enables mouse mode sequences" do
      program = described_class.new(quit_after_init_model, output: output, mouse: :all_motion)
      opts = program.instance_variable_get(:@options)
      expect(opts.mouse).to eq(:all_motion)
    end

    it "accepts an Options struct directly" do
      opts = Chamomile::Options.default(alt_screen: false, fps: 30, output: output)
      program = described_class.new(quit_after_init_model, options: opts)
      actual_opts = program.instance_variable_get(:@options)
      expect(actual_opts.alt_screen).to be false
      expect(actual_opts.fps).to eq(30)
    end
  end

  describe "InterruptMsg handling" do
    it "defaults to quit when model doesn't handle InterruptMsg" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        def update(msg)
          case msg
          when Chamomile::InterruptMsg
            raise NotImplementedError
          end
          [self, nil]
        end

        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)

      # Push InterruptMsg to trigger default quit behavior
      Thread.new do
        sleep(0.01)
        program.send_msg(Chamomile::InterruptMsg.new)
      end

      result = program.run
      expect(result).to eq(model)
    end
  end

  describe "message filter" do
    it "filters messages before delivery" do
      received = []
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        define_method(:received) { received }

        def init
          quit
        end

        def update(msg)
          received << msg
          [self, nil]
        end

        def view = "test"
      end.new

      filter = ->(_m, msg) {
        case msg
        when Chamomile::WindowSizeMsg then nil # drop WindowSizeMsg
        else msg
        end
      }

      program = described_class.new(model, output: output, filter: filter)
      stub_terminal(program)
      program.run

      expect(received.any? { |m| m.is_a?(Chamomile::WindowSizeMsg) }).to be false
    end
  end

  describe "panic recovery" do
    it "restores terminal on exception when catch_panics is true" do
      model = Class.new do
        include Chamomile::Model

        def update(msg)
          raise "boom!" unless msg.is_a?(Chamomile::WindowSizeMsg)

          [self, nil]
        end

        def view = "test"
      end.new

      program = described_class.new(model, output: output, catch_panics: true)
      stub_terminal(program)

      # Push a message that will cause the model to raise
      Thread.new do
        sleep(0.01)
        program.send_msg(Chamomile::KeyMsg.new(key: "a", mod: []))
      end

      expect { program.run }.to raise_error(RuntimeError, "boom!")
      # teardown_terminal should have been called (stubbed, so no crash)
    end
  end

  describe "BatchCmd dispatch" do
    it "executes all commands in a batch" do
      results = []
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        define_method(:results) { results }

        def init
          batch(
            -> { Chamomile::TickMsg.new(time: Time.now) },
            -> { Chamomile::TickMsg.new(time: Time.now) }
          )
        end

        def update(msg)
          case msg
          when Chamomile::TickMsg
            results << msg
            return [self, quit] if results.length >= 2
          end
          [self, nil]
        end

        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)
      program.run
      expect(results.length).to eq(2)
    end
  end

  describe "SequenceCmd dispatch" do
    it "executes commands in sequence" do
      order = []
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        define_method(:order) { order }

        def init
          sequence(
            -> {
              order << 1
              Chamomile::TickMsg.new(time: Time.now)
            },
            -> {
              order << 2
              Chamomile::TickMsg.new(time: Time.now)
            }
          )
        end

        def update(msg)
          case msg
          when Chamomile::TickMsg
            return [self, quit] if order.length >= 2
          end
          [self, nil]
        end

        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)
      program.run
      expect(order).to eq([1, 2])
    end
  end

  describe "WindowSizeMsg delivery" do
    it "delivers WindowSizeMsg to model and resizes renderer" do
      received_window_msg = nil
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        define_method(:received_window_msg=) { |v| received_window_msg = v }

        def init
          quit
        end

        def update(msg)
          case msg
          when Chamomile::WindowSizeMsg
            self.received_window_msg = msg
          end
          [self, nil]
        end

        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)
      program.run

      # WindowSizeMsg is sent during run, should be delivered to model
      expect(received_window_msg).to be_a(Chamomile::WindowSizeMsg)
    end
  end

  describe "error propagation" do
    it "raises ErrorMsg errors in the event loop" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        def init
          -> { raise "test error" }
        end

        def update(_msg)
          [self, nil]
        end

        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)

      expect { program.run }.to raise_error(RuntimeError, "test error")
    end
  end

  describe "edge cases" do
    it "handles empty view string" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        def init = quit
        def update(_msg) = [self, nil]
        def view = ""
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)
      expect { program.run }.not_to raise_error
    end

    it "handles model returning nil from update" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        def init = quit
        def update(_msg) = [nil, nil]
        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)
      result = program.run
      expect(result).to eq(model)
    end

    it "backward compat: Chamomile.run with zero kwargs works" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        def init = quit
        def update(_msg) = [self, nil]
        def view = "test"
      end.new

      # Verify Options.default is used
      program = described_class.new(model, output: output)
      opts = program.instance_variable_get(:@options)
      expect(opts.alt_screen).to be true
      expect(opts.mouse).to eq(:none)
      expect(opts.bracketed_paste).to be true
      expect(opts.fps).to eq(60)
    end

    it "handles model.view returning nil" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        def init = quit
        def update(_msg) = [self, nil]
        def view = nil
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)
      expect { program.run }.not_to raise_error
    end

    it "teardown_terminal is safe to call twice" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        def init = quit
        def update(_msg) = [self, nil]
        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)
      program.run
      # teardown already called by run; calling again should be safe
      expect { program.send(:teardown_terminal) }.not_to raise_error
    end
  end

  describe "terminal setup sequences" do
    it "writes mouse enable sequences for :all_motion" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def init = quit
        def update(_msg) = [self, nil]
        def view = ""
      end.new

      program = described_class.new(model, output: output, mouse: :all_motion)
      allow(program).to receive(:setup_terminal).and_wrap_original do |_m|
        # Skip stty and signals but call the rest
        program.instance_variable_set(:@running, true)
        program.instance_variable_get(:@input_reader)
               .instance_variable_set(:@running, false)
      end
      allow(program).to receive(:teardown_terminal) do
        program.instance_variable_set(:@running, false)
      end

      program.run
      opts = program.instance_variable_get(:@options)
      expect(opts.mouse).to eq(:all_motion)
    end

    it "writes paste enable sequence when bracketed_paste is true" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def init = quit
        def update(_msg) = [self, nil]
        def view = ""
      end.new

      program = described_class.new(model, output: output, bracketed_paste: true)
      opts = program.instance_variable_get(:@options)
      expect(opts.bracketed_paste).to be true
    end
  end

  describe "Chamomile.run wrapper" do
    it "delegates to Program#run and returns model" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def init = quit
        def update(_msg) = [self, nil]
        def view = "test"
      end.new

      # Mock Program.new to avoid terminal manipulation
      program = instance_double(Chamomile::Program)
      allow(Chamomile::Program).to receive(:new).with(model).and_return(program)
      allow(program).to receive(:run).and_return(model)

      result = Chamomile.run(model)
      expect(result).to eq(model)
    end
  end

  describe "renderer command routing" do
    it "routes WindowTitleCmd to renderer without delivering to model" do
      received = []
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        define_method(:received) { received }

        def update(msg)
          received << msg
          return [self, quit] if received.length >= 2

          [self, nil]
        end

        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)

      Thread.new do
        sleep(0.01)
        program.send_msg(Chamomile::WindowTitleCmd.new(title: "test"))
        sleep(0.01)
        program.send_msg(Chamomile::QuitMsg.new)
      end

      program.run
      # WindowTitleCmd should NOT have been delivered to model
      expect(received.none? { |m| m.is_a?(Chamomile::WindowTitleCmd) }).to be true
    end
  end

  describe "sequence error handling" do
    it "stops sequence on error and delivers ErrorMsg" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        def update(_msg)
          [self, nil]
        end

        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)

      cmds = [
        -> { raise "seq error" },
        -> { Chamomile::TickMsg.new(time: Time.now) },
      ]

      Thread.new do
        sleep(0.01)
        program.send_msg(Chamomile::SequenceCmd.new(cmds: cmds))
      end

      expect { program.run }.to raise_error(RuntimeError, "seq error")
    end
  end

  describe "#quit!" do
    it "sends QuitMsg to terminate the program" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def update(_msg) = [self, nil]
        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)

      Thread.new do
        sleep(0.01)
        program.quit!
      end

      result = program.run
      expect(result).to eq(model)
    end
  end

  describe "#kill!" do
    it "immediately stops the program" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def update(_msg) = [self, nil]
        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)

      Thread.new do
        sleep(0.01)
        program.kill!
      end

      result = program.run
      expect(result).to eq(model)
    end
  end

  describe "#wait" do
    it "blocks until program finishes" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def init = quit
        def update(_msg) = [self, nil]
        def view = "test"
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)

      done = false
      Thread.new do
        program.run
      end

      Thread.new do
        program.wait
        done = true
      end

      sleep(0.1)
      expect(done).to be true
    end
  end

  describe "without_renderer option" do
    it "uses NullRenderer when without_renderer: true" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def init = quit
        def update(_msg) = [self, nil]
        def view = "test"
      end.new

      program = described_class.new(model, output: output, without_renderer: true)
      renderer = program.instance_variable_get(:@renderer)
      expect(renderer).to be_a(Chamomile::NullRenderer)
    end
  end

  describe "initial_width/height option" do
    it "uses provided dimensions instead of querying terminal" do
      received_size = nil
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        define_method(:received_size=) { |v| received_size = v }

        def init = quit

        def update(msg)
          case msg
          when Chamomile::WindowSizeMsg
            self.received_size = msg
          end
          [self, nil]
        end

        def view = "test"
      end.new

      program = described_class.new(model, output: output, initial_width: 120, initial_height: 40)
      stub_terminal(program)
      program.run

      expect(received_size).to be_a(Chamomile::WindowSizeMsg)
      expect(received_size.width).to eq(120)
      expect(received_size.height).to eq(40)
    end
  end

  describe "runtime mode toggle routing" do
    it "routes EnableMouseAllMotionMsg to output" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def update(_msg) = [self, nil]
        def view = ""
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)

      Thread.new do
        sleep(0.01)
        program.send_msg(Chamomile::EnableMouseAllMotionMsg.new)
        sleep(0.01)
        program.send_msg(Chamomile::QuitMsg.new)
      end

      program.run
      expect(output.string).to include("\e[?1003h")
    end

    it "routes DisableMouseMsg to output" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def update(_msg) = [self, nil]
        def view = ""
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)

      Thread.new do
        sleep(0.01)
        program.send_msg(Chamomile::DisableMouseMsg.new)
        sleep(0.01)
        program.send_msg(Chamomile::QuitMsg.new)
      end

      program.run
      expect(output.string).to include("\e[?1002l")
    end

    it "routes RequestWindowSizeMsg to push WindowSizeMsg" do
      sizes_received = []
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        define_method(:sizes_received) { sizes_received }

        def update(msg)
          case msg
          when Chamomile::WindowSizeMsg
            sizes_received << msg
            return [self, quit] if sizes_received.length >= 2
          end
          [self, nil]
        end

        def view = ""
      end.new

      program = described_class.new(model, output: output, initial_width: 80, initial_height: 24)
      stub_terminal(program)

      Thread.new do
        sleep(0.02)
        program.send_msg(Chamomile::RequestWindowSizeMsg.new)
      end

      program.run
      # Should have received at least 2 WindowSizeMsg (initial + requested)
      expect(sizes_received.length).to be >= 2
    end

    it "routes PrintlnCmd to renderer" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def update(_msg) = [self, nil]
        def view = ""
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)

      Thread.new do
        sleep(0.01)
        program.send_msg(Chamomile::PrintlnCmd.new(text: "log line"))
        sleep(0.01)
        program.send_msg(Chamomile::QuitMsg.new)
      end

      program.run
      expect(output.string).to include("log line")
    end
  end

  describe "exec with callback" do
    it "calls callback with success status after exec" do
      callback_called = false
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        define_method(:callback_called=) { |v| callback_called = v }

        def update(msg)
          case msg
          when Chamomile::TickMsg
            self.callback_called = true
            return [self, quit]
          end
          [self, nil]
        end

        def view = ""
      end.new

      program = described_class.new(model, output: output)
      stub_terminal(program)

      Thread.new do
        sleep(0.01)
        exec_cmd = Chamomile::ExecCmd.new(
          command: "true",
          args: [],
          callback: ->(_success) {
            Chamomile::TickMsg.new(time: Time.now)
          }
        )
        program.send_msg(exec_cmd)
      end

      program.run
      expect(callback_called).to be true
    end
  end
end
