# frozen_string_literal: true

module Chamomile
  BorderDef = Data.define(
    :top, :bottom, :left, :right,
    :top_left, :top_right, :bottom_left, :bottom_right,
    :middle_left, :middle_right, :middle, :middle_top, :middle_bottom
  )

  module Border
    NORMAL = BorderDef.new(
      top: "─", bottom: "─", left: "│", right: "│",
      top_left: "┌", top_right: "┐", bottom_left: "└", bottom_right: "┘",
      middle_left: "├", middle_right: "┤", middle: "┼", middle_top: "┬", middle_bottom: "┴"
    ).freeze

    ROUNDED = BorderDef.new(
      top: "─", bottom: "─", left: "│", right: "│",
      top_left: "╭", top_right: "╮", bottom_left: "╰", bottom_right: "╯",
      middle_left: "├", middle_right: "┤", middle: "┼", middle_top: "┬", middle_bottom: "┴"
    ).freeze

    THICK = BorderDef.new(
      top: "━", bottom: "━", left: "┃", right: "┃",
      top_left: "┏", top_right: "┓", bottom_left: "┗", bottom_right: "┛",
      middle_left: "┣", middle_right: "┫", middle: "╋", middle_top: "┳", middle_bottom: "┻"
    ).freeze

    DOUBLE = BorderDef.new(
      top: "═", bottom: "═", left: "║", right: "║",
      top_left: "╔", top_right: "╗", bottom_left: "╚", bottom_right: "╝",
      middle_left: "╠", middle_right: "╣", middle: "╬", middle_top: "╦", middle_bottom: "╩"
    ).freeze

    BLOCK = BorderDef.new(
      top: "█", bottom: "█", left: "█", right: "█",
      top_left: "█", top_right: "█", bottom_left: "█", bottom_right: "█",
      middle_left: "█", middle_right: "█", middle: "█", middle_top: "█", middle_bottom: "█"
    ).freeze

    OUTER_HALF_BLOCK = BorderDef.new(
      top: "▀", bottom: "▄", left: "▌", right: "▐",
      top_left: "▛", top_right: "▜", bottom_left: "▙", bottom_right: "▟",
      middle_left: "▌", middle_right: "▐", middle: "┼", middle_top: "▀", middle_bottom: "▄"
    ).freeze

    INNER_HALF_BLOCK = BorderDef.new(
      top: "▄", bottom: "▀", left: "▐", right: "▌",
      top_left: "▗", top_right: "▖", bottom_left: "▝", bottom_right: "▘",
      middle_left: "▐", middle_right: "▌", middle: "┼", middle_top: "▄", middle_bottom: "▀"
    ).freeze

    HIDDEN = BorderDef.new(
      top: " ", bottom: " ", left: " ", right: " ",
      top_left: " ", top_right: " ", bottom_left: " ", bottom_right: " ",
      middle_left: " ", middle_right: " ", middle: " ", middle_top: " ", middle_bottom: " "
    ).freeze

    ASCII = BorderDef.new(
      top: "-", bottom: "-", left: "|", right: "|",
      top_left: "+", top_right: "+", bottom_left: "+", bottom_right: "+",
      middle_left: "+", middle_right: "+", middle: "+", middle_top: "+", middle_bottom: "+"
    ).freeze

    MARKDOWN = ASCII
  end
end
