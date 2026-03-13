# frozen_string_literal: true

RSpec.describe "Color detailed" do
  describe "ANSIColor fg_sequence mapping" do
    {
      0 => "30", 1 => "31", 2 => "32", 3 => "33",
      4 => "34", 5 => "35", 6 => "36", 7 => "37",
      8 => "90", 9 => "91", 10 => "92", 11 => "93",
      12 => "94", 13 => "95", 14 => "96", 15 => "97",
    }.each do |code, expected|
      it "code #{code} → fg #{expected}" do
        expect(Chamomile::Color::ANSIColor.new(code).fg_sequence).to eq(expected)
      end
    end
  end

  describe "ANSIColor bg_sequence mapping" do
    {
      0 => "40", 1 => "41", 2 => "42", 3 => "43",
      4 => "44", 5 => "45", 6 => "46", 7 => "47",
      8 => "100", 9 => "101", 10 => "102", 11 => "103",
      12 => "104", 13 => "105", 14 => "106", 15 => "107",
    }.each do |code, expected|
      it "code #{code} → bg #{expected}" do
        expect(Chamomile::Color::ANSIColor.new(code).bg_sequence).to eq(expected)
      end
    end
  end

  describe "TrueColor parsing" do
    it "parses #abc as expanded" do
      c = Chamomile::Color.parse("#abc")
      expect(c.r).to eq(170)
      expect(c.g).to eq(187)
      expect(c.b).to eq(204)
    end

    it "parses #123456" do
      c = Chamomile::Color.parse("#123456")
      expect(c.r).to eq(18)
      expect(c.g).to eq(52)
      expect(c.b).to eq(86)
    end

    it "parses #7f7f7f (mid gray)" do
      c = Chamomile::Color.parse("#7f7f7f")
      expect(c.r).to eq(127)
      expect(c.g).to eq(127)
      expect(c.b).to eq(127)
    end
  end

  describe "ANSI256Color sequences" do
    [16, 50, 100, 150, 200, 255].each do |code|
      it "code #{code} fg → 38;5;#{code}" do
        expect(Chamomile::Color::ANSI256Color.new(code).fg_sequence).to eq("38;5;#{code}")
      end

      it "code #{code} bg → 48;5;#{code}" do
        expect(Chamomile::Color::ANSI256Color.new(code).bg_sequence).to eq("48;5;#{code}")
      end
    end
  end

  describe "ColorProfile.downsample preserves identity" do
    it "TrueColor → TRUE_COLOR is identity" do
      c = Chamomile::Color::TrueColor.new(100, 200, 50)
      result = Chamomile::ColorProfile.downsample(c, Chamomile::ColorProfile::TRUE_COLOR)
      expect(result).to be(c)
    end

    it "ANSI256 → ANSI256 is identity" do
      c = Chamomile::Color::ANSI256Color.new(100)
      result = Chamomile::ColorProfile.downsample(c, Chamomile::ColorProfile::ANSI256)
      expect(result).to be(c)
    end

    it "ANSI → ANSI is identity" do
      c = Chamomile::Color::ANSIColor.new(5)
      result = Chamomile::ColorProfile.downsample(c, Chamomile::ColorProfile::ANSI)
      expect(result).to be(c)
    end

    it "ANSI → TRUE_COLOR is identity" do
      c = Chamomile::Color::ANSIColor.new(3)
      result = Chamomile::ColorProfile.downsample(c, Chamomile::ColorProfile::TRUE_COLOR)
      expect(result).to be(c)
    end
  end

  describe "ColorProfile.downsample TrueColor → ANSI256 color accuracy" do
    it "maps pure red near ANSI256 red" do
      c = Chamomile::Color::TrueColor.new(255, 0, 0)
      result = Chamomile::ColorProfile.downsample(c, Chamomile::ColorProfile::ANSI256)
      # Should be near code 196 (pure red in 6x6x6 cube)
      expect(result.code).to be_between(160, 210)
    end

    it "maps pure green near ANSI256 green" do
      c = Chamomile::Color::TrueColor.new(0, 255, 0)
      result = Chamomile::ColorProfile.downsample(c, Chamomile::ColorProfile::ANSI256)
      expect(result.code).to be_between(30, 80)
    end

    it "maps pure blue near ANSI256 blue" do
      c = Chamomile::Color::TrueColor.new(0, 0, 255)
      result = Chamomile::ColorProfile.downsample(c, Chamomile::ColorProfile::ANSI256)
      expect(result.code).to be_between(16, 50)
    end

    it "maps mid gray to grayscale ramp" do
      c = Chamomile::Color::TrueColor.new(128, 128, 128)
      result = Chamomile::ColorProfile.downsample(c, Chamomile::ColorProfile::ANSI256)
      expect(result.code).to be_between(232, 255)
    end
  end

  describe "ColorProfile.detect with env vars" do
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

    it "NO_COLOR takes precedence over COLORTERM" do
      ENV["NO_COLOR"] = "1"
      ENV["COLORTERM"] = "truecolor"
      expect(Chamomile::ColorProfile.detect).to eq(Chamomile::ColorProfile::NO_COLOR)
    end

    it "COLORTERM takes precedence over TERM" do
      ENV["COLORTERM"] = "truecolor"
      ENV["TERM"] = "xterm"
      expect(Chamomile::ColorProfile.detect).to eq(Chamomile::ColorProfile::TRUE_COLOR)
    end

    it "handles TERM=screen-256color" do
      ENV["TERM"] = "screen-256color"
      expect(Chamomile::ColorProfile.detect).to eq(Chamomile::ColorProfile::ANSI256)
    end

    it "handles TERM=dumb" do
      ENV["TERM"] = "dumb"
      expect(Chamomile::ColorProfile.detect).to eq(Chamomile::ColorProfile::ANSI)
    end
  end
end
