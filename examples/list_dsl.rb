# frozen_string_literal: true

# Item List — DSL style
# Run: ruby examples/list_dsl.rb
# Compare: examples/list_explicit.rb

require_relative "../lib/chamomile"
require "flourish"

class ItemList
  include Chamomile::Application

  ITEMS = %w[Apples Bananas Cherries Dates Elderberries].freeze

  def initialize
    @cursor   = 0
    @selected = {}
  end

  on_key(:up, "k")   { @cursor = [@cursor - 1, 0].max }
  on_key(:down, "j") { @cursor = [@cursor + 1, ITEMS.size - 1].min }
  on_key(" ", :enter) {
    if @selected[@cursor]
      @selected.delete(@cursor)
    else
      @selected[@cursor] = true
    end
  }
  on_key("q") { quit }

  def view
    items = ITEMS.each_with_index.map do |item, i|
      cursor  = @cursor == i ? ">" : " "
      checked = @selected[i] ? "x" : " "
      "#{cursor} [#{checked}] #{item}"
    end

    vertical(align: :left) do
      text "Pick some items:", bold: true
      text ""
      items.each { |line| text line }
      text ""
      status_bar "Space/Enter to select, q to quit"
    end
  end
end

Chamomile.run(ItemList.new)
