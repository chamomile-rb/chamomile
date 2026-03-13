# frozen_string_literal: true

# Mouse Tracker — DSL style
# Run: ruby examples/mouse_dsl.rb
# Compare: examples/mouse_explicit.rb

require_relative "../lib/chamomile"
# (styling is included in chamomile)

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
    vertical(align: :left) do
      text "Mouse Tracker", bold: true, color: "#7d56f4"
      text ""
      text "Position: (#{@x}, #{@y})"
      text "Button:   #{@button}"
      text "Action:   #{@action}"
      text "Events:   #{@events}"
      text ""
      status_bar "Move your mouse, click, or scroll. Press q to quit."
    end
  end
end

Chamomile.run(MouseTracker.new) do |config|
  config.mouse = :all_motion
end
