# frozen_string_literal: true

require "spec_helper"

RSpec.describe "symbol position API" do
  describe "resolve_position" do
    it ":top resolves to 0.0" do
      expect(Chamomile.resolve_position(:top)).to eq(0.0)
    end

    it ":left resolves to 0.0" do
      expect(Chamomile.resolve_position(:left)).to eq(0.0)
    end

    it ":center resolves to 0.5" do
      expect(Chamomile.resolve_position(:center)).to eq(0.5)
    end

    it ":bottom resolves to 1.0" do
      expect(Chamomile.resolve_position(:bottom)).to eq(1.0)
    end

    it ":right resolves to 1.0" do
      expect(Chamomile.resolve_position(:right)).to eq(1.0)
    end

    it "passes through float values" do
      expect(Chamomile.resolve_position(0.75)).to eq(0.75)
    end

    it "raises for unknown symbol" do
      expect { Chamomile.resolve_position(:bogus) }.to raise_error(ArgumentError)
    end
  end

  describe "Style#align_horizontal with symbols" do
    it ":center works" do
      style = Chamomile::Style.new.width(20).align_horizontal(:center)
      result = style.render("hi")
      lines = result.split("\n")
      # "hi" should be centered in 20-char width
      expect(lines[0]).to match(/\s{9}hi\s{9}/)
    end

    it ":right works" do
      style = Chamomile::Style.new.width(20).align_horizontal(:right)
      result = style.render("hi")
      lines = result.split("\n")
      expect(lines[0]).to match(/\s{18}hi/)
    end
  end

  describe "Style#align_vertical with symbols" do
    it ":center works" do
      style = Chamomile::Style.new.height(5).align_vertical(:center)
      result = style.render("hi")
      lines = result.split("\n", -1)
      expect(lines.length).to eq(5)
      # "hi" should be near the middle
      expect(lines[2]).to include("hi")
    end
  end

  describe "Chamomile.horizontal" do
    it "joins boxes side by side with align: :top" do
      result = Chamomile.horizontal(%w[hello world], align: :top)
      expect(result).to eq("helloworld")
    end

    it "produces same result as old join_horizontal" do
      old = Chamomile.join_horizontal(Chamomile::TOP, "hello", "world")
      new_result = Chamomile.horizontal(%w[hello world], align: :top)
      expect(new_result).to eq(old)
    end

    it "supports block form" do
      result = Chamomile.horizontal(align: :top) { %w[hello world] }
      expect(result).to eq("helloworld")
    end
  end

  describe "Chamomile.vertical" do
    it "stacks boxes with align: :left" do
      result = Chamomile.vertical(%w[hello world], align: :left)
      expect(result).to eq("hello\nworld")
    end

    it "produces same result as old join_vertical" do
      old = Chamomile.join_vertical(Chamomile::LEFT, "hello", "world")
      new_result = Chamomile.vertical(%w[hello world], align: :left)
      expect(new_result).to eq(old)
    end

    it "supports block form" do
      result = Chamomile.vertical(align: :left) { %w[hello world] }
      expect(result).to eq("hello\nworld")
    end
  end

  describe "Chamomile.place with keyword args" do
    it "places content with keyword arguments" do
      result = Chamomile.place("hi", width: 20, height: 3, align: :center, valign: :center)
      expect(result).to include("hi")
      lines = result.split("\n")
      expect(lines.length).to eq(3)
    end

    it "defaults align and valign" do
      result = Chamomile.place("hi", width: 10, height: 1)
      expect(result).to include("hi")
    end
  end

  describe "join_horizontal/join_vertical accept symbols" do
    it "join_horizontal with :top symbol works" do
      result = Chamomile.join_horizontal(:top, "hello", "world")
      expect(result).to eq("helloworld")
    end

    it "join_vertical with :left symbol works" do
      result = Chamomile.join_vertical(:left, "hello", "world")
      expect(result).to eq("hello\nworld")
    end
  end
end
