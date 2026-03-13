# frozen_string_literal: true

RSpec.describe Chamomile::Color do
  describe ".parse" do
    context "with nil or empty string" do
      it "returns NoColor for nil" do
        color = described_class.parse(nil)
        expect(color).to be_a(Chamomile::Color::NoColor)
        expect(color.no_color?).to be true
      end

      it "returns NoColor for empty string" do
        color = described_class.parse("")
        expect(color).to be_a(Chamomile::Color::NoColor)
      end
    end

    context "with ANSI codes 0-15" do
      it "returns ANSIColor for 0" do
        color = described_class.parse("0")
        expect(color).to be_a(Chamomile::Color::ANSIColor)
        expect(color.code).to eq(0)
      end

      it "returns ANSIColor for 15" do
        color = described_class.parse("15")
        expect(color).to be_a(Chamomile::Color::ANSIColor)
        expect(color.code).to eq(15)
      end

      it "returns ANSIColor for 7" do
        color = described_class.parse("7")
        expect(color).to be_a(Chamomile::Color::ANSIColor)
        expect(color.code).to eq(7)
      end
    end

    context "with ANSI256 codes 16-255" do
      it "returns ANSI256Color for 16" do
        color = described_class.parse("16")
        expect(color).to be_a(Chamomile::Color::ANSI256Color)
        expect(color.code).to eq(16)
      end

      it "returns ANSI256Color for 255" do
        color = described_class.parse("255")
        expect(color).to be_a(Chamomile::Color::ANSI256Color)
        expect(color.code).to eq(255)
      end

      it "returns ANSI256Color for 128" do
        color = described_class.parse("128")
        expect(color).to be_a(Chamomile::Color::ANSI256Color)
        expect(color.code).to eq(128)
      end
    end

    context "with hex colors" do
      it "parses #RGB shorthand" do
        color = described_class.parse("#f00")
        expect(color).to be_a(Chamomile::Color::TrueColor)
        expect(color.r).to eq(255)
        expect(color.g).to eq(0)
        expect(color.b).to eq(0)
      end

      it "parses #RRGGBB" do
        color = described_class.parse("#ff8800")
        expect(color).to be_a(Chamomile::Color::TrueColor)
        expect(color.r).to eq(255)
        expect(color.g).to eq(136)
        expect(color.b).to eq(0)
      end

      it "parses #000000" do
        color = described_class.parse("#000000")
        expect(color).to be_a(Chamomile::Color::TrueColor)
        expect([color.r, color.g, color.b]).to eq([0, 0, 0])
      end

      it "parses #ffffff" do
        color = described_class.parse("#ffffff")
        expect(color).to be_a(Chamomile::Color::TrueColor)
        expect([color.r, color.g, color.b]).to eq([255, 255, 255])
      end

      it "returns NoColor for invalid hex length" do
        color = described_class.parse("#12")
        expect(color).to be_a(Chamomile::Color::NoColor)
      end
    end
  end

  describe Chamomile::Color::ANSIColor do
    describe "#fg_sequence" do
      it "returns 30-37 for codes 0-7" do
        expect(described_class.new(0).fg_sequence).to eq("30")
        expect(described_class.new(1).fg_sequence).to eq("31")
        expect(described_class.new(7).fg_sequence).to eq("37")
      end

      it "returns 90-97 for codes 8-15" do
        expect(described_class.new(8).fg_sequence).to eq("90")
        expect(described_class.new(9).fg_sequence).to eq("91")
        expect(described_class.new(15).fg_sequence).to eq("97")
      end
    end

    describe "#bg_sequence" do
      it "returns 40-47 for codes 0-7" do
        expect(described_class.new(0).bg_sequence).to eq("40")
        expect(described_class.new(1).bg_sequence).to eq("41")
        expect(described_class.new(7).bg_sequence).to eq("47")
      end

      it "returns 100-107 for codes 8-15" do
        expect(described_class.new(8).bg_sequence).to eq("100")
        expect(described_class.new(15).bg_sequence).to eq("107")
      end
    end

    describe "#no_color?" do
      it "returns false" do
        expect(described_class.new(0).no_color?).to be false
      end
    end
  end

  describe Chamomile::Color::ANSI256Color do
    describe "#fg_sequence" do
      it "returns 38;5;N format" do
        expect(described_class.new(100).fg_sequence).to eq("38;5;100")
      end
    end

    describe "#bg_sequence" do
      it "returns 48;5;N format" do
        expect(described_class.new(200).bg_sequence).to eq("48;5;200")
      end
    end
  end

  describe Chamomile::Color::TrueColor do
    describe "#fg_sequence" do
      it "returns 38;2;R;G;B format" do
        expect(described_class.new(255, 128, 0).fg_sequence).to eq("38;2;255;128;0")
      end
    end

    describe "#bg_sequence" do
      it "returns 48;2;R;G;B format" do
        expect(described_class.new(0, 128, 255).bg_sequence).to eq("48;2;0;128;255")
      end
    end
  end

  describe Chamomile::Color::NoColor do
    it "returns nil for fg_sequence" do
      expect(described_class.new.fg_sequence).to be_nil
    end

    it "returns nil for bg_sequence" do
      expect(described_class.new.bg_sequence).to be_nil
    end

    it "returns true for no_color?" do
      expect(described_class.new.no_color?).to be true
    end
  end

  describe "named constants" do
    it "defines BLACK as ANSI 0" do
      expect(Chamomile::Color::BLACK.code).to eq(0)
    end

    it "defines RED as ANSI 1" do
      expect(Chamomile::Color::RED.code).to eq(1)
    end

    it "defines WHITE as ANSI 7" do
      expect(Chamomile::Color::WHITE.code).to eq(7)
    end

    it "defines BRIGHT_WHITE as ANSI 15" do
      expect(Chamomile::Color::BRIGHT_WHITE.code).to eq(15)
    end

    it "defines all 16 named colors" do
      names = %i[BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE
                 BRIGHT_BLACK BRIGHT_RED BRIGHT_GREEN BRIGHT_YELLOW
                 BRIGHT_BLUE BRIGHT_MAGENTA BRIGHT_CYAN BRIGHT_WHITE]
      names.each_with_index do |name, i|
        expect(Chamomile::Color.const_get(name).code).to eq(i)
      end
    end
  end
end
