# frozen_string_literal: true

RSpec.describe Chamomile::Align do
  describe ".horizontal" do
    it "left-aligns with position 0.0" do
      result = described_class.horizontal(["hi"], 10, 0.0)
      expect(result[0]).to eq("hi        ")
    end

    it "right-aligns with position 1.0" do
      result = described_class.horizontal(["hi"], 10, 1.0)
      expect(result[0]).to eq("        hi")
    end

    it "center-aligns with position 0.5" do
      result = described_class.horizontal(["hi"], 10, 0.5)
      stripped = result[0]
      # 8 gap: left=4, right=4
      expect(stripped).to eq("    hi    ")
    end

    it "does not pad if line is wider than width" do
      result = described_class.horizontal(["hello world"], 5, 0.5)
      expect(result[0]).to eq("hello world")
    end

    it "handles empty lines" do
      result = described_class.horizontal([""], 5, 0.0)
      expect(result[0]).to eq("     ")
    end

    it "aligns multiple lines independently" do
      result = described_class.horizontal(%w[hi hello], 10, 1.0)
      expect(Chamomile::ANSI.printable_width(result[0])).to eq(10)
      expect(Chamomile::ANSI.printable_width(result[1])).to eq(10)
      expect(result[0]).to end_with("hi")
      expect(result[1]).to end_with("hello")
    end

    it "handles ANSI-styled text" do
      result = described_class.horizontal(["\e[1mhi\e[0m"], 10, 1.0)
      # Printable width of "hi" is 2, so 8 spaces on left
      expect(result[0]).to start_with("        ")
      expect(result[0]).to include("\e[1mhi\e[0m")
    end

    it "handles position 0.25" do
      result = described_class.horizontal(["ab"], 10, 0.25)
      # gap = 8, left = round(8 * 0.25) = 2
      expect(result[0]).to start_with("  ab")
    end
  end

  describe ".vertical" do
    it "top-aligns with position 0.0" do
      result = described_class.vertical(["hi"], 5, 0.0)
      expect(result.length).to eq(5)
      expect(result[0]).to eq("hi")
      expect(result[1]).to eq("")
    end

    it "bottom-aligns with position 1.0" do
      result = described_class.vertical(["hi"], 5, 1.0)
      expect(result.length).to eq(5)
      expect(result[4]).to eq("hi")
      expect(result[0]).to eq("")
    end

    it "center-aligns with position 0.5" do
      result = described_class.vertical(["hi"], 5, 0.5)
      expect(result.length).to eq(5)
      expect(result[2]).to eq("hi")
    end

    it "does not pad if already at height" do
      result = described_class.vertical(%w[a b c], 3, 0.5)
      expect(result).to eq(%w[a b c])
    end

    it "does not pad if taller than height" do
      result = described_class.vertical(%w[a b c d], 2, 0.5)
      expect(result).to eq(%w[a b c d])
    end

    it "handles empty array" do
      result = described_class.vertical([], 3, 0.0)
      expect(result.length).to eq(3)
    end
  end
end
