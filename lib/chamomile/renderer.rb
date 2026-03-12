# frozen_string_literal: true

module Chamomile
  # FPS-throttled terminal renderer with alt-screen diff, inline, and full modes.
  class Renderer
    HIDE_CURSOR    = "\e[?25l"
    SHOW_CURSOR    = "\e[?25h"
    ALT_SCREEN_ON  = "\e[?1049h"
    ALT_SCREEN_OFF = "\e[?1049l"
    CLEAR_SCREEN   = "\e[H\e[2J"
    CURSOR_HOME    = "\e[H"
    SYNC_START     = "\e[?2026h"
    SYNC_END       = "\e[?2026l"

    attr_reader :width, :height

    def initialize(output: $stdout, fps: 60)
      @output       = output
      @alt_screen   = false
      @inline       = false
      @width        = 80
      @height       = 24
      @prev_lines   = []
      @inline_lines = 0
      @mutex        = Mutex.new
      @fps          = fps
      @min_interval = fps.positive? ? 1.0 / fps : 0
      @last_render  = 0.0
      @pending_view = nil
      @timer_thread = nil
    end

    def enter_alt_screen
      @output.write(ALT_SCREEN_ON)
      @alt_screen = true
      @inline = false
    end

    def exit_alt_screen
      @output.write(ALT_SCREEN_OFF)
      @alt_screen = false
    end

    def enter_inline_mode
      @inline = true
      @inline_lines = 0
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

    def render(view_output)
      view_string = resolve_view(view_output)
      @mutex.synchronize do
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        elapsed = now - @last_render

        if elapsed >= @min_interval
          flush_render(view_string)
          @last_render = now
          @pending_view = nil
          cancel_timer
        else
          @pending_view = view_string
          schedule_timer(@min_interval - elapsed)
        end
      end
    end

    def clear
      @output.write(CLEAR_SCREEN)
      @output.flush
    end

    def println(str)
      @output.puts(str)
    end

    # Print a line above the rendered area (for inline mode logging, etc.)
    def println_above(str)
      @mutex.synchronize do
        if @inline && @inline_lines.positive?
          buf = +""
          buf << "\e[#{@inline_lines}A" # Move up
          buf << "\e[L" # Insert line
          buf << str
          buf << "\n"
          buf << "\e[#{@inline_lines}B" # Move back down
          @output.write(buf)
          @output.flush
        else
          @output.puts(str)
        end
      end
    end

    def move_cursor(row, col)
      @output.write("\e[#{row};#{col}H")
    end

    def apply_cursor_shape(shape)
      code = case shape
             when :block          then 2
             when :underline      then 4
             when :bar            then 6
             when :blinking_block then 1
             when :blinking_underline then 3
             when :blinking_bar then 5
             else 0 # default
             end
      @output.write("\e[#{code} q")
    end

    def write_window_title(title)
      @output.write("\e]2;#{title}\a")
    end

    # Force an immediate render, bypassing FPS throttle
    def force_render(view_output)
      view_string = resolve_view(view_output)
      @mutex.synchronize do
        flush_render(view_string)
        @last_render = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @pending_view = nil
        cancel_timer
      end
    end

    def stop
      @mutex.synchronize do
        cancel_timer
      end
    end

    private

    def flush_render(view_string)
      if @inline
        render_inline(view_string)
      elsif @alt_screen
        render_diff(view_string)
      else
        render_full(view_string)
      end
    end

    def render_full(view_string)
      buf = +""
      buf << SYNC_START
      buf << CURSOR_HOME << CLEAR_SCREEN << view_string
      buf << SYNC_END
      @output.write(buf)
      @output.flush
    end

    def render_diff(view_string)
      new_lines = view_string.split("\n", -1)
      buf = +""
      buf << SYNC_START

      max = [new_lines.length, @prev_lines.length].max
      max.times do |i|
        new_line = new_lines[i] || ""
        old_line = @prev_lines[i] || ""

        next if new_line == old_line

        buf << "\e[#{i + 1};1H"  # Move to row
        buf << "\e[K"            # Clear line
        buf << new_line
      end

      # Clear any extra lines from previous render
      if new_lines.length < @prev_lines.length
        (new_lines.length...@prev_lines.length).each do |i|
          buf << "\e[#{i + 1};1H\e[K"
        end
      end

      buf << SYNC_END
      @output.write(buf)
      @output.flush
      @prev_lines = new_lines
    end

    def render_inline(view_string)
      new_lines = view_string.split("\n", -1)
      buf = +""
      buf << SYNC_START

      # Move cursor up to overwrite previous output
      if @inline_lines.positive?
        buf << "\e[#{@inline_lines}A"
        buf << "\r"
      end

      new_lines.each_with_index do |line, i|
        buf << "\e[K" # Clear line
        buf << line
        buf << "\n" if i < new_lines.length - 1
      end

      # Clear leftover lines from previous render
      if new_lines.length < @inline_lines
        (@inline_lines - new_lines.length).times do
          buf << "\n\e[K"
        end
        # Move back up
        extra = @inline_lines - new_lines.length
        buf << "\e[#{extra}A" if extra.positive?
      end

      buf << SYNC_END
      @output.write(buf)
      @output.flush
      @inline_lines = new_lines.length
    end

    def schedule_timer(delay)
      cancel_timer
      @timer_thread = Thread.new do
        sleep(delay)
        @mutex.synchronize do
          if @pending_view
            flush_render(@pending_view)
            @last_render = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            @pending_view = nil
          end
        end
      end
    end

    def cancel_timer
      return unless @timer_thread

      @timer_thread.kill if @timer_thread.alive?
      @timer_thread = nil
    end

    # If the view returned a Frame object, render it; otherwise treat as string.
    def resolve_view(view_output)
      if view_output.respond_to?(:render) && !view_output.is_a?(String)
        view_output.render(width: @width, height: @height)
      else
        view_output.to_s
      end
    end
  end
end
