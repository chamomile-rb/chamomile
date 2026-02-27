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
    it "returns a lambda that produces BatchCmd" do
      c1 = -> { :a }
      c2 = -> { :b }
      cmd = batch(c1, c2)
      result = cmd.call
      expect(result).to be_a(Chamomile::BatchCmd)
      expect(result.cmds).to eq([c1, c2])
    end

    it "returns nil for empty batch" do
      expect(batch).to be_nil
      expect(batch(nil, nil)).to be_nil
    end

    it "filters out nils" do
      c1 = -> { :a }
      cmd = batch(c1, nil)
      result = cmd.call
      expect(result.cmds).to eq([c1])
    end
  end

  describe "#sequence" do
    it "returns a lambda that produces SequenceCmd" do
      c1 = -> { :a }
      c2 = -> { :b }
      cmd = sequence(c1, c2)
      result = cmd.call
      expect(result).to be_a(Chamomile::SequenceCmd)
      expect(result.cmds).to eq([c1, c2])
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
  end

  describe "#cmd" do
    it "wraps a callable" do
      result_msg = Chamomile::QuitMsg.new
      c = cmd(-> { result_msg })
      expect(c.call).to eq(result_msg)
    end
  end
end
