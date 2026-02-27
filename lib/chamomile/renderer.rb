module Chamomile
  class Renderer
    HIDE_CURSOR    = "\e[?25l"
    SHOW_CURSOR    = "\e[?25h"
    ALT_SCREEN_ON  = "\e[?1049h"
    ALT_SCREEN_OFF = "\e[?1049l"
    CLEAR_SCREEN   = "\e[H\e[2J"
    CURSOR_HOME    = "\e[H"

    attr_reader :width, :height

    def initialize(output: $stdout)
      @output     = output
      @alt_screen = false
      @width      = 80
      @height     = 24
    end

    def enter_alt_screen
      @output.write(ALT_SCREEN_ON)
      @alt_screen = true
    end

    def exit_alt_screen
      @output.write(ALT_SCREEN_OFF)
      @alt_screen = false
    end

    def hide_cursor
      @output.write(HIDE_CURSOR)
    end

    def show_cursor
      @output.write(SHOW_CURSOR)
    end

    def resize(width, height)
      @width  = width
      @height = height
    end

    def render(view_string)
      @output.write(CURSOR_HOME + CLEAR_SCREEN + view_string.to_s)
      @output.flush
    end

    def clear
      @output.write(CLEAR_SCREEN)
      @output.flush
    end

    def println(str)
      @output.puts(str)
    end
  end
end
