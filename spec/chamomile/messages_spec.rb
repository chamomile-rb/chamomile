# frozen_string_literal: true

RSpec.describe "Chamomile messages" do
  describe Chamomile::QuitMsg do
    it "is a Data.define value type" do
      msg = Chamomile::QuitMsg.new
      expect(msg).to be_a(Chamomile::QuitMsg)
      expect(msg).to eq(Chamomile::QuitMsg.new)
    end
  end

  describe Chamomile::WindowSizeMsg do
    it "stores width and height" do
      msg = Chamomile::WindowSizeMsg.new(width: 120, height: 40)
      expect(msg.width).to eq(120)
      expect(msg.height).to eq(40)
    end

    it "is immutable" do
      msg = Chamomile::WindowSizeMsg.new(width: 80, height: 24)
      expect(msg).to be_frozen
    end
  end

  describe Chamomile::KeyMsg do
    it "stores key and mod" do
      msg = Chamomile::KeyMsg.new(key: "a", mod: [])
      expect(msg.key).to eq("a")
      expect(msg.mod).to eq([])
    end

    it "detects ctrl modifier" do
      msg = Chamomile::KeyMsg.new(key: "c", mod: [:ctrl])
      expect(msg.ctrl?).to be true
      expect(msg.shift?).to be false
      expect(msg.alt?).to be false
    end

    it "detects shift modifier" do
      msg = Chamomile::KeyMsg.new(key: "A", mod: [:shift])
      expect(msg.shift?).to be true
    end

    it "detects alt modifier" do
      msg = Chamomile::KeyMsg.new(key: "x", mod: [:alt])
      expect(msg.alt?).to be true
    end

    it "formats to_s without modifiers" do
      msg = Chamomile::KeyMsg.new(key: "q", mod: [])
      expect(msg.to_s).to eq("q")
    end

    it "formats to_s with modifiers" do
      msg = Chamomile::KeyMsg.new(key: "c", mod: %i[ctrl shift])
      expect(msg.to_s).to eq("ctrl+shift+c")
    end
  end

  describe Chamomile::FocusMsg do
    it "is a Data.define value type" do
      expect(Chamomile::FocusMsg.new).to eq(Chamomile::FocusMsg.new)
    end
  end

  describe Chamomile::BlurMsg do
    it "is a Data.define value type" do
      expect(Chamomile::BlurMsg.new).to eq(Chamomile::BlurMsg.new)
    end
  end

  describe Chamomile::MouseMsg do
    it "stores position and button info" do
      msg = Chamomile::MouseMsg.new(x: 10, y: 5, button: :left, action: :press, mod: [])
      expect(msg.x).to eq(10)
      expect(msg.y).to eq(5)
      expect(msg.button).to eq(:left)
      expect(msg.action).to eq(:press)
    end

    it "detects press action" do
      msg = Chamomile::MouseMsg.new(x: 0, y: 0, button: :left, action: :press, mod: [])
      expect(msg.press?).to be true
      expect(msg.release?).to be false
      expect(msg.motion?).to be false
    end

    it "detects release action" do
      msg = Chamomile::MouseMsg.new(x: 0, y: 0, button: :left, action: :release, mod: [])
      expect(msg.release?).to be true
    end

    it "detects motion action" do
      msg = Chamomile::MouseMsg.new(x: 0, y: 0, button: :none, action: :motion, mod: [])
      expect(msg.motion?).to be true
    end

    it "detects wheel events" do
      msg = Chamomile::MouseMsg.new(x: 0, y: 0, button: :wheel_up, action: :press, mod: [])
      expect(msg.wheel?).to be true
    end

    it "detects modifiers" do
      msg = Chamomile::MouseMsg.new(x: 0, y: 0, button: :left, action: :press, mod: %i[ctrl shift])
      expect(msg.ctrl?).to be true
      expect(msg.shift?).to be true
      expect(msg.alt?).to be false
    end
  end

  describe Chamomile::PasteMsg do
    it "stores pasted content" do
      msg = Chamomile::PasteMsg.new(content: "hello world")
      expect(msg.content).to eq("hello world")
    end
  end

  describe Chamomile::InterruptMsg do
    it "is a Data.define value type" do
      expect(Chamomile::InterruptMsg.new).to eq(Chamomile::InterruptMsg.new)
    end
  end

  describe Chamomile::SuspendMsg do
    it "is a Data.define value type" do
      expect(Chamomile::SuspendMsg.new).to eq(Chamomile::SuspendMsg.new)
    end
  end

  describe Chamomile::ResumeMsg do
    it "is a Data.define value type" do
      expect(Chamomile::ResumeMsg.new).to eq(Chamomile::ResumeMsg.new)
    end
  end

  describe Chamomile::ErrorMsg do
    it "wraps an error" do
      err = RuntimeError.new("boom")
      msg = Chamomile::ErrorMsg.new(error: err)
      expect(msg.error).to eq(err)
      expect(msg.error.message).to eq("boom")
    end
  end

  describe Chamomile::TickMsg do
    it "stores a time" do
      t = Time.now
      msg = Chamomile::TickMsg.new(time: t)
      expect(msg.time).to eq(t)
    end
  end
end
