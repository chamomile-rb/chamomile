# frozen_string_literal: true

# Mouse Tracker — explicit Flourish style
# Run: ruby examples/mouse_explicit.rb
# Compare: examples/mouse_dsl.rb

require_relative "../lib/chamomile"
require "flourish"

class MouseTracker
  include Chamomile::Application

  def initialize
    @x = 0
    @y = 0
    @button = ""
    @action = ""
    @events = 0
  end

  on_key("q") { quit }

  on_mouse { |e|
    @x = e.x
    @y = e.y
    @button = e.button.to_s
    @action = e.action.to_s
    @events += 1
  }

  def view
    header = Flourish::Style.new.bold.foreground("#7d56f4").render("Mouse Tracker")
    bar    = Flourish::Style.new.foreground("#666666").render(
               "Move your mouse, click, or scroll. Press q to quit."
             )
    Flourish.vertical([
      header, "",
      "Position: (#{@x}, #{@y})",
      "Button:   #{@button}",
      "Action:   #{@action}",
      "Events:   #{@events}",
      "", bar
    ], align: :left)
  end
end

Chamomile.run(MouseTracker.new, mouse: :all_motion)
