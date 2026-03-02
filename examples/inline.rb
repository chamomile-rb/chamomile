# frozen_string_literal: true

require_relative "../lib/chamomile"

class InlineSpinner
  include Chamomile::Model
  include Chamomile::Commands

  FRAMES = ["|", "/", "-", "\\"].freeze

  def initialize
    @frame = 0
    @progress = 0
  end

  def start
    tick(0.1)
  end

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      return quit if msg.key == "q" || msg.ctrl?
    when Chamomile::TickMsg
      @frame = (@frame + 1) % FRAMES.length
      @progress = [@progress + 1, 100].min
      return quit if @progress >= 100

      return tick(0.1)
    end
    nil
  end

  def view
    spinner = FRAMES[@frame]
    bar_width = 30
    filled = (@progress * bar_width / 100.0).round
    empty = bar_width - filled
    bar = "#{"=" * filled}#{" " * empty}"

    lines = []
    lines << "#{spinner} Processing... #{@progress}%"
    lines << "[#{bar}]"
    lines << "Press q to cancel."
    lines.join("\n")
  end
end

puts "Inline mode spinner example:"
puts "(This renders within your scrollback, no alt screen)"
puts ""
Chamomile.run(InlineSpinner.new, alt_screen: false)
puts "\nDone!"
