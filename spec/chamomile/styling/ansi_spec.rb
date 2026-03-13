# frozen_string_literal: true

RSpec.describe Chamomile::ANSI do
  describe ".strip" do
    it "returns plain text unchanged" do
      expect(described_class.strip("hello")).to eq("hello")
    end

    it "strips CSI SGR sequences" do
      expect(described_class.strip("\e[1mhello\e[0m")).to eq("hello")
    end

    it "strips multiple SGR sequences" do
      expect(described_class.strip("\e[1;31mhello\e[0m \e[32mworld\e[0m")).to eq("hello world")
    end

    it "strips CSI cursor sequences" do
      expect(described_class.strip("\e[2Jhello\e[H")).to eq("hello")
    end

    it "strips OSC sequences terminated by BEL" do
      expect(described_class.strip("\e]0;title\ahello")).to eq("hello")
    end

    it "strips OSC sequences terminated by ST" do
      expect(described_class.strip("\e]0;title\e\\hello")).to eq("hello")
    end

    it "strips ESC charset sequences" do
      expect(described_class.strip("\e(Bhello")).to eq("hello")
    end

    it "strips mixed sequences" do
      input = "\e[1m\e[31mhello\e[0m \e]0;title\aworld"
      expect(described_class.strip(input)).to eq("hello world")
    end

    it "handles empty string" do
      expect(described_class.strip("")).to eq("")
    end

    it "handles string with only escapes" do
      expect(described_class.strip("\e[1m\e[0m")).to eq("")
    end
  end

  describe ".printable_width" do
    it "returns width of plain ASCII text" do
      expect(described_class.printable_width("hello")).to eq(5)
    end

    it "ignores ANSI escape sequences" do
      expect(described_class.printable_width("\e[1mhello\e[0m")).to eq(5)
    end

    it "counts CJK characters as 2 cells" do
      expect(described_class.printable_width("你好")).to eq(4)
    end

    it "handles mixed ASCII and CJK" do
      expect(described_class.printable_width("hi你好")).to eq(6)
    end

    it "handles empty string" do
      expect(described_class.printable_width("")).to eq(0)
    end

    it "ignores control characters" do
      expect(described_class.printable_width("ab\x01cd")).to eq(4)
    end

    it "handles fullwidth punctuation" do
      expect(described_class.printable_width("！")).to eq(2)
    end

    it "handles emoji as wide chars" do
      expect(described_class.printable_width("🌸")).to eq(2)
    end

    it "handles styled CJK text" do
      expect(described_class.printable_width("\e[31m你好\e[0m")).to eq(4)
    end
  end

  describe ".height" do
    it "returns 1 for single line" do
      expect(described_class.height("hello")).to eq(1)
    end

    it "counts newlines" do
      expect(described_class.height("a\nb\nc")).to eq(3)
    end

    it "counts trailing newline" do
      expect(described_class.height("a\n")).to eq(2)
    end

    it "returns 1 for empty string" do
      expect(described_class.height("")).to eq(1)
    end
  end

  describe ".size" do
    it "returns [width, height] for single line" do
      expect(described_class.size("hello")).to eq([5, 1])
    end

    it "returns max width across lines" do
      expect(described_class.size("hi\nhello")).to eq([5, 2])
    end

    it "handles empty string" do
      expect(described_class.size("")).to eq([0, 1])
    end

    it "handles styled text" do
      expect(described_class.size("\e[1mhi\e[0m\nhello")).to eq([5, 2])
    end

    it "handles trailing newline" do
      w, h = described_class.size("abc\n")
      expect(w).to eq(3)
      expect(h).to eq(2)
    end
  end
end
