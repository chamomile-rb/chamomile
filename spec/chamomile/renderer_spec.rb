require "stringio"

RSpec.describe Chamomile::Renderer do
  let(:output) { StringIO.new }
  let(:renderer) { described_class.new(output: output) }

  describe "#enter_alt_screen" do
    it "writes alt screen on sequence" do
      renderer.enter_alt_screen
      expect(output.string).to include("\e[?1049h")
    end
  end

  describe "#exit_alt_screen" do
    it "writes alt screen off sequence" do
      renderer.exit_alt_screen
      expect(output.string).to include("\e[?1049l")
    end
  end

  describe "#hide_cursor" do
    it "writes hide cursor sequence" do
      renderer.hide_cursor
      expect(output.string).to include("\e[?25l")
    end
  end

  describe "#show_cursor" do
    it "writes show cursor sequence" do
      renderer.show_cursor
      expect(output.string).to include("\e[?25h")
    end
  end

  describe "#resize" do
    it "updates width and height" do
      renderer.resize(120, 40)
      expect(renderer.width).to eq(120)
      expect(renderer.height).to eq(40)
    end
  end

  describe "#render" do
    it "writes cursor home, clear, and view content" do
      renderer.render("Hello, world!")
      expect(output.string).to include("\e[H")
      expect(output.string).to include("\e[H\e[2J")
      expect(output.string).to include("Hello, world!")
    end
  end

  describe "#clear" do
    it "writes clear screen sequence" do
      renderer.clear
      expect(output.string).to include("\e[H\e[2J")
    end
  end

  describe "#println" do
    it "writes a line with newline" do
      renderer.println("test")
      expect(output.string).to eq("test\n")
    end
  end

  describe "defaults" do
    it "has default dimensions" do
      expect(renderer.width).to eq(80)
      expect(renderer.height).to eq(24)
    end
  end
end
