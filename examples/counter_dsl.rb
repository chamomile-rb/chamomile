# frozen_string_literal: true

# Counter — DSL style
# Run: ruby examples/counter_dsl.rb
# Compare: examples/counter_explicit.rb (same output, explicit Chamomile API)

require_relative "../lib/chamomile"
# (styling is included in chamomile)

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

  on_tick { @seconds += 1; tick(1.0) }

  def on_start
    tick(1.0)
  end

  def view
    vertical(align: :left) do
      text "Counter", bold: true, color: "#7d56f4"
      text ""
      text "Count:   #{@count}"
      text "Uptime:  #{@seconds}s"
      text ""
      status_bar "up/k  increment  |  down/j  decrement  |  r  reset  |  q  quit"
    end
  end
end

Chamomile.run(Counter.new)
