# frozen_string_literal: true

RSpec.describe Chamomile::InputReader do
  let(:queue) { Queue.new }

  describe "with IO.pipe" do
    let(:read_io) { @read_io }
    let(:write_io) { @write_io }
    let(:reader) { described_class.new(queue, input: read_io) }

    before do
      @read_io, @write_io = IO.pipe
    end

    after do
      reader.stop
      write_io.close unless write_io.closed?
      read_io.close unless read_io.closed?
    end

    it "reads single keys" do
      reader.start
      write_io.write("a")
      write_io.flush

      msg = queue.pop
      expect(msg).to be_a(Chamomile::KeyMsg)
      expect(msg.key).to eq("a")
    end

    it "reads escape sequences" do
      reader.start
      write_io.write("\e[A")
      write_io.flush

      msg = queue.pop
      expect(msg).to be_a(Chamomile::KeyMsg)
      expect(msg.key).to eq(:up)
    end

    it "handles EOF" do
      reader.start
      write_io.close

      msg = queue.pop
      expect(msg).to be_a(Chamomile::QuitMsg)
    end

    it "handles timeout for bare ESC" do
      reader.start
      write_io.write("\e")
      write_io.flush

      # The parser should flush ESC on timeout
      msg = queue.pop
      expect(msg).to be_a(Chamomile::KeyMsg)
      expect(msg.key).to eq(:escape)
    end

    it "reads multiple keys in sequence" do
      reader.start
      write_io.write("abc")
      write_io.flush

      msgs = 3.times.map { queue.pop }
      expect(msgs.map(&:key)).to eq(%w[a b c])
    end

    it "reads mouse events" do
      reader.start
      write_io.write("\e[<0;10;5M")
      write_io.flush

      msg = queue.pop
      expect(msg).to be_a(Chamomile::MouseMsg)
      expect(msg.x).to eq(10)
      expect(msg.y).to eq(5)
    end

    it "reads bracketed paste" do
      reader.start
      write_io.write("\e[200~pasted text\e[201~")
      write_io.flush

      msg = queue.pop
      expect(msg).to be_a(Chamomile::PasteMsg)
      expect(msg.content).to eq("pasted text")
    end
  end

  describe "lifecycle" do
    it "reports running state" do
      rd, wr = IO.pipe
      reader = described_class.new(queue, input: rd)

      expect(reader.running?).to be false
      reader.start
      expect(reader.running?).to be true
      reader.stop
      expect(reader.running?).to be false

      wr.close
      rd.close
    end

    it "is safe to stop before start" do
      rd, wr = IO.pipe
      reader = described_class.new(queue, input: rd)
      expect { reader.stop }.not_to raise_error
      wr.close
      rd.close
    end

    it "is safe to stop twice" do
      rd, wr = IO.pipe
      reader = described_class.new(queue, input: rd)
      reader.start
      reader.stop
      expect { reader.stop }.not_to raise_error
      wr.close
      rd.close
    end

    it "does not start twice" do
      rd, wr = IO.pipe
      reader = described_class.new(queue, input: rd)
      t1 = reader.start
      t2 = reader.start
      expect(t1).to eq(t2) # Same thread returned
      reader.stop
      wr.close
      rd.close
    end
  end
end
