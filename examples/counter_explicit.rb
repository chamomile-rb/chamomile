# frozen_string_literal: true

# Counter — explicit Flourish style
# Run: ruby examples/counter_explicit.rb
# Compare: examples/counter_dsl.rb (same output, DSL API)

require_relative "../lib/chamomile"
require "flourish"

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
    header = Flourish::Style.new.bold.foreground("#7d56f4").render("Counter")
    count  = "Count:   #{@count}"
    uptime = "Uptime:  #{@seconds}s"
    bar    = Flourish::Style.new.foreground("#666666").render(
               "up/k  increment  |  down/j  decrement  |  r  reset  |  q  quit"
             )
    Flourish.vertical([header, "", count, uptime, "", bar], align: :left)
  end
end

Chamomile.run(Counter.new)
