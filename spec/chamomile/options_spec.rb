# frozen_string_literal: true

RSpec.describe Chamomile::Options do
  describe ".default" do
    it "creates options with default values" do
      opts = described_class.default
      expect(opts.alt_screen).to be true
      expect(opts.mouse).to eq(:none)
      expect(opts.report_focus).to be false
      expect(opts.bracketed_paste).to be true
      expect(opts.fps).to eq(60)
      expect(opts.input).to eq($stdin)
      expect(opts.output).to eq($stdout)
      expect(opts.filter).to be_nil
      expect(opts.catch_panics).to be true
      expect(opts.handle_signals).to be true
    end

    it "allows overrides" do
      opts = described_class.default(
        alt_screen: false,
        mouse: :all_motion,
        fps: 30,
        report_focus: true
      )
      expect(opts.alt_screen).to be false
      expect(opts.mouse).to eq(:all_motion)
      expect(opts.fps).to eq(30)
      expect(opts.report_focus).to be true
      # Defaults preserved
      expect(opts.bracketed_paste).to be true
      expect(opts.catch_panics).to be true
    end

    it "accepts a filter proc" do
      filter = ->(_model, msg) { msg }
      opts = described_class.default(filter: filter)
      expect(opts.filter).to eq(filter)
    end

    it "accepts cell_motion mouse mode" do
      opts = described_class.default(mouse: :cell_motion)
      expect(opts.mouse).to eq(:cell_motion)
    end

    it "accepts fps: 0 for unlimited rendering" do
      opts = described_class.default(fps: 0)
      expect(opts.fps).to eq(0)
    end
  end

  describe "validation" do
    it "rejects invalid mouse mode" do
      expect do
        described_class.default(mouse: :invalid)
      end.to raise_error(ArgumentError, /invalid mouse mode/)
    end

    it "rejects negative fps" do
      expect do
        described_class.default(fps: -1)
      end.to raise_error(ArgumentError, /fps must be a non-negative number/)
    end

    it "rejects non-numeric fps" do
      expect do
        described_class.default(fps: "fast")
      end.to raise_error(ArgumentError, /fps must be a non-negative number/)
    end

    it "rejects non-callable filter" do
      expect do
        described_class.default(filter: "not a proc")
      end.to raise_error(ArgumentError, /filter must respond to #call/)
    end

    it "accepts nil filter" do
      expect { described_class.default(filter: nil) }.not_to raise_error
    end
  end

  it "is immutable" do
    opts = described_class.default
    expect(opts).to be_frozen
  end
end
