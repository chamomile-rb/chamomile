RSpec.describe Chamomile::KeyMap do
  describe ".translate" do
    it "translates arrow keys" do
      expect(described_class.translate("\e[A")).to eq(Chamomile::KeyMsg.new(key: :up, mod: []))
      expect(described_class.translate("\e[B")).to eq(Chamomile::KeyMsg.new(key: :down, mod: []))
      expect(described_class.translate("\e[C")).to eq(Chamomile::KeyMsg.new(key: :right, mod: []))
      expect(described_class.translate("\e[D")).to eq(Chamomile::KeyMsg.new(key: :left, mod: []))
    end

    it "translates ctrl combos" do
      msg = described_class.translate("\x03")
      expect(msg.key).to eq("c")
      expect(msg.mod).to eq([:ctrl])
      expect(msg.ctrl?).to be true
    end

    it "translates enter" do
      expect(described_class.translate("\x0d").key).to eq(:enter)
      expect(described_class.translate("\x0a").key).to eq(:enter)
    end

    it "translates backspace" do
      expect(described_class.translate("\x7f").key).to eq(:backspace)
      expect(described_class.translate("\x08").key).to eq(:backspace)
    end

    it "translates tab" do
      expect(described_class.translate("\x09").key).to eq(:tab)
    end

    it "translates escape" do
      expect(described_class.translate("\x1b").key).to eq(:escape)
    end

    it "translates function keys" do
      expect(described_class.translate("\eOP").key).to eq(:f1)
      expect(described_class.translate("\e[24~").key).to eq(:f12)
    end

    it "translates printable characters" do
      msg = described_class.translate("a")
      expect(msg.key).to eq("a")
      expect(msg.mod).to eq([])
    end

    it "passes unknown sequences with :unknown modifier" do
      msg = described_class.translate("\e[999~")
      expect(msg.key).to eq("\e[999~")
      expect(msg.mod).to eq([:unknown])
    end
  end
end
