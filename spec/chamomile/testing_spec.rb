# frozen_string_literal: true

RSpec.describe Chamomile::Testing::Harness do
  let(:counter_class) do
    Class.new do
      include Chamomile::Model
      include Chamomile::Commands

      attr_reader :count

      def initialize
        @count = 0
      end

      def update(msg)
        case msg
        when Chamomile::KeyMsg
          return quit if msg.key == "q"

          @count += 1
        when Chamomile::WindowSizeMsg
          # ignore
        end
        nil
      end

      def view
        "Count: #{@count}"
      end
    end
  end

  describe "#initialize" do
    it "delivers WindowSizeMsg on creation" do
      model = counter_class.new
      harness = described_class.new(model)
      expect(harness.messages.first).to be_a(Chamomile::WindowSizeMsg)
    end

    it "accepts custom dimensions" do
      model = counter_class.new
      harness = described_class.new(model, width: 120, height: 40)
      window_msg = harness.messages.first
      expect(window_msg.width).to eq(120)
      expect(window_msg.height).to eq(40)
    end

    it "runs the model's start command" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        attr_reader :started

        def initialize
          @started = false
        end

        def start
          deliver(Chamomile::TickMsg.new(time: Time.now))
        end

        def update(msg)
          @started = true if msg.is_a?(Chamomile::TickMsg)
          nil
        end

        def view = "test"
      end.new

      described_class.new(model)
      expect(model.started).to be true
    end
  end

  describe "#send_key" do
    it "delivers a KeyMsg to the model" do
      model = counter_class.new
      harness = described_class.new(model)
      harness.send_key("a")
      expect(model.count).to eq(1)
    end

    it "supports modifier keys" do
      received = nil
      model = Class.new do
        include Chamomile::Model
        define_method(:received=) { |v| received = v }

        def update(msg)
          self.received = msg if msg.is_a?(Chamomile::KeyMsg)
          nil
        end

        def view = ""
      end.new

      harness = described_class.new(model)
      harness.send_key("c", mod: [:ctrl])
      expect(received.ctrl?).to be true
    end
  end

  describe "#send_mouse" do
    it "delivers a MouseMsg to the model" do
      received = nil
      model = Class.new do
        include Chamomile::Model
        define_method(:received=) { |v| received = v }

        def update(msg)
          self.received = msg if msg.is_a?(Chamomile::MouseMsg)
          nil
        end

        def view = ""
      end.new

      harness = described_class.new(model)
      harness.send_mouse(x: 10, y: 5)
      expect(received).to be_a(Chamomile::MouseMsg)
      expect(received.x).to eq(10)
      expect(received.y).to eq(5)
    end
  end

  describe "#send_msg" do
    it "delivers any message to the model" do
      model = counter_class.new
      harness = described_class.new(model)
      harness.send_msg(Chamomile::TickMsg.new(time: Time.now))
      # TickMsg doesn't increment count in counter_class
      expect(model.count).to eq(0)
    end
  end

  describe "#resize" do
    it "delivers a WindowSizeMsg with new dimensions" do
      model = counter_class.new
      harness = described_class.new(model)
      harness.resize(120, 40)
      window_msgs = harness.messages.select { |m| m.is_a?(Chamomile::WindowSizeMsg) }
      expect(window_msgs.last.width).to eq(120)
      expect(window_msgs.last.height).to eq(40)
    end
  end

  describe "#view" do
    it "returns the current rendered view" do
      model = counter_class.new
      harness = described_class.new(model)
      expect(harness.view).to eq("Count: 0")
      harness.send_key("a")
      expect(harness.view).to eq("Count: 1")
    end
  end

  describe "#quit?" do
    it "returns false initially" do
      model = counter_class.new
      harness = described_class.new(model)
      expect(harness.quit?).to be false
    end

    it "returns true after quit command" do
      model = counter_class.new
      harness = described_class.new(model)
      harness.send_key("q")
      expect(harness.quit?).to be true
    end
  end

  describe "batch command handling" do
    it "unwraps and executes batch commands synchronously" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        attr_reader :values

        def initialize
          @values = []
        end

        def start
          batch(
            deliver(Chamomile::TickMsg.new(time: Time.now)),
            deliver(Chamomile::TickMsg.new(time: Time.now))
          )
        end

        def update(msg)
          @values << :tick if msg.is_a?(Chamomile::TickMsg)
          nil
        end

        def view = "test"
      end.new

      described_class.new(model)
      expect(model.values.length).to eq(2)
    end
  end

  describe "sequence command handling" do
    it "unwraps and executes sequence commands in order" do
      order = []
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        define_method(:order) { order }

        def start
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
          order << :update if msg.is_a?(Chamomile::TickMsg)
          nil
        end

        def view = "test"
      end.new

      described_class.new(model)
      expect(order).to eq([1, :update, 2, :update])
    end
  end

  describe "#assert_snapshot" do
    it "stores and compares snapshots" do
      model = counter_class.new
      harness = described_class.new(model)
      result = harness.assert_snapshot("initial")
      expect(result).to eq("Count: 0")

      # Same snapshot should pass
      expect { harness.assert_snapshot("initial") }.not_to raise_error
    end

    it "raises on snapshot mismatch" do
      model = counter_class.new
      harness = described_class.new(model)
      harness.assert_snapshot("before")
      harness.send_key("a")
      expect { harness.assert_snapshot("before") }.to raise_error(Chamomile::Testing::SnapshotMismatch)
    end

    it "accepts a normalize block" do
      model = counter_class.new
      harness = described_class.new(model)
      result = harness.assert_snapshot("normalized") { |lines| lines.map(&:strip) }
      expect(result).to eq("Count: 0")
    end
  end

  describe "#messages" do
    it "records all messages delivered to the model" do
      model = counter_class.new
      harness = described_class.new(model)
      harness.send_key("a")
      harness.send_key("b")
      key_msgs = harness.messages.select { |m| m.is_a?(Chamomile::KeyMsg) }
      expect(key_msgs.length).to eq(2)
    end
  end

  describe "#commands_run" do
    it "records all commands executed" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        def start
          deliver(Chamomile::TickMsg.new(time: Time.now))
        end

        def update(_msg) = nil
        def view = ""
      end.new

      harness = described_class.new(model)
      expect(harness.commands_run).not_to be_empty
    end
  end

  describe "runtime command interception" do
    it "intercepts WindowTitleCmd without delivering to model" do
      received = []
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        define_method(:received) { received }

        def update(msg)
          received << msg
          window_title("test title")
        end

        def view = ""
      end.new

      harness = described_class.new(model)
      harness.send_key("a")
      # WindowTitleCmd should NOT appear in received
      expect(received.none? { |m| m.is_a?(Chamomile::WindowTitleCmd) }).to be true
    end

    it "intercepts CursorVisibilityCmd without delivering to model" do
      received = []
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        define_method(:received) { received }

        def update(msg)
          received << msg
          show_cursor
        end

        def view = ""
      end.new

      harness = described_class.new(model)
      harness.send_key("a")
      expect(received.none? { |m| m.is_a?(Chamomile::CursorVisibilityCmd) }).to be true
    end

    it "raises ErrorMsg errors" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        def update(msg)
          return -> { raise "test error" } if msg.is_a?(Chamomile::KeyMsg)

          nil
        end

        def view = ""
      end.new

      harness = described_class.new(model)
      expect { harness.send_key("a") }.to raise_error(RuntimeError, "test error")
    end
  end

  describe "cancel command handling" do
    it "cancels a token via CancelCmd" do
      token = nil
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        define_method(:token=) { |t| token = t }

        def update(msg)
          case msg
          when Chamomile::KeyMsg
            t, _cmd = cancellable { |_t| nil }
            self.token = t
            cancel(t)
          end
        end

        def view = ""
      end.new

      harness = described_class.new(model)
      harness.send_key("c")
      expect(token).to be_a(Chamomile::CancelToken)
      expect(token.cancelled?).to be true
    end
  end
end
