# frozen_string_literal: true

require "spec_helper"

RSpec.describe "edge cases" do
  describe "on_key handler return value semantics" do
    it "quit works when it is the last expression" do
      klass = Class.new do
        include Chamomile::Application

        def initialize = @cleaned = false
        on_key("q") do
          @cleaned = true
          quit
        end
        def view = @cleaned ? "cleaned" : "not cleaned"
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_key("q")
      expect(harness.quit?).to be true
      expect(harness.view).to eq("cleaned")
    end

    it "non-callable return values are ignored (no crash)" do
      klass = Class.new do
        include Chamomile::Application

        def initialize = @count = 0
        on_key("a") { @count += 1 } # returns Integer, not a command
        def view = @count.to_s
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_key("a")
      expect(harness.view).to eq("1") # no crash, state updated
    end

    it "tick command works when returned from handler" do
      klass = Class.new do
        include Chamomile::Application

        def initialize = @ticks = 0
        on_key("t") { tick(0.001) }
        on_tick { @ticks += 1 }
        def view = @ticks.to_s
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_key("t")
      # tick command was returned and executed
      expect(harness.view).to eq("1")
    end
  end

  describe "on_key with no handlers and no update" do
    it "returns nil (no crash)" do
      klass = Class.new do
        include Chamomile::Application

        def view = "empty"
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_key("x")
      expect(harness.view).to eq("empty")
    end
  end

  describe "handler exception propagation" do
    it "exceptions in handlers propagate to caller" do
      klass = Class.new do
        include Chamomile::Application

        on_key("x") { raise "boom" }
        def view = ""
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      expect { harness.send_key("x") }.to raise_error(RuntimeError, "boom")
    end
  end

  describe "on_start with private method" do
    it "works when on_start is private" do
      klass = Class.new do
        include Chamomile::Application

        def initialize = @started = false
        on_tick { @started = true }
        def view = @started ? "started" : "waiting"

        private

        def on_start
          deliver(Chamomile::TickEvent.new(time: Time.now))
        end
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      expect(harness.view).to eq("started")
    end
  end

  describe "KeyEvent methods work through alias" do
    it "ctrl? works on KeyMsg alias" do
      event = Chamomile::KeyMsg.new(key: "c", mod: [:ctrl])
      expect(event.ctrl?).to be true
      expect(event.to_s).to eq("ctrl+c")
    end

    it "MouseEvent methods work through alias" do
      event = Chamomile::MouseMsg.new(x: 5, y: 10, button: :left, action: :press, mod: [])
      expect(event.press?).to be true
      expect(event.wheel?).to be false
    end
  end

  describe "multiple on_key for same key" do
    it "last registration wins" do
      klass = Class.new do
        include Chamomile::Application

        def initialize = @value = "none"
        on_key("a") { @value = "first" }
        on_key("a") { @value = "second" }
        def view = @value
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_key("a")
      expect(harness.view).to eq("second")
    end
  end

  describe "renderer handles nil view" do
    it "renders empty string for nil" do
      renderer = Chamomile::Renderer.new(output: StringIO.new, fps: 0)
      # Should not crash
      renderer.render(nil)
    end
  end

  describe "Frame with NullRenderer" do
    it "NullRenderer accepts Frame without crash" do
      renderer = Chamomile::NullRenderer.new
      frame = Chamomile::Frame.build { |f| f.text("hello") }
      # NullRenderer discards, should not crash
      renderer.render(frame)
    end
  end
end
