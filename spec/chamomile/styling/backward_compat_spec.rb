# frozen_string_literal: true

require "spec_helper"

RSpec.describe "backward compatibility" do
  describe "float position constants" do
    it "Chamomile::TOP still works" do
      expect(Chamomile::TOP).to eq(0.0)
    end

    it "Chamomile::CENTER still works" do
      expect(Chamomile::CENTER).to eq(0.5)
    end

    it "Chamomile::BOTTOM still works" do
      expect(Chamomile::BOTTOM).to eq(1.0)
    end

    it "Chamomile::LEFT still works" do
      expect(Chamomile::LEFT).to eq(0.0)
    end

    it "Chamomile::RIGHT still works" do
      expect(Chamomile::RIGHT).to eq(1.0)
    end
  end

  describe "old join methods" do
    it "join_horizontal(Chamomile::TOP, ...) still works" do
      result = Chamomile.join_horizontal(Chamomile::TOP, "hello", "world")
      expect(result).to include("hello")
      expect(result).to include("world")
    end

    it "join_vertical(Chamomile::LEFT, ...) still works" do
      result = Chamomile.join_vertical(Chamomile::LEFT, "hello", "world")
      expect(result).to include("hello")
      expect(result).to include("world")
    end
  end

  describe "old align with floats" do
    it "align_horizontal(0.5) still works" do
      style = Chamomile::Style.new.width(20).align_horizontal(0.5)
      result = style.render("hi")
      expect(result).to include("hi")
    end

    it "align_vertical(0.5) still works" do
      style = Chamomile::Style.new.height(5).align_vertical(0.5)
      result = style.render("hi")
      expect(result).to include("hi")
    end
  end

  describe "old place 5-arg form" do
    it "place(80, 24, Chamomile::CENTER, Chamomile::CENTER, content) still works" do
      result = Chamomile.place(20, 3, Chamomile::CENTER, Chamomile::CENTER, "hi")
      expect(result).to include("hi")
    end
  end
end
