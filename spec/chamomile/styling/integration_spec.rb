# frozen_string_literal: true

RSpec.describe "Chamomile styling integration" do
  describe "module-level helpers" do
    it "Chamomile.width delegates to ANSI.printable_width" do
      expect(Chamomile.width("hello")).to eq(5)
    end

    it "Chamomile.height delegates to ANSI.height" do
      expect(Chamomile.height("a\nb")).to eq(2)
    end

    it "Chamomile.size delegates to ANSI.size" do
      expect(Chamomile.size("hi\nhello")).to eq([5, 2])
    end

    it "Chamomile.width handles ANSI codes" do
      expect(Chamomile.width("\e[1mhi\e[0m")).to eq(2)
    end
  end

  describe "position constants" do
    it "defines TOP as 0.0" do
      expect(Chamomile::TOP).to eq(0.0)
    end

    it "defines LEFT as 0.0" do
      expect(Chamomile::LEFT).to eq(0.0)
    end

    it "defines CENTER as 0.5" do
      expect(Chamomile::CENTER).to eq(0.5)
    end

    it "defines BOTTOM as 1.0" do
      expect(Chamomile::BOTTOM).to eq(1.0)
    end

    it "defines RIGHT as 1.0" do
      expect(Chamomile::RIGHT).to eq(1.0)
    end
  end

  describe "Chamomile.join_horizontal" do
    it "delegates to Join.horizontal" do
      result = Chamomile.join_horizontal(Chamomile::TOP, "a", "b")
      expect(result).to eq("ab")
    end
  end

  describe "Chamomile.join_vertical" do
    it "delegates to Join.vertical" do
      result = Chamomile.join_vertical(Chamomile::LEFT, "a", "b")
      expect(result).to eq("a\nb")
    end
  end

  describe "Chamomile.place" do
    it "delegates to Place.place" do
      result = Chamomile.place(10, 3, Chamomile::CENTER, Chamomile::CENTER, "hi")
      lines = result.split("\n")
      expect(lines.length).to eq(3)
    end
  end

  describe "Chamomile.place_horizontal" do
    it "delegates to Place.place_horizontal" do
      result = Chamomile.place_horizontal(10, Chamomile::RIGHT, "hi")
      expect(result).to end_with("hi")
    end
  end

  describe "Chamomile.place_vertical" do
    it "delegates to Place.place_vertical" do
      result = Chamomile.place_vertical(5, Chamomile::CENTER, "hi")
      lines = result.split("\n", -1)
      expect(lines.length).to eq(5)
    end
  end

  describe "composing styles with join" do
    it "joins two bordered boxes horizontally" do
      a = Chamomile::Style.new.border(Chamomile::Border::ASCII).render("A")
      b = Chamomile::Style.new.border(Chamomile::Border::ASCII).render("B")
      result = Chamomile.join_horizontal(Chamomile::TOP, a, b)
      lines = result.split("\n")
      expect(lines.length).to eq(3)
    end

    it "joins two bordered boxes vertically" do
      a = Chamomile::Style.new.border(Chamomile::Border::ASCII).render("A")
      b = Chamomile::Style.new.border(Chamomile::Border::ASCII).render("B")
      result = Chamomile.join_vertical(Chamomile::LEFT, a, b)
      lines = result.split("\n")
      expect(lines.length).to eq(6)
    end

    it "places a styled box in a larger area" do
      box = Chamomile::Style.new
                            .bold
                            .foreground("#ff0")
                            .border(Chamomile::Border::ROUNDED)
                            .render("centered")
      result = Chamomile.place(40, 10, Chamomile::CENTER, Chamomile::CENTER, box)
      lines = result.split("\n")
      expect(lines.length).to eq(10)
      lines.each { |l| expect(Chamomile.width(l)).to eq(40) }
    end
  end

  describe "style with all features" do
    it "renders a fully featured style" do
      result = Chamomile::Style.new
                               .bold
                               .italic
                               .foreground("#ff0000")
                               .background("#000033")
                               .width(30)
                               .padding(1, 2)
                               .border(Chamomile::Border::DOUBLE)
                               .border_foreground("#ff0")
                               .margin(1)
                               .align_horizontal(0.5)
                               .render("Hello!")

      lines = result.split("\n", -1)
      expect(lines.length).to be >= 7
      expect(result).to include("Hello!")
    end
  end

  describe "color profile downsampling with style" do
    it "downsample TrueColor to ANSI256" do
      color = Chamomile::Color.parse("#ff0000")
      result = Chamomile::ColorProfile.downsample(color, Chamomile::ColorProfile::ANSI256)
      expect(result).to be_a(Chamomile::Color::ANSI256Color)
      expect(result.fg_sequence).to start_with("38;5;")
    end

    it "downsample TrueColor to ANSI" do
      color = Chamomile::Color.parse("#ff0000")
      result = Chamomile::ColorProfile.downsample(color, Chamomile::ColorProfile::ANSI)
      expect(result).to be_a(Chamomile::Color::ANSIColor)
    end
  end
end
