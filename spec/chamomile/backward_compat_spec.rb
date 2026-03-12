# frozen_string_literal: true

require "spec_helper"

RSpec.describe "backward compatibility" do
  describe "include Chamomile::Model still works" do
    let(:klass) do
      Class.new do
        include Chamomile::Model
        include Chamomile::Commands

        def initialize
          @count = 0
        end

        def update(msg)
          case msg
          when Chamomile::KeyMsg
            @count += 1 if msg.key == "a"
            return quit if msg.key == "q"
          end
          nil
        end

        def view
          "count: #{@count}"
        end
      end
    end

    it "works with the old Model + Commands includes" do
      model = klass.new
      harness = Chamomile::Testing::Harness.new(model)
      harness.send_key("a")
      expect(harness.view).to include("count: 1")
    end
  end

  describe "def update(msg) case switch still works" do
    let(:klass) do
      Class.new do
        include Chamomile::Application

        def initialize
          @handled = false
        end

        def update(msg)
          @handled = true if msg.is_a?(Chamomile::KeyEvent)
          nil
        end

        def view
          @handled ? "handled" : "not handled"
        end
      end
    end

    it "manually defined update takes precedence over DSL" do
      model = klass.new
      harness = Chamomile::Testing::Harness.new(model)
      harness.send_key("x")
      expect(harness.view).to eq("handled")
    end
  end

  describe "def start returning a command still works" do
    let(:klass) do
      Class.new do
        include Chamomile::Model
        include Chamomile::Commands

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

        def view
          @started ? "started" : "waiting"
        end
      end
    end

    it "start still triggers commands on startup" do
      model = klass.new
      harness = Chamomile::Testing::Harness.new(model)
      expect(harness.view).to eq("started")
    end
  end

  describe "view returning a String still works" do
    it "renders string output" do
      klass = Class.new do
        include Chamomile::Application

        def view
          "hello world"
        end
      end
      model = klass.new
      harness = Chamomile::Testing::Harness.new(model)
      expect(harness.view).to eq("hello world")
    end
  end

  describe "old message names still work as aliases" do
    it "KeyMsg is the same as KeyEvent" do
      expect(Chamomile::KeyMsg).to eq(Chamomile::KeyEvent)
    end

    it "MouseMsg is the same as MouseEvent" do
      expect(Chamomile::MouseMsg).to eq(Chamomile::MouseEvent)
    end

    it "WindowSizeMsg is the same as ResizeEvent" do
      expect(Chamomile::WindowSizeMsg).to eq(Chamomile::ResizeEvent)
    end

    it "QuitMsg is the same as QuitEvent" do
      expect(Chamomile::QuitMsg).to eq(Chamomile::QuitEvent)
    end

    it "TickMsg is the same as TickEvent" do
      expect(Chamomile::TickMsg).to eq(Chamomile::TickEvent)
    end

    it "FocusMsg is the same as FocusEvent" do
      expect(Chamomile::FocusMsg).to eq(Chamomile::FocusEvent)
    end

    it "BlurMsg is the same as BlurEvent" do
      expect(Chamomile::BlurMsg).to eq(Chamomile::BlurEvent)
    end

    it "PasteMsg is the same as PasteEvent" do
      expect(Chamomile::PasteMsg).to eq(Chamomile::PasteEvent)
    end

    it "InterruptMsg is the same as InterruptEvent" do
      expect(Chamomile::InterruptMsg).to eq(Chamomile::InterruptEvent)
    end

    it "ErrorMsg is the same as ErrorEvent" do
      expect(Chamomile::ErrorMsg).to eq(Chamomile::ErrorEvent)
    end
  end

  describe "old command type names still work as aliases" do
    it "ExecCmd is the same as ExecCommand" do
      expect(Chamomile::ExecCmd).to eq(Chamomile::ExecCommand)
    end

    it "CancelCmd is the same as CancelCommand" do
      expect(Chamomile::CancelCmd).to eq(Chamomile::CancelCommand)
    end

    it "StreamCmd is the same as StreamCommand" do
      expect(Chamomile::StreamCmd).to eq(Chamomile::StreamCommand)
    end
  end

  describe "batch() and sequence() still work" do
    it "batch returns a command that produces an array" do
      cmd1 = -> { :result1 }
      cmd2 = -> { :result2 }
      batched = Chamomile::Commands.batch(cmd1, cmd2)
      expect(batched.call).to eq([cmd1, cmd2])
    end

    it "sequence returns a command with :sequence marker" do
      cmd1 = -> { :result1 }
      cmd2 = -> { :result2 }
      sequenced = Chamomile::Commands.sequence(cmd1, cmd2)
      result = sequenced.call
      expect(result[0]).to eq(:sequence)
    end
  end
end
