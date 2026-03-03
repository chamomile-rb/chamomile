# frozen_string_literal: true

RSpec.describe Chamomile::Commands do
  include Chamomile::Commands

  describe "#quit" do
    it "returns a lambda that produces QuitMsg" do
      cmd = quit
      expect(cmd).to be_a(Proc)
      expect(cmd.call).to be_a(Chamomile::QuitMsg)
    end
  end

  describe "#none" do
    it "returns nil" do
      expect(none).to be_nil
    end
  end

  describe "#batch" do
    it "returns a lambda that produces an Array of commands" do
      c1 = -> { :a }
      c2 = -> { :b }
      cmd = batch(c1, c2)
      result = cmd.call
      expect(result).to be_an(Array)
      expect(result).to eq([c1, c2])
    end

    it "returns nil for empty batch" do
      expect(batch).to be_nil
      expect(batch(nil, nil)).to be_nil
    end

    it "filters out nils" do
      c1 = -> { :a }
      cmd = batch(c1, nil)
      result = cmd.call
      expect(result).to eq([c1])
    end
  end

  describe "#sequence" do
    it "returns a lambda that produces a tagged array [:sequence, ...]" do
      c1 = -> { :a }
      c2 = -> { :b }
      cmd = sequence(c1, c2)
      result = cmd.call
      expect(result).to be_an(Array)
      expect(result[0]).to eq(:sequence)
      expect(result[1..]).to eq([c1, c2])
    end

    it "returns nil for empty sequence" do
      expect(sequence).to be_nil
    end
  end

  describe "#tick" do
    it "returns a lambda that sleeps and produces TickMsg" do
      cmd = tick(0.01)
      result = cmd.call
      expect(result).to be_a(Chamomile::TickMsg)
      expect(result.time).to be_a(Time)
    end

    it "uses custom block if given" do
      custom_msg = Chamomile::KeyMsg.new(key: "x", mod: [])
      cmd = tick(0.01) { custom_msg }
      expect(cmd.call).to eq(custom_msg)
    end

    it "actually sleeps for the specified duration" do
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      tick(0.05).call
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      expect(elapsed).to be >= 0.04
    end

    it "handles zero duration" do
      result = tick(0).call
      expect(result).to be_a(Chamomile::TickMsg)
    end
  end

  describe "#every" do
    it "returns a lambda that produces TickMsg" do
      cmd = every(0.01)
      result = cmd.call
      expect(result).to be_a(Chamomile::TickMsg)
      expect(result.time).to be_a(Time)
    end

    it "uses custom block if given" do
      custom_msg = Chamomile::KeyMsg.new(key: "x", mod: [])
      cmd = every(0.01) { custom_msg }
      expect(cmd.call).to eq(custom_msg)
    end

    it "aligns to interval boundaries" do
      # every(1.0) should wait until the next whole second boundary
      cmd = every(0.05)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      cmd.call
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      # Should sleep at most the interval duration
      expect(elapsed).to be <= 0.06
    end
  end

  describe "#cmd" do
    it "wraps a callable" do
      result_msg = Chamomile::QuitMsg.new
      c = cmd(-> { result_msg })
      expect(c.call).to eq(result_msg)
    end
  end

  describe "#window_title" do
    it "returns a lambda that produces WindowTitleCmd" do
      cmd = window_title("My App")
      result = cmd.call
      expect(result).to be_a(Chamomile::WindowTitleCmd)
      expect(result.title).to eq("My App")
    end
  end

  describe "#cursor_position" do
    it "returns a lambda that produces CursorPositionCmd" do
      cmd = cursor_position(5, 10)
      result = cmd.call
      expect(result).to be_a(Chamomile::CursorPositionCmd)
      expect(result.row).to eq(5)
      expect(result.col).to eq(10)
    end
  end

  describe "#cursor_shape" do
    it "returns a lambda that produces CursorShapeCmd" do
      cmd = cursor_shape(:bar)
      result = cmd.call
      expect(result).to be_a(Chamomile::CursorShapeCmd)
      expect(result.shape).to eq(:bar)
    end
  end

  describe "#show_cursor" do
    it "returns a lambda that produces CursorVisibilityCmd with visible: true" do
      cmd = show_cursor
      result = cmd.call
      expect(result).to be_a(Chamomile::CursorVisibilityCmd)
      expect(result.visible).to be true
    end
  end

  describe "#hide_cursor" do
    it "returns a lambda that produces CursorVisibilityCmd with visible: false" do
      cmd = hide_cursor
      result = cmd.call
      expect(result).to be_a(Chamomile::CursorVisibilityCmd)
      expect(result.visible).to be false
    end
  end

  describe "#exec" do
    it "returns a lambda that produces ExecCmd" do
      cmd = exec("vim", "file.txt")
      result = cmd.call
      expect(result).to be_a(Chamomile::ExecCmd)
      expect(result.command).to eq("vim")
      expect(result.args).to eq(["file.txt"])
    end

    it "accepts a callback block" do
      callback_result = nil
      cmd = exec("echo", "test") do |success|
        callback_result = success
        nil
      end
      result = cmd.call
      expect(result.callback).to be_a(Proc)
    end

    it "has nil callback when no block given" do
      result = exec("echo").call
      expect(result.callback).to be_nil
    end
  end

  describe "#println" do
    it "returns a lambda that produces PrintlnCmd" do
      cmd = println("hello")
      result = cmd.call
      expect(result).to be_a(Chamomile::PrintlnCmd)
      expect(result.text).to eq("hello")
    end
  end

  describe "runtime mode toggles" do
    it "#enter_alt_screen returns EnterAltScreenMsg" do
      expect(enter_alt_screen.call).to be_a(Chamomile::EnterAltScreenMsg)
    end

    it "#exit_alt_screen returns ExitAltScreenMsg" do
      expect(exit_alt_screen.call).to be_a(Chamomile::ExitAltScreenMsg)
    end

    it "#enable_mouse_cell_motion returns EnableMouseCellMotionMsg" do
      expect(enable_mouse_cell_motion.call).to be_a(Chamomile::EnableMouseCellMotionMsg)
    end

    it "#enable_mouse_all_motion returns EnableMouseAllMotionMsg" do
      expect(enable_mouse_all_motion.call).to be_a(Chamomile::EnableMouseAllMotionMsg)
    end

    it "#disable_mouse returns DisableMouseMsg" do
      expect(disable_mouse.call).to be_a(Chamomile::DisableMouseMsg)
    end

    it "#enable_bracketed_paste returns EnableBracketedPasteMsg" do
      expect(enable_bracketed_paste.call).to be_a(Chamomile::EnableBracketedPasteMsg)
    end

    it "#disable_bracketed_paste returns DisableBracketedPasteMsg" do
      expect(disable_bracketed_paste.call).to be_a(Chamomile::DisableBracketedPasteMsg)
    end

    it "#enable_report_focus returns EnableReportFocusMsg" do
      expect(enable_report_focus.call).to be_a(Chamomile::EnableReportFocusMsg)
    end

    it "#disable_report_focus returns DisableReportFocusMsg" do
      expect(disable_report_focus.call).to be_a(Chamomile::DisableReportFocusMsg)
    end

    it "#clear_screen returns ClearScreenMsg" do
      expect(clear_screen.call).to be_a(Chamomile::ClearScreenMsg)
    end

    it "#request_window_size returns RequestWindowSizeMsg" do
      expect(request_window_size.call).to be_a(Chamomile::RequestWindowSizeMsg)
    end
  end
end
