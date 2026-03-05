# frozen_string_literal: true

RSpec.describe Chamomile::Router do
  def key_msg(key, mod: [])
    Chamomile::KeyMsg.new(key: key, mod: mod)
  end

  it "routes key events to the panel's declared keymap" do
    panel_class = Class.new do
      include Chamomile::Router

      attr_accessor :started

      def initialize
        @started = false
      end

      keymap do |km|
        km.bind("s") { @started = true; nil }
      end
    end

    panel = panel_class.new
    panel.handle_panel_key(key_msg("s"))
    expect(panel.started).to be true
  end

  it "returns nil when no keymap is defined" do
    panel_class = Class.new do
      include Chamomile::Router
    end

    panel = panel_class.new
    expect(panel.handle_panel_key(key_msg("s"))).to be_nil
  end

  it "returns nil when no key matches" do
    panel_class = Class.new do
      include Chamomile::Router

      keymap do |km|
        km.bind("s") { :start }
      end
    end

    panel = panel_class.new
    expect(panel.handle_panel_key(key_msg("x"))).to be_nil
  end

  it "returns the action result" do
    panel_class = Class.new do
      include Chamomile::Router
      include Chamomile::Commands

      keymap do |km|
        km.bind("q") { quit }
      end
    end

    panel = panel_class.new
    result = panel.handle_panel_key(key_msg("q"))
    expect(result).to be_a(Proc)
    expect(result.call).to be_a(Chamomile::QuitMsg)
  end

  it "supports multiple bindings" do
    panel_class = Class.new do
      include Chamomile::Router

      attr_accessor :action

      keymap do |km|
        km.bind("s") { @action = :start; nil }
        km.bind("S") { @action = :stop; nil }
      end
    end

    panel = panel_class.new
    panel.handle_panel_key(key_msg("s"))
    expect(panel.action).to eq(:start)
    panel.handle_panel_key(key_msg("S"))
    expect(panel.action).to eq(:stop)
  end
end
