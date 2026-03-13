# frozen_string_literal: true

RSpec.describe Chamomile::Place do
  describe ".place" do
    it "places content at top-left" do
      result = described_class.place(10, 5, Chamomile::LEFT, Chamomile::TOP, "hi")
      lines = result.split("\n")
      expect(lines.length).to eq(5)
      expect(lines[0]).to start_with("hi")
      expect(Chamomile.width(lines[0])).to eq(10)
    end

    it "places content at bottom-right" do
      result = described_class.place(10, 5, Chamomile::RIGHT, Chamomile::BOTTOM, "hi")
      lines = result.split("\n")
      expect(lines.length).to eq(5)
      expect(lines[4]).to end_with("hi")
      expect(lines[0]).to eq(" " * 10)
    end

    it "places content at center" do
      result = described_class.place(10, 5, Chamomile::CENTER, Chamomile::CENTER, "hi")
      lines = result.split("\n")
      expect(lines.length).to eq(5)
      expect(lines[2]).to include("hi")
      # Centered horizontally in 10 chars
      expect(Chamomile.width(lines[2])).to eq(10)
    end

    it "handles multiline content" do
      result = described_class.place(10, 5, Chamomile::LEFT, Chamomile::TOP, "aa\nbb")
      lines = result.split("\n")
      expect(lines.length).to eq(5)
      expect(lines[0]).to start_with("aa")
      expect(lines[1]).to start_with("bb")
    end

    it "pads all lines to full width" do
      result = described_class.place(10, 3, Chamomile::LEFT, Chamomile::TOP, "hi")
      lines = result.split("\n")
      lines.each do |line|
        expect(Chamomile.width(line)).to eq(10)
      end
    end

    it "places content with ANSI codes" do
      result = described_class.place(10, 3, Chamomile::CENTER, Chamomile::CENTER, "\e[1mhi\e[0m")
      lines = result.split("\n")
      expect(lines.length).to eq(3)
      expect(lines[1]).to include("\e[1mhi\e[0m")
    end
  end

  describe ".place_horizontal" do
    it "places content at left" do
      result = described_class.place_horizontal(10, Chamomile::LEFT, "hi")
      expect(result).to eq("hi        ")
    end

    it "places content at right" do
      result = described_class.place_horizontal(10, Chamomile::RIGHT, "hi")
      expect(result).to eq("        hi")
    end

    it "places content at center" do
      result = described_class.place_horizontal(10, Chamomile::CENTER, "hi")
      expect(result).to eq("    hi    ")
    end

    it "handles multiline content" do
      result = described_class.place_horizontal(10, Chamomile::RIGHT, "aa\nbb")
      lines = result.split("\n")
      expect(lines[0]).to end_with("aa")
      expect(lines[1]).to end_with("bb")
    end
  end

  describe ".place_vertical" do
    it "places content at top" do
      result = described_class.place_vertical(5, Chamomile::TOP, "hi")
      lines = result.split("\n", -1)
      expect(lines.length).to eq(5)
      expect(lines[0]).to eq("hi")
    end

    it "places content at bottom" do
      result = described_class.place_vertical(5, Chamomile::BOTTOM, "hi")
      lines = result.split("\n", -1)
      expect(lines.length).to eq(5)
      expect(lines[4]).to eq("hi")
    end

    it "places content at center" do
      result = described_class.place_vertical(5, Chamomile::CENTER, "hi")
      lines = result.split("\n", -1)
      expect(lines.length).to eq(5)
      expect(lines[2]).to eq("hi")
    end

    it "handles multiline content" do
      result = described_class.place_vertical(5, Chamomile::BOTTOM, "a\nb")
      lines = result.split("\n", -1)
      expect(lines.length).to eq(5)
      expect(lines[3]).to eq("a")
      expect(lines[4]).to eq("b")
    end
  end
end
