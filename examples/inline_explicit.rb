# frozen_string_literal: true

# Inline Spinner — explicit Chamomile style
# Run: ruby examples/inline_explicit.rb
# Compare: examples/inline_dsl.rb

require_relative "../lib/chamomile"
# (styling is included in chamomile)

class InlineSpinner
  include Chamomile::Application

  FRAMES = ["|", "/", "-", "\\"].freeze

  def initialize
    @frame = 0
    @progress = 0
  end

  on_key("q") { quit }

  on_tick {
    @frame = (@frame + 1) % FRAMES.length
    @progress = [@progress + 1, 100].min
    if @progress >= 100
      quit
    else
      tick(0.1)
    end
  }

  def on_start
    tick(0.1)
  end

  def view
    spinner = FRAMES[@frame]
    bar_width = 30
    filled = (@progress * bar_width / 100.0).round
    empty = bar_width - filled
    bar = "#{"=" * filled}#{" " * empty}"

    Chamomile.vertical([
      "#{spinner} Processing... #{@progress}%",
      "[#{bar}]",
      "Press q to cancel."
    ], align: :left)
  end
end

puts "Inline mode spinner example:"
puts "(This renders within your scrollback, no alt screen)"
puts ""
Chamomile.run(InlineSpinner.new, alt_screen: false)
puts "\nDone!"
