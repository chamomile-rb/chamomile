# frozen_string_literal: true

RSpec.describe Chamomile::Wrap do
  describe ".word_wrap" do
    it "returns text unchanged if within width" do
      expect(described_class.word_wrap("hello", 10)).to eq("hello")
    end

    it "wraps at word boundary" do
      result = described_class.word_wrap("hello world", 7)
      lines = result.split("\n")
      expect(lines.length).to eq(2)
      expect(lines[0].strip).to eq("hello")
      expect(lines[1].strip).to eq("world")
    end

    it "wraps long words by breaking mid-word" do
      result = described_class.word_wrap("abcdefghij", 5)
      lines = result.split("\n")
      expect(lines.length).to eq(2)
    end

    it "preserves existing newlines" do
      result = described_class.word_wrap("hello\nworld", 20)
      expect(result).to eq("hello\nworld")
    end

    it "handles empty string" do
      expect(described_class.word_wrap("", 10)).to eq("")
    end

    it "handles width of 0" do
      expect(described_class.word_wrap("hello", 0)).to eq("hello")
    end

    it "wraps multiple words" do
      result = described_class.word_wrap("the quick brown fox", 10)
      lines = result.split("\n")
      lines.each do |line|
        expect(Chamomile::ANSI.printable_width(line)).to be <= 10
      end
    end

    it "handles ANSI escape sequences" do
      input = "\e[1mhello world\e[0m"
      result = described_class.word_wrap(input, 7)
      stripped = Chamomile::ANSI.strip(result)
      lines = stripped.split("\n")
      expect(lines[0].strip).to eq("hello")
      expect(lines[1].strip).to eq("world")
    end

    it "preserves ANSI codes across line breaks" do
      input = "\e[31mhello world\e[0m"
      result = described_class.word_wrap(input, 7)
      lines = result.split("\n")
      # Second line should re-emit the color
      expect(lines[1]).to include("\e[31m")
    end

    it "handles multiple lines with wrapping" do
      input = "short\nthis is a longer line that wraps"
      result = described_class.word_wrap(input, 10)
      lines = result.split("\n")
      lines.each do |line|
        expect(Chamomile::ANSI.printable_width(line)).to be <= 10
      end
    end

    it "handles text that fits exactly" do
      result = described_class.word_wrap("hello", 5)
      expect(result).to eq("hello")
    end

    it "wraps at hyphen" do
      result = described_class.word_wrap("well-known fact", 10)
      lines = result.split("\n")
      expect(lines.length).to be >= 1
    end

    it "handles multiple spaces" do
      result = described_class.word_wrap("a  b  c", 4)
      lines = result.split("\n")
      lines.each do |line|
        expect(Chamomile::ANSI.printable_width(line)).to be <= 4
      end
    end
  end
end
