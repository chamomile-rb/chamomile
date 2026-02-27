# frozen_string_literal: true

require_relative "../lib/chamomile"

class Counter
  include Chamomile::Model
  include Chamomile::Commands

  def initialize
    @count   = 0
    @seconds = 0
  end

  def init
    tick(1.0)
  end

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      case msg.key
      when :up,   "k" then @count += 1
      when :down, "j" then @count -= 1
      when "r"         then @count = 0
      when "q"         then return [self, quit]
      end
      return [self, nil]

    when Chamomile::TickMsg
      @seconds += 1
      return [self, tick(1.0)]
    end

    [self, nil]
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
