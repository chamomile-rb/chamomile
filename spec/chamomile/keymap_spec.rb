# frozen_string_literal: true

RSpec.describe Chamomile::Keymap do
  let(:model) do
    Class.new do
      include Chamomile::Model
      include Chamomile::Commands

      attr_accessor :value

      def initialize
        @value = 0
      end

      def update(_msg) = nil
      def view = "value: #{@value}"
    end.new
  end

  def key_msg(key, mod: [])
    Chamomile::KeyMsg.new(key: key, mod: mod)
  end

  describe "#bind" do
    it "matches a string key" do
      km = described_class.new.bind("q") { @value = 42 }
      km.handle(key_msg("q"), model)
      expect(model.value).to eq(42)
    end

    it "matches a symbol key" do
      km = described_class.new.bind(:tab) { @value = 99 }
      km.handle(key_msg(:tab), model)
      expect(model.value).to eq(99)
    end

    it "matches an array of keys" do
      km = described_class.new.bind(["j", :down]) { @value += 1 }
      km.handle(key_msg("j"), model)
      expect(model.value).to eq(1)
      km.handle(key_msg(:down), model)
      expect(model.value).to eq(2)
    end

    it "returns the result of the action block" do
      km = described_class.new.bind("q") { quit }
      result = km.handle(key_msg("q"), model)
      expect(result).to be_a(Proc)
      expect(result.call).to be_a(Chamomile::QuitMsg)
    end

    it "returns nil when no key matches" do
      km = described_class.new.bind("q") { @value = 42 }
      result = km.handle(key_msg("x"), model)
      expect(result).to be_nil
    end

    it "returns nil for non-KeyMsg" do
      km = described_class.new.bind("q") { @value = 42 }
      result = km.handle(Chamomile::TickMsg.new(time: Time.now), model)
      expect(result).to be_nil
    end

    it "supports chaining" do
      km = described_class.new
              .bind("j") { @value += 1 }
              .bind("k") { @value -= 1 }

      km.handle(key_msg("j"), model)
      expect(model.value).to eq(1)
      km.handle(key_msg("k"), model)
      expect(model.value).to eq(0)
    end
  end

  describe "#bind with guard" do
    it "skips binding when guard returns false" do
      guard = ->(_m) { false }
      km = described_class.new.bind("q", guard: guard) { @value = 42 }
      result = km.handle(key_msg("q"), model)
      expect(result).to be_nil
      expect(model.value).to eq(0)
    end

    it "fires binding when guard returns true" do
      guard = ->(_m) { true }
      km = described_class.new.bind("q", guard: guard) { @value = 42 }
      km.handle(key_msg("q"), model)
      expect(model.value).to eq(42)
    end
  end

  describe "#only" do
    it "applies guard to all bindings in the block" do
      km = described_class.new
              .only(->(m) { m.value < 5 }) do |sub|
                sub.bind("j") { @value += 1 }
              end

      5.times { km.handle(key_msg("j"), model) }
      expect(model.value).to eq(5)

      # Guard should now prevent further increments
      km.handle(key_msg("j"), model)
      expect(model.value).to eq(5)
    end

    it "combines nested guards" do
      km = described_class.new
              .only(->(m) { m.value < 10 }) do |sub|
                sub.bind("j", guard: ->(m) { m.value.even? }) { @value += 1 }
              end

      km.handle(key_msg("j"), model) # value=0 (even) -> 1
      expect(model.value).to eq(1)

      km.handle(key_msg("j"), model) # value=1 (odd) -> no match
      expect(model.value).to eq(1)
    end

    it "returns self for chaining" do
      km = described_class.new
      result = km.only(->(_m) { true }) { |sub| sub.bind("q") { nil } }
      expect(result).to eq(km)
    end
  end

  describe "first match wins" do
    it "uses the first matching binding" do
      km = described_class.new
              .bind("q") { @value = 1 }
              .bind("q") { @value = 2 }

      km.handle(key_msg("q"), model)
      expect(model.value).to eq(1)
    end
  end
end
