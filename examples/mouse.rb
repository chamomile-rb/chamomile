# frozen_string_literal: true

require_relative "../lib/chamomile"

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

  def update(msg)
    case msg
    when Chamomile::KeyEvent
      return quit if msg.ctrl?
    end
    nil
  end

  def view
    lines = []
    lines << "Mouse Tracker"
    lines << "============="
    lines << ""
    lines << "Position: (#{@x}, #{@y})"
    lines << "Button:   #{@button}"
    lines << "Action:   #{@action}"
    lines << "Events:   #{@events}"
    lines << ""
    lines << "Move your mouse, click, or scroll."
    lines << "Press q to quit."
    lines.join("\n")
  end
end

Chamomile.run(MouseTracker.new, mouse: :all_motion)
