# frozen_string_literal: true

require "spec_helper"

RSpec.describe Chamomile::Configuration do
  describe "defaults" do
    it "has sensible defaults" do
      config = described_class.new
      expect(config.alt_screen).to be true
      expect(config.mouse).to eq(:none)
      expect(config.bracketed_paste).to be true
      expect(config.report_focus).to be false
      expect(config.fps).to eq(60)
      expect(config.catch_panics).to be true
    end
  end

  describe "#to_h" do
    it "returns a hash of all settings" do
      config = described_class.new
      config.mouse = :cell_motion
      config.fps = 30
      h = config.to_h
      expect(h[:mouse]).to eq(:cell_motion)
      expect(h[:fps]).to eq(30)
      expect(h[:alt_screen]).to be true
    end
  end

  describe "Chamomile.run block config" do
    it "block form sets config values" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def view; ""; end
        def start; quit; end
      end.new

      # We can't easily test the full run loop, but we can verify
      # the block is called and config is passed through
      config_received = nil
      allow(Chamomile::Program).to receive(:new) do |_model, **opts|
        config_received = opts
        instance_double(Chamomile::Program, run: model)
      end

      Chamomile.run(model) do |c|
        c.alt_screen = false
        c.mouse = :all_motion
        c.fps = 30
      end

      expect(config_received[:alt_screen]).to be false
      expect(config_received[:mouse]).to eq(:all_motion)
      expect(config_received[:fps]).to eq(30)
    end

    it "kwargs override block config" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def view; ""; end
        def start; quit; end
      end.new

      config_received = nil
      allow(Chamomile::Program).to receive(:new) do |_model, **opts|
        config_received = opts
        instance_double(Chamomile::Program, run: model)
      end

      Chamomile.run(model, fps: 120) do |c|
        c.fps = 30
      end

      expect(config_received[:fps]).to eq(120)
    end

    it "old keyword form still works" do
      model = Class.new do
        include Chamomile::Model
        include Chamomile::Commands
        def view; ""; end
        def start; quit; end
      end.new

      config_received = nil
      allow(Chamomile::Program).to receive(:new) do |_model, **opts|
        config_received = opts
        instance_double(Chamomile::Program, run: model)
      end

      Chamomile.run(model, alt_screen: false, fps: 15)
      expect(config_received[:alt_screen]).to be false
      expect(config_received[:fps]).to eq(15)
    end
  end
end
