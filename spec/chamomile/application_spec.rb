# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chamomile::Application do
  describe "on_key DSL" do
    it "registers and fires handler for a single key" do
      klass = Class.new do
        include Chamomile::Application
        def initialize = @hit = false
        on_key("a") { @hit = true }
        def view = @hit ? "hit" : "miss"
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_key("a")
      expect(harness.view).to eq("hit")
    end

    it "registers handler for multiple keys in one call" do
      klass = Class.new do
        include Chamomile::Application
        def initialize = @count = 0
        on_key(:up, "k") { @count += 1 }
        def view = @count.to_s
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_key(:up)
      harness.send_key("k")
      expect(harness.view).to eq("2")
    end

    it "block has access to instance variables" do
      klass = Class.new do
        include Chamomile::Application
        def initialize = @name = "world"
        on_key("g") { @name = "ruby" }
        def view = "hello #{@name}"
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_key("g")
      expect(harness.view).to eq("hello ruby")
    end

    it "can call quit from handler" do
      klass = Class.new do
        include Chamomile::Application
        on_key("q") { quit }
        def view = "alive"
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_key("q")
      expect(harness.quit?).to be true
    end

    it "does not fire handler for unregistered keys" do
      klass = Class.new do
        include Chamomile::Application
        def initialize = @hit = false
        on_key("a") { @hit = true }
        def view = @hit ? "hit" : "miss"
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_key("b")
      expect(harness.view).to eq("miss")
    end
  end

  describe "on_resize DSL" do
    it "receives event with width and height" do
      klass = Class.new do
        include Chamomile::Application
        def initialize
          @w = 0
          @h = 0
        end
        on_resize do |e|
          @w = e.width
          @h = e.height
        end
        def view = "#{@w}x#{@h}"
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      # Initial resize from harness setup
      expect(harness.view).to eq("80x24")
      harness.resize(120, 40)
      expect(harness.view).to eq("120x40")
    end
  end

  describe "on_tick DSL" do
    it "fires on tick events" do
      klass = Class.new do
        include Chamomile::Application
        def initialize = @ticks = 0
        on_tick { @ticks += 1 }
        def view = @ticks.to_s
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_msg(Chamomile::TickEvent.new(time: Time.now))
      expect(harness.view).to eq("1")
    end
  end

  describe "on_mouse DSL" do
    it "receives mouse event" do
      klass = Class.new do
        include Chamomile::Application
        def initialize = @clicked = false
        on_mouse { |e| @clicked = true if e.press? }
        def view = @clicked ? "clicked" : "waiting"
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_mouse(x: 5, y: 5, button: :left, action: :press)
      expect(harness.view).to eq("clicked")
    end
  end

  describe "on_focus / on_blur DSL" do
    it "fires on focus and blur events" do
      klass = Class.new do
        include Chamomile::Application
        def initialize = @focused = false
        on_focus { @focused = true }
        on_blur { @focused = false }
        def view = @focused ? "focused" : "blurred"
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_msg(Chamomile::FocusEvent.new)
      expect(harness.view).to eq("focused")
      harness.send_msg(Chamomile::BlurEvent.new)
      expect(harness.view).to eq("blurred")
    end
  end

  describe "on_paste DSL" do
    it "receives paste content" do
      klass = Class.new do
        include Chamomile::Application
        def initialize = @pasted = ""
        on_paste { |e| @pasted = e.content }
        def view = @pasted
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_msg(Chamomile::PasteEvent.new(content: "hello world"))
      expect(harness.view).to eq("hello world")
    end
  end

  describe "manually defined update takes precedence" do
    it "ignores DSL handlers when update is defined" do
      klass = Class.new do
        include Chamomile::Application
        def initialize = @source = "none"
        on_key("a") { @source = "dsl" }

        def update(msg)
          @source = "manual" if msg.is_a?(Chamomile::KeyEvent)
          nil
        end

        def view = @source
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      harness.send_key("a")
      expect(harness.view).to eq("manual")
    end
  end

  describe "inherited handlers from parent class" do
    it "subclass inherits parent handlers" do
      parent = Class.new do
        include Chamomile::Application
        def initialize = @count = 0
        on_key("a") { @count += 1 }
        def view = @count.to_s
      end

      child = Class.new(parent)

      harness = Chamomile::Testing::Harness.new(child.new)
      harness.send_key("a")
      expect(harness.view).to eq("1")
    end
  end

  describe "include Chamomile::Application gives all functionality" do
    it "provides quit, tick, and other command helpers" do
      klass = Class.new do
        include Chamomile::Application

        def initialize = @started = false

        def on_start
          deliver(Chamomile::TickEvent.new(time: Time.now))
        end

        on_tick { @started = true }

        def view = @started ? "started" : "waiting"
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      expect(harness.view).to eq("started")
    end
  end

  describe "on_start hook" do
    it "fires on program start" do
      klass = Class.new do
        include Chamomile::Application
        def initialize = @started = false

        def on_start
          deliver(Chamomile::TickEvent.new(time: Time.now))
        end

        on_tick { @started = true }
        def view = @started ? "started" : "waiting"
      end

      harness = Chamomile::Testing::Harness.new(klass.new)
      expect(harness.view).to eq("started")
    end
  end

  describe "parallel and serial aliases" do
    it "parallel is an alias for batch" do
      cmd1 = -> { :a }
      cmd2 = -> { :b }
      result = Chamomile::Commands.parallel(cmd1, cmd2)
      expect(result.call).to eq([cmd1, cmd2])
    end

    it "serial is an alias for sequence" do
      cmd1 = -> { :a }
      cmd2 = -> { :b }
      result = Chamomile::Commands.serial(cmd1, cmd2)
      expect(result.call[0]).to eq(:sequence)
    end
  end

  describe "new event type names" do
    it "KeyEvent is the primary name" do
      event = Chamomile::KeyEvent.new(key: "a", mod: [])
      expect(event).to be_a(Chamomile::KeyEvent)
      expect(event).to be_a(Chamomile::KeyMsg) # backward compat
    end

    it "ResizeEvent is the primary name" do
      event = Chamomile::ResizeEvent.new(width: 80, height: 24)
      expect(event).to be_a(Chamomile::ResizeEvent)
      expect(event).to be_a(Chamomile::WindowSizeMsg) # backward compat
    end
  end

  describe "Frame.build view DSL" do
    it "returns a Frame" do
      frame = Chamomile::Frame.build do |f|
        f.text("hello")
      end
      expect(frame).to be_a(Chamomile::Frame)
    end

    it "frame.render returns a string" do
      frame = Chamomile::Frame.build do |f|
        f.text("hello world")
      end
      result = frame.render(width: 80, height: 24)
      expect(result).to be_a(String)
      expect(result).to include("hello world")
    end

    it "Panel widget renders border and title" do
      frame = Chamomile::Frame.build do |f|
        f.panel("Title") do |p|
          p.text("content")
        end
      end
      result = frame.render(width: 40, height: 10)
      expect(result).to include("Title")
      expect(result).to include("content")
    end

    it "backward compat: view returning a String still works with renderer" do
      renderer = Chamomile::Renderer.new(output: StringIO.new, fps: 0)
      renderer.render("plain string")
      # No error raised
    end
  end
end
