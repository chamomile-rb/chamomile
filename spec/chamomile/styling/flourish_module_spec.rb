# frozen_string_literal: true

RSpec.describe Chamomile do
  describe ".width" do
    it "handles plain text" do
      expect(described_class.width("hello")).to eq(5)
    end

    it "handles styled text" do
      expect(described_class.width("\e[1mhi\e[0m")).to eq(2)
    end

    it "handles CJK" do
      expect(described_class.width("你好世界")).to eq(8)
    end

    it "handles empty string" do
      expect(described_class.width("")).to eq(0)
    end
  end

  describe ".height" do
    it "counts lines" do
      expect(described_class.height("a\nb\nc")).to eq(3)
    end

    it "single line" do
      expect(described_class.height("hello")).to eq(1)
    end

    it "empty string" do
      expect(described_class.height("")).to eq(1)
    end
  end

  describe ".size" do
    it "returns width and height" do
      expect(described_class.size("hi\nhello")).to eq([5, 2])
    end

    it "handles single line" do
      expect(described_class.size("hello")).to eq([5, 1])
    end
  end

  describe ".join_horizontal" do
    it "joins blocks side by side" do
      expect(described_class.join_horizontal(0.0, "a", "b")).to eq("ab")
    end

    it "accepts array" do
      expect(described_class.join_horizontal(0.0, %w[a b])).to eq("ab")
    end
  end

  describe ".join_vertical" do
    it "stacks blocks" do
      expect(described_class.join_vertical(0.0, "a", "b")).to eq("a\nb")
    end

    it "accepts array" do
      expect(described_class.join_vertical(0.0, %w[a b])).to eq("a\nb")
    end
  end

  describe ".place" do
    it "places in box" do
      result = described_class.place(10, 3, 0.5, 0.5, "x")
      lines = result.split("\n")
      expect(lines.length).to eq(3)
      expect(lines[1]).to include("x")
    end
  end

  describe ".place_horizontal" do
    it "places horizontally" do
      result = described_class.place_horizontal(10, 0.5, "ab")
      expect(result).to eq("    ab    ")
    end
  end

  describe ".place_vertical" do
    it "places vertically" do
      result = described_class.place_vertical(3, 0.5, "x")
      lines = result.split("\n", -1)
      expect(lines.length).to eq(3)
      expect(lines[1]).to eq("x")
    end
  end

  describe "VERSION" do
    it "is defined" do
      expect(Chamomile::VERSION).to be_a(String)
      expect(Chamomile::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end
end
