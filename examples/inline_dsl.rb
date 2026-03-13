# frozen_string_literal: true

# Inline Spinner — DSL style
# Run: ruby examples/inline_dsl.rb
# Compare: examples/inline_explicit.rb

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

    vertical(align: :left) do
      text "#{spinner} Processing... #{@progress}%"
      text "[#{bar}]"
      text "Press q to cancel."
    end
  end
end

puts "Inline mode spinner example:"
puts "(This renders within your scrollback, no alt screen)"
puts ""
Chamomile.run(InlineSpinner.new) do |config|
  config.alt_screen = false
end
puts "\nDone!"
