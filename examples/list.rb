# frozen_string_literal: true

require_relative "../lib/chamomile"

class ItemList
  include Chamomile::Model
  include Chamomile::Commands

  ITEMS = %w[Apples Bananas Cherries Dates Elderberries].freeze

  def initialize
    @cursor   = 0
    @selected = {}
  end

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      case msg.key
      when :up,   "k" then @cursor = [@cursor - 1, 0].max
      when :down, "j" then @cursor = [@cursor + 1, ITEMS.size - 1].min
      when " ", :enter
        if @selected[@cursor]
          @selected.delete(@cursor)
        else
          @selected[@cursor] = true
        end
      when "q" then return [self, quit]
      end
    end
    [self, nil]
  end

  def view
    lines = ["Pick some items:\n\n"]
    ITEMS.each_with_index do |item, i|
      cursor  = @cursor == i ? ">" : " "
      checked = @selected[i] ? "x" : " "
      lines << "#{cursor} [#{checked}] #{item}"
    end
    lines << "\n\nSpace/Enter to select, q to quit"
    lines.join("\n")
  end
end

Chamomile.run(ItemList.new)
