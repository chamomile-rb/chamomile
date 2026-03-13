# frozen_string_literal: true

# Item List — explicit Chamomile style
# Run: ruby examples/list_explicit.rb
# Compare: examples/list_dsl.rb

require_relative "../lib/chamomile"
# (styling is included in chamomile)

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
    header = Chamomile::Style.new.bold.render("Pick some items:")
    items = ITEMS.each_with_index.map do |item, i|
      cursor  = @cursor == i ? ">" : " "
      checked = @selected[i] ? "x" : " "
      "#{cursor} [#{checked}] #{item}"
    end
    bar = Chamomile::Style.new.foreground("#666666").render("Space/Enter to select, q to quit")
    Chamomile.vertical([header, "", *items, "", bar], align: :left)
  end
end

Chamomile.run(ItemList.new)
