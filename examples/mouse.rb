# frozen_string_literal: true

require_relative "../lib/chamomile"

class MouseTracker
  include Chamomile::Model
  include Chamomile::Commands

  def initialize
    @x = 0
    @y = 0
    @button = ""
    @action = ""
    @events = 0
  end

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      return quit if msg.key == "q" || msg.ctrl?
    when Chamomile::MouseMsg
      @x = msg.x
      @y = msg.y
      @button = msg.button.to_s
      @action = msg.action.to_s
      @events += 1
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
