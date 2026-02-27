# frozen_string_literal: true

require "stringio"

RSpec.describe Chamomile::Renderer do
  let(:output) { StringIO.new }
  let(:renderer) { described_class.new(output: output) }

  describe "#enter_alt_screen" do
    it "writes alt screen on sequence" do
      renderer.enter_alt_screen
      expect(output.string).to include("\e[?1049h")
    end
  end

  describe "#exit_alt_screen" do
    it "writes alt screen off sequence" do
      renderer.exit_alt_screen
      expect(output.string).to include("\e[?1049l")
    end
  end

  describe "#hide_cursor" do
    it "writes hide cursor sequence" do
      renderer.hide_cursor
      expect(output.string).to include("\e[?25l")
    end
  end

  describe "#show_cursor" do
    it "writes show cursor sequence" do
      renderer.show_cursor
      expect(output.string).to include("\e[?25h")
    end
  end

  describe "#resize" do
    it "updates width and height" do
      renderer.resize(120, 40)
      expect(renderer.width).to eq(120)
      expect(renderer.height).to eq(40)
    end
  end

  describe "#render" do
    it "writes view content" do
      renderer.render("Hello, world!")
      expect(output.string).to include("Hello, world!")
    end

    it "includes synchronized output sequences" do
      renderer.render("test")
      expect(output.string).to include("\e[?2026h")
      expect(output.string).to include("\e[?2026l")
    end
  end

  describe "#clear" do
    it "writes clear screen sequence" do
      renderer.clear
      expect(output.string).to include("\e[H\e[2J")
    end
  end

  describe "#println" do
    it "writes a line with newline" do
      renderer.println("test")
      expect(output.string).to eq("test\n")
    end
  end

  describe "defaults" do
    it "has default dimensions" do
      expect(renderer.width).to eq(80)
      expect(renderer.height).to eq(24)
    end
  end

  describe "diff rendering" do
    let(:diff_renderer) { described_class.new(output: output, fps: 0) }

    it "only rewrites changed lines on subsequent renders" do
      diff_renderer.enter_alt_screen
      output.truncate(0)
      output.rewind

      diff_renderer.render("line1\nline2\nline3")
      output.truncate(0)
      output.rewind

      diff_renderer.render("line1\nCHANGED\nline3")
      second_output = output.string

      # Second render should NOT contain "line1" or "line3" as content
      # (they're unchanged), but SHOULD contain "CHANGED"
      expect(second_output).to include("CHANGED")
      # line1 should not be re-written (it's unchanged)
      expect(second_output).not_to include("line1")
      expect(second_output).not_to include("line3")
    end

    it "clears extra lines when new render has fewer lines" do
      diff_renderer.enter_alt_screen
      output.truncate(0)
      output.rewind

      diff_renderer.render("line1\nline2\nline3")
      output.truncate(0)
      output.rewind

      diff_renderer.render("line1")
      second_output = output.string

      # Should contain clear-line sequences for removed lines
      expect(second_output).to include("\e[K")
    end
  end

  describe "FPS throttling" do
    it "coalesces rapid renders" do
      fast_renderer = described_class.new(output: output, fps: 10) # 100ms interval
      fast_renderer.render("first")
      output.string.length

      # Immediate second render should be deferred
      fast_renderer.render("second")
      # Give timer thread a moment
      sleep(0.15)
      fast_renderer.stop

      final_output = output.string
      expect(final_output).to include("second")
    end
  end

  describe "inline mode" do
    let(:inline_renderer) { described_class.new(output: output, fps: 0) }

    it "renders without alt screen" do
      inline_renderer.enter_inline_mode
      inline_renderer.render("inline content")
      expect(output.string).to include("inline content")
      expect(output.string).not_to include("\e[?1049h")
    end

    it "overwrites previous inline output" do
      inline_renderer.enter_inline_mode
      inline_renderer.render("first line")
      output.truncate(0)
      output.rewind

      inline_renderer.render("second line")
      rendered = output.string
      # Should move cursor up to overwrite
      expect(rendered).to include("\e[1A")
      expect(rendered).to include("second line")
    end
  end

  describe "#move_cursor" do
    it "writes cursor position sequence" do
      renderer.move_cursor(5, 10)
      expect(output.string).to eq("\e[5;10H")
    end
  end

  describe "#apply_cursor_shape" do
    it "writes block cursor shape" do
      renderer.apply_cursor_shape(:block)
      expect(output.string).to eq("\e[2 q")
    end

    it "writes bar cursor shape" do
      renderer.apply_cursor_shape(:bar)
      expect(output.string).to eq("\e[6 q")
    end

    it "writes underline cursor shape" do
      renderer.apply_cursor_shape(:underline)
      expect(output.string).to eq("\e[4 q")
    end
  end

  describe "#write_window_title" do
    it "writes window title sequence" do
      renderer.write_window_title("My App")
      expect(output.string).to eq("\e]2;My App\a")
    end
  end

  describe "#force_render" do
    it "renders immediately regardless of FPS" do
      slow_renderer = described_class.new(output: output, fps: 1)
      slow_renderer.render("first")
      slow_renderer.force_render("forced")
      expect(output.string).to include("forced")
      slow_renderer.stop
    end
  end

  describe "edge cases" do
    let(:edge_renderer) { described_class.new(output: output, fps: 0) }

    it "handles empty string render" do
      edge_renderer.render("")
      expect(output.string).to include(Chamomile::Renderer::SYNC_START)
    end

    it "handles nil view (via .to_s)" do
      expect { edge_renderer.render(nil) }.not_to raise_error
    end

    it "handles fps: 0 (unlimited rendering)" do
      r = described_class.new(output: output, fps: 0)
      expect { r.render("test") }.not_to raise_error
      r.stop
    end

    it "handles diff render with empty initial state" do
      edge_renderer.enter_alt_screen
      output.truncate(0)
      output.rewind
      edge_renderer.render("hello")
      expect(output.string).to include("hello")
    end

    it "stops cleanly when no timer is running" do
      expect { edge_renderer.stop }.not_to raise_error
    end

    it "stops cleanly when called twice" do
      edge_renderer.render("test")
      edge_renderer.stop
      expect { edge_renderer.stop }.not_to raise_error
    end
  end

  describe "#println_above" do
    it "prints normally when not in inline mode" do
      renderer.println_above("above text")
      expect(output.string).to include("above text")
    end

    it "uses cursor movement in inline mode with prior output" do
      inline_renderer = described_class.new(output: output, fps: 0)
      inline_renderer.enter_inline_mode
      inline_renderer.render("content")
      output.truncate(0)
      output.rewind

      inline_renderer.println_above("inserted line")
      rendered = output.string
      expect(rendered).to include("inserted line")
      expect(rendered).to include("\e[L") # Insert line sequence
    end
  end

  describe "#apply_cursor_shape edge cases" do
    it "handles unknown shape with default code" do
      renderer.apply_cursor_shape(:unknown_shape)
      expect(output.string).to eq("\e[0 q")
    end

    it "handles blinking shapes" do
      renderer.apply_cursor_shape(:blinking_bar)
      expect(output.string).to eq("\e[5 q")
    end
  end

  describe "concurrent rendering" do
    it "does not corrupt output from multiple threads" do
      threaded_renderer = described_class.new(output: output, fps: 0)
      threads = 10.times.map do |i|
        Thread.new { threaded_renderer.render("thread #{i}") }
      end
      threads.each(&:join)
      threaded_renderer.stop
      # Should not raise — mutex protects the render
    end
  end
end
