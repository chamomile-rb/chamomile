# frozen_string_literal: true

require_relative "../lib/chamomile"

class Counter
  include Chamomile::Application

  def initialize
    @count   = 0
    @seconds = 0
  end

  on_key(:up, "k")   { @count += 1 }
  on_key(:down, "j") { @count -= 1 }
  on_key("r")        { @count = 0 }
  on_key("q")        { quit }

  on_tick do
    @seconds += 1
    tick(1.0)
  end

  def on_start
    tick(1.0)
  end

  def view
    <<~VIEW
      Chamomile Counter

      Count:   #{@count}
      Uptime:  #{@seconds}s

      up/k    increment
      down/j  decrement
      r       reset
      q       quit
    VIEW
  end
end

Chamomile.run(Counter.new)
