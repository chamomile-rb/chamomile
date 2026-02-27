# frozen_string_literal: true

RSpec.describe "Mouse, Paste, and Focus integration" do
  let(:parser) { Chamomile::EscapeParser.new }

  def parse(bytes)
    msgs = []
    parser.feed(bytes) { |msg| msgs << msg }
    msgs
  end

  describe "SGR mouse through parser to MouseMsg" do
    it "delivers left click as MouseMsg" do
      msgs = parse("\e[<0;42;13M")
      expect(msgs.length).to eq(1)
      msg = msgs[0]
      expect(msg).to be_a(Chamomile::MouseMsg)
      expect(msg.x).to eq(42)
      expect(msg.y).to eq(13)
      expect(msg.button).to eq(:left)
      expect(msg.press?).to be true
    end

    it "delivers right click release" do
      msgs = parse("\e[<2;10;5m")
      msg = msgs[0]
      expect(msg.button).to eq(:right)
      expect(msg.release?).to be true
    end

    it "delivers wheel events" do
      msgs = parse("\e[<64;10;5M")
      msg = msgs[0]
      expect(msg.wheel?).to be true
      expect(msg.button).to eq(:wheel_up)
    end

    it "delivers motion events" do
      msgs = parse("\e[<35;20;10M")
      msg = msgs[0]
      expect(msg.motion?).to be true
    end

    it "delivers mouse with modifiers" do
      msgs = parse("\e[<4;10;5M") # shift+left click
      msg = msgs[0]
      expect(msg.shift?).to be true
      expect(msg.button).to eq(:left)
    end
  end

  describe "bracketed paste through parser to PasteMsg" do
    it "delivers pasted text" do
      msgs = parse("\e[200~Hello, world!\e[201~")
      expect(msgs.length).to eq(1)
      msg = msgs[0]
      expect(msg).to be_a(Chamomile::PasteMsg)
      expect(msg.content).to eq("Hello, world!")
    end

    it "preserves newlines in paste" do
      msgs = parse("\e[200~line1\nline2\e[201~")
      expect(msgs[0].content).to eq("line1\nline2")
    end

    it "handles paste followed by keypress" do
      msgs = parse("\e[200~pasted\e[201~q")
      expect(msgs.length).to eq(2)
      expect(msgs[0]).to be_a(Chamomile::PasteMsg)
      expect(msgs[0].content).to eq("pasted")
      expect(msgs[1]).to be_a(Chamomile::KeyMsg)
      expect(msgs[1].key).to eq("q")
    end
  end

  describe "focus/blur events" do
    it "delivers FocusMsg" do
      msgs = parse("\e[I")
      expect(msgs[0]).to be_a(Chamomile::FocusMsg)
    end

    it "delivers BlurMsg" do
      msgs = parse("\e[O")
      expect(msgs[0]).to be_a(Chamomile::BlurMsg)
    end

    it "handles focus events mixed with keypresses" do
      msgs = parse("a\e[Ib\e[Oc")
      expect(msgs.length).to eq(5)
      expect(msgs[0].key).to eq("a")
      expect(msgs[1]).to be_a(Chamomile::FocusMsg)
      expect(msgs[2].key).to eq("b")
      expect(msgs[3]).to be_a(Chamomile::BlurMsg)
      expect(msgs[4].key).to eq("c")
    end
  end

  describe "exec command" do
    include Chamomile::Commands

    it "creates ExecCmd with command and args" do
      cmd = exec("vim", "file.txt")
      result = cmd.call
      expect(result).to be_a(Chamomile::ExecCmd)
      expect(result.command).to eq("vim")
      expect(result.args).to eq(["file.txt"])
    end
  end

  describe "mixed input stream" do
    it "handles mouse, keys, and paste in sequence" do
      input = "\e[<0;5;5Ma\e[200~paste\e[201~\e[A"
      msgs = parse(input)
      expect(msgs.length).to eq(4)
      expect(msgs[0]).to be_a(Chamomile::MouseMsg)
      expect(msgs[1]).to be_a(Chamomile::KeyMsg)
      expect(msgs[1].key).to eq("a")
      expect(msgs[2]).to be_a(Chamomile::PasteMsg)
      expect(msgs[2].content).to eq("paste")
      expect(msgs[3]).to be_a(Chamomile::KeyMsg)
      expect(msgs[3].key).to eq(:up)
    end
  end
end
