# frozen_string_literal: true

require "spec_helper"
require "flourish"
require "petals"

RSpec.describe "ViewDSL" do
  let(:app_class) do
    Class.new do
      include Chamomile::Application

      def initialize
        @items = %w[one two three]
        @cursor = 1
      end
    end
  end

  let(:app) { app_class.new }

  describe "vertical" do
    it "returns a Layout::Vertical" do
      result = app.vertical(align: :left) { app.text("hi") }
      expect(result).to be_a(Chamomile::Layout::Vertical)
    end

    it "renders to a string" do
      result = app.vertical(align: :left) { app.text("hello") }
      output = result.render(width: 40, height: 10)
      expect(output).to be_a(String)
      expect(output).to include("hello")
    end
  end

  describe "horizontal" do
    it "returns a Layout::Horizontal" do
      result = app.horizontal(align: :top) { app.text("hi") }
      expect(result).to be_a(Chamomile::Layout::Horizontal)
    end
  end

  describe "panel" do
    it "renders with border" do
      result = app.panel(title: "Test") { app.text("content") }
      output = result.render(width: 30, height: 8)
      expect(output).to include("content")
      expect(output).to include("│") # border character
    end

    it "panel(width: '40%').resolved_width(100) == 40" do
      result = app.panel(width: "40%") { app.text("x") }
      expect(result.resolved_width(100)).to eq(40)
    end

    it "panel(width: 30).resolved_width(100) == 30" do
      result = app.panel(width: 30) { app.text("x") }
      expect(result.resolved_width(100)).to eq(30)
    end
  end

  describe "text" do
    it "renders content" do
      widget = app.text("hello")
      output = widget.render(width: 40, height: 10)
      expect(output).to include("hello")
    end

    it "renders bold" do
      widget = app.text("hello", bold: true)
      output = widget.render(width: 40, height: 10)
      expect(output).to include("\e[1m") # bold SGR
    end

    it "renders with color" do
      widget = app.text("hello", color: "#ff0000")
      output = widget.render(width: 40, height: 10)
      expect(output).to include("hello")
      expect(output).to include("\e[") # has ANSI codes
    end
  end

  describe "status_bar" do
    it "fills full width" do
      widget = app.status_bar("q quit")
      output = widget.render(width: 80, height: 1)
      expect(output).to include("q quit")
    end
  end

  describe "list" do
    it "highlights item at cursor" do
      widget = app.list(%w[a b c], cursor: 1)
      output = widget.render(width: 20, height: 10)
      expect(output).to include("b")
      expect(output).to include("\e[7;") # reverse for selected (combined with color)
    end
  end

  describe "raw" do
    it "passes through pre-built string unchanged" do
      raw_string = "pre-built \e[1mstring\e[0m"
      widget = app.raw(raw_string)
      expect(widget.render(width: 80, height: 10)).to eq(raw_string)
    end
  end

  describe "nesting" do
    it "vertical { horizontal { text; text }; text } renders correctly" do
      result = app.vertical(align: :left) do
        app.horizontal(align: :top) do
          app.text("left")
          app.text("right")
        end
        app.text("bottom")
      end
      output = result.render(width: 80, height: 20)
      expect(output).to include("left")
      expect(output).to include("right")
      expect(output).to include("bottom")
    end
  end

  describe "mixed DSL + raw" do
    it "raw(styled_string) inside vertical works" do
      header = Chamomile::Style.new.bold.foreground("#7d56f4").render("Title")
      result = app.vertical(align: :left) do
        app.raw(header)
        app.text("body")
      end
      output = result.render(width: 80, height: 20)
      expect(output).to include("Title")
      expect(output).to include("body")
    end
  end

  describe "@ivar access" do
    it "block inside vertical can access instance variables" do
      klass = Class.new do
        include Chamomile::Application
        def initialize
          @name = "Claude"
        end

        def view
          vertical(align: :left) do
            text "Hello #{@name}"
          end
        end
      end

      instance = klass.new
      result = instance.view
      expect(result).to be_a(Chamomile::Layout::Vertical)
      output = result.render(width: 40, height: 10)
      expect(output).to include("Hello Claude")
    end
  end

  describe "stack resets between render calls" do
    it "no state leak between views" do
      klass = Class.new do
        include Chamomile::Application
        def initialize; @count = 0; end

        def view
          @count += 1
          vertical(align: :left) do
            text "render #{@count}"
          end
        end
      end

      instance = klass.new
      r1 = instance.view
      r2 = instance.view
      expect(r1.render(width: 40, height: 5)).to include("render 1")
      expect(r2.render(width: 40, height: 5)).to include("render 2")
    end
  end

  describe "backward compat" do
    it "view returning a String still works with renderer" do
      renderer = Chamomile::Renderer.new(output: StringIO.new, fps: 0)
      renderer.render("plain string")
    end

    it "view returning a Layout object works with renderer" do
      klass = Class.new do
        include Chamomile::Application
        def view
          vertical(align: :left) do
            text "DSL view"
          end
        end
      end

      renderer = Chamomile::Renderer.new(output: StringIO.new, fps: 0)
      result = klass.new.view
      renderer.render(result)
    end
  end
end
