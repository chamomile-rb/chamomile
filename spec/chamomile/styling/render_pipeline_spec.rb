# frozen_string_literal: true

RSpec.describe "Render pipeline" do
  describe "pipeline order: transform → tabs → wrap → sgr → align → padding → border → height → margin → max" do
    it "transform happens before SGR" do
      result = Chamomile::Style.new.bold.transform(&:upcase).render("hello")
      expect(result).to eq("\e[1mHELLO\e[0m")
    end

    it "tab conversion happens before wrap" do
      result = Chamomile::Style.new.tab_width(4).width(10).render("\thello")
      stripped = Chamomile::ANSI.strip(result)
      expect(stripped).not_to include("\t")
    end

    it "wrap happens before SGR" do
      result = Chamomile::Style.new.bold.width(5).render("hello world")
      lines = result.split("\n")
      lines.each { |l| expect(l).to start_with("\e[1m") }
    end

    it "alignment happens inside border" do
      result = Chamomile::Style.new
                               .width(20)
                               .align_horizontal(1.0)
                               .border(Chamomile::Border::ASCII)
                               .render("hi")
      lines = result.split("\n")
      # Content line should be right-aligned inside borders
      content_line = lines[1]
      expect(content_line).to start_with("|")
      expect(content_line).to end_with("|")
      inner = content_line[1..-2]
      expect(inner.rstrip).to end_with("hi")
    end

    it "padding happens inside border" do
      result = Chamomile::Style.new
                               .padding(0, 2)
                               .border(Chamomile::Border::ASCII)
                               .render("x")
      lines = result.split("\n")
      content = lines[1]
      # |  x  | — padding on both sides
      expect(content).to start_with("|  x")
      expect(content).to end_with("  |")
    end

    it "border happens before margin" do
      result = Chamomile::Style.new
                               .border(Chamomile::Border::ASCII)
                               .margin_left(3)
                               .render("x")
      lines = result.split("\n")
      lines.each do |line|
        expect(line).to start_with("   ") # 3 spaces of margin
      end
    end

    it "height enforcement happens after border" do
      result = Chamomile::Style.new
                               .height(5)
                               .border(Chamomile::Border::ASCII)
                               .render("x")
      lines = result.split("\n", -1)
      expect(lines.length).to eq(5)
    end

    it "margin happens after height" do
      result = Chamomile::Style.new
                               .height(3)
                               .margin(1)
                               .render("x")
      lines = result.split("\n", -1)
      # 1 margin + 3 height + 1 margin = 5
      expect(lines.length).to eq(5)
    end

    it "max_width truncates after everything" do
      result = Chamomile::Style.new
                               .width(20)
                               .border(Chamomile::Border::ASCII)
                               .margin_left(5)
                               .max_width(15)
                               .render("hello world")
      lines = result.split("\n")
      lines.each { |l| expect(Chamomile.width(l)).to be <= 15 }
    end

    it "max_height truncates after everything" do
      result = Chamomile::Style.new
                               .border(Chamomile::Border::ASCII)
                               .margin(2)
                               .max_height(5)
                               .render("hello")
      lines = result.split("\n", -1)
      expect(lines.length).to be <= 5
    end
  end

  describe "width calculation" do
    it "width includes padding but not margin" do
      result = Chamomile::Style.new.width(10).padding(0, 2).render("hi")
      expect(Chamomile.width(result)).to eq(10)
    end

    it "width includes border" do
      result = Chamomile::Style.new.width(10).border(Chamomile::Border::ASCII).render("hi")
      lines = result.split("\n")
      expect(Chamomile.width(lines[1])).to eq(10)
    end

    it "margin adds to total visual width" do
      result = Chamomile::Style.new.width(10).margin_left(3).margin_right(3).render("hi")
      expect(Chamomile.width(result)).to eq(16) # 3 + 10 + 3
    end

    it "content width = width - padding - border" do
      style = Chamomile::Style.new
                              .width(20)
                              .padding(0, 2)
                              .border(Chamomile::Border::ASCII)
      result = style.render("this is some long text that should wrap")
      lines = result.split("\n")
      lines.each { |l| expect(Chamomile.width(l)).to eq(20) }
    end
  end

  describe "SGR application" do
    it "each line gets its own SGR open/close" do
      result = Chamomile::Style.new.foreground("1").render("a\nb")
      lines = result.split("\n")
      expect(lines[0]).to eq("\e[31ma\e[0m")
      expect(lines[1]).to eq("\e[31mb\e[0m")
    end

    it "no SGR for unstyled text" do
      result = Chamomile::Style.new.render("hello")
      expect(result).to eq("hello")
      expect(result).not_to include("\e[")
    end

    it "SGR order: bold, faint, italic, underline, blink, reverse, strikethrough, fg, bg" do
      result = Chamomile::Style.new
                               .bold
                               .faint
                               .italic
                               .underline
                               .blink
                               .reverse
                               .strikethrough
                               .foreground("1")
                               .background("2")
                               .render("x")
      # SGR codes: 1;2;3;4;5;7;9;31;42
      expect(result).to include("1;2;3;4;5;7;9;31;42")
    end
  end

  describe "border rendering" do
    it "top border spans full content width" do
      result = Chamomile::Style.new.width(10).border(Chamomile::Border::ASCII).render("hi")
      lines = result.split("\n")
      top = lines[0]
      # +--------+ = 10 chars
      expect(Chamomile.width(top)).to eq(10)
    end

    it "content lines are padded to fill border" do
      result = Chamomile::Style.new.width(10).border(Chamomile::Border::ASCII).render("hi")
      lines = result.split("\n")
      content = lines[1]
      # |hi      | = 10 chars
      expect(Chamomile.width(content)).to eq(10)
    end

    it "border with no content" do
      result = Chamomile::Style.new.border(Chamomile::Border::ASCII).render("")
      lines = result.split("\n")
      expect(lines.length).to eq(3) # top + empty content + bottom
    end

    it "border with multiline content" do
      result = Chamomile::Style.new.border(Chamomile::Border::ASCII).render("aa\nbbb")
      lines = result.split("\n")
      expect(lines.length).to eq(4) # top + 2 content + bottom
    end

    it "styled border characters" do
      result = Chamomile::Style.new
                               .border(Chamomile::Border::ASCII)
                               .border_foreground("1")
                               .border_background("4")
                               .render("hi")
      # Border chars should have both fg and bg
      expect(result).to include("31;44")
    end
  end

  describe "padding rendering" do
    it "left padding is prepended to each content line" do
      result = Chamomile::Style.new.padding_left(3).render("hi\nbye")
      lines = result.split("\n")
      lines.each { |l| expect(l).to start_with("   ") }
    end

    it "right padding is appended to each content line" do
      result = Chamomile::Style.new.padding_right(3).render("hi")
      expect(result).to end_with("   ")
    end

    it "top padding adds blank lines before content" do
      result = Chamomile::Style.new.width(5).padding_top(2).render("hi")
      lines = result.split("\n", -1)
      expect(lines[0].strip).to eq("")
      expect(lines[1].strip).to eq("")
    end

    it "bottom padding adds blank lines after content" do
      result = Chamomile::Style.new.width(5).padding_bottom(2).render("hi")
      lines = result.split("\n", -1)
      expect(lines[-1].strip).to eq("")
      expect(lines[-2].strip).to eq("")
    end
  end

  describe "margin rendering" do
    it "left margin prepends spaces" do
      result = Chamomile::Style.new.margin_left(5).render("hi")
      expect(result).to start_with("     hi")
    end

    it "right margin appends spaces" do
      result = Chamomile::Style.new.margin_right(5).render("hi")
      expect(result).to end_with("hi     ")
    end

    it "top margin adds empty lines before" do
      result = Chamomile::Style.new.margin_top(2).render("hi")
      lines = result.split("\n", -1)
      expect(lines[0]).to eq("")
      expect(lines[1]).to eq("")
      expect(lines[2]).to eq("hi")
    end

    it "bottom margin adds empty lines after" do
      result = Chamomile::Style.new.margin_bottom(2).render("hi")
      lines = result.split("\n", -1)
      expect(lines[-1]).to eq("")
      expect(lines[-2]).to eq("")
    end
  end

  describe "height enforcement" do
    it "pads short content to height" do
      result = Chamomile::Style.new.height(5).render("hi")
      lines = result.split("\n", -1)
      expect(lines.length).to eq(5)
    end

    it "truncates tall content to height" do
      result = Chamomile::Style.new.height(2).render("a\nb\nc\nd")
      lines = result.split("\n", -1)
      expect(lines.length).to eq(2)
    end

    it "exact height produces no change" do
      result = Chamomile::Style.new.height(3).render("a\nb\nc")
      lines = result.split("\n", -1)
      expect(lines.length).to eq(3)
    end
  end

  describe "max constraints" do
    it "max_width does not affect content within limit" do
      result = Chamomile::Style.new.max_width(20).render("hello")
      expect(result).to eq("hello")
    end

    it "max_height does not affect content within limit" do
      result = Chamomile::Style.new.max_height(5).render("a\nb")
      expect(result).to eq("a\nb")
    end

    it "max_width truncates ANSI-styled lines" do
      result = Chamomile::Style.new.bold.max_width(5).render("hello world")
      expect(Chamomile.width(result)).to be <= 5
    end
  end
end
