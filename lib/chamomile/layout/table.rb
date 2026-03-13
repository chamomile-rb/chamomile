# frozen_string_literal: true

module Chamomile
  module Layout
    class Table < Base
      def initialize(data, columns: nil, height: nil)
        @data    = data
        @columns = columns
        @height  = height
      end

      def render(width:, height:)
        if @data.is_a?(Chamomile::Table)
          @data.view
        else
          table = build_table(width)
          table.view
        end
      end

      private

      def build_table(available_width)
        cols = @columns || auto_columns(available_width)
        Chamomile::Table.new(rows: @data) do |t|
          cols.each { |c| t.column c[:title], width: c[:width] }
        end
      end

      def auto_columns(available_width)
        return [] if @data.empty? || @data.first.empty?
        col_count  = @data.first.size
        col_width  = [available_width / col_count, 8].max
        col_count.times.map { |i| { title: "col#{i + 1}", width: col_width } }
      end
    end
  end
end
