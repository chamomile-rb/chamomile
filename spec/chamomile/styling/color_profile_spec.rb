# frozen_string_literal: true

RSpec.describe Chamomile::ColorProfile do
  describe ".detect" do
    around do |example|
      old_no_color = ENV.delete("NO_COLOR")
      old_colorterm = ENV.delete("COLORTERM")
      old_term = ENV.delete("TERM")
      example.run
    ensure
      old_no_color ? ENV["NO_COLOR"] = old_no_color : ENV.delete("NO_COLOR")
      old_colorterm ? ENV["COLORTERM"] = old_colorterm : ENV.delete("COLORTERM")
      old_term ? ENV["TERM"] = old_term : ENV.delete("TERM")
    end

    it "returns NO_COLOR when NO_COLOR is set" do
      ENV["NO_COLOR"] = "1"
      expect(described_class.detect).to eq(Chamomile::ColorProfile::NO_COLOR)
    end

    it "returns TRUE_COLOR for truecolor COLORTERM" do
      ENV["COLORTERM"] = "truecolor"
      expect(described_class.detect).to eq(Chamomile::ColorProfile::TRUE_COLOR)
    end

    it "returns TRUE_COLOR for 24bit COLORTERM" do
      ENV["COLORTERM"] = "24bit"
      expect(described_class.detect).to eq(Chamomile::ColorProfile::TRUE_COLOR)
    end

    it "returns ANSI256 for 256color TERM" do
      ENV["TERM"] = "xterm-256color"
      expect(described_class.detect).to eq(Chamomile::ColorProfile::ANSI256)
    end

    it "returns ANSI for color TERM" do
      ENV["TERM"] = "xterm-color"
      expect(described_class.detect).to eq(Chamomile::ColorProfile::ANSI)
    end

    it "returns ANSI for ansi TERM" do
      ENV["TERM"] = "ansi"
      expect(described_class.detect).to eq(Chamomile::ColorProfile::ANSI)
    end

    it "returns ANSI as default" do
      expect(described_class.detect).to eq(Chamomile::ColorProfile::ANSI)
    end
  end

  describe ".downsample" do
    it "returns NoColor for NO_COLOR profile" do
      color = Chamomile::Color::TrueColor.new(255, 0, 0)
      result = described_class.downsample(color, Chamomile::ColorProfile::NO_COLOR)
      expect(result).to be_a(Chamomile::Color::NoColor)
    end

    it "passes TrueColor through for TRUE_COLOR profile" do
      color = Chamomile::Color::TrueColor.new(255, 0, 0)
      result = described_class.downsample(color, Chamomile::ColorProfile::TRUE_COLOR)
      expect(result).to be(color)
    end

    it "converts TrueColor red to ANSI256" do
      color = Chamomile::Color::TrueColor.new(255, 0, 0)
      result = described_class.downsample(color, Chamomile::ColorProfile::ANSI256)
      expect(result).to be_a(Chamomile::Color::ANSI256Color)
    end

    it "converts TrueColor to ANSI" do
      color = Chamomile::Color::TrueColor.new(255, 0, 0)
      result = described_class.downsample(color, Chamomile::ColorProfile::ANSI)
      expect(result).to be_a(Chamomile::Color::ANSIColor)
    end

    it "converts ANSI256 to ANSI" do
      color = Chamomile::Color::ANSI256Color.new(196)
      result = described_class.downsample(color, Chamomile::ColorProfile::ANSI)
      expect(result).to be_a(Chamomile::Color::ANSIColor)
    end

    it "passes ANSIColor through for any profile" do
      color = Chamomile::Color::ANSIColor.new(1)
      expect(described_class.downsample(color, Chamomile::ColorProfile::ANSI)).to be(color)
      expect(described_class.downsample(color, Chamomile::ColorProfile::ANSI256)).to be(color)
      expect(described_class.downsample(color, Chamomile::ColorProfile::TRUE_COLOR)).to be(color)
    end

    it "converts grayscale TrueColor to ANSI256 grayscale" do
      color = Chamomile::Color::TrueColor.new(128, 128, 128)
      result = described_class.downsample(color, Chamomile::ColorProfile::ANSI256)
      expect(result).to be_a(Chamomile::Color::ANSI256Color)
      expect(result.code).to be_between(232, 255)
    end

    it "converts pure black to ANSI256 code 16" do
      color = Chamomile::Color::TrueColor.new(0, 0, 0)
      result = described_class.downsample(color, Chamomile::ColorProfile::ANSI256)
      expect(result.code).to eq(16)
    end

    it "converts pure white to ANSI256 code 231" do
      color = Chamomile::Color::TrueColor.new(255, 255, 255)
      result = described_class.downsample(color, Chamomile::ColorProfile::ANSI256)
      expect(result.code).to eq(231)
    end

    it "passes ANSI256 through for ANSI256 profile" do
      color = Chamomile::Color::ANSI256Color.new(100)
      result = described_class.downsample(color, Chamomile::ColorProfile::ANSI256)
      expect(result).to be(color)
    end
  end
end
