# frozen_string_literal: true

require_relative "../lib/chamomile"

class ItemList
  include Chamomile::Application

  ITEMS = %w[Apples Bananas Cherries Dates Elderberries].freeze

  def initialize
    @cursor   = 0
    @selected = {}
  end

  on_key(:up, "k")   { @cursor = [@cursor - 1, 0].max }
  on_key(:down, "j") { @cursor = [@cursor + 1, ITEMS.size - 1].min }
  on_key(" ", :enter) do
    if @selected[@cursor]
      @selected.delete(@cursor)
    else
      @selected[@cursor] = true
    end
  end
  on_key("q") { quit }

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
