require "stringio"

RSpec.describe Chamomile::Program do
  let(:output) { StringIO.new }

  let(:quit_after_init_model) do
    Class.new do
      include Chamomile::Model
      include Chamomile::Commands

      attr_reader :messages_received

      def initialize
        @messages_received = []
      end

      def init
        quit
      end

      def update(msg)
        @messages_received << msg
        [self, nil]
      end

      def view
        "test view"
      end
    end.new
  end

  let(:count_then_quit_model) do
    Class.new do
      include Chamomile::Model
      include Chamomile::Commands

      attr_reader :count

      def initialize
        @count = 0
      end

      def update(msg)
        case msg
        when Chamomile::WindowSizeMsg
          # ignore
        else
          @count += 1
          return [self, quit] if @count >= 2
        end
        [self, nil]
      end

      def view
        "count: #{@count}"
      end
    end.new
  end

  describe "#run" do
    it "runs a model that quits immediately via init cmd" do
      program = described_class.new(quit_after_init_model, output: output)
      # Stub terminal methods to avoid real terminal manipulation
      allow(program).to receive(:setup_terminal) do
        program.instance_variable_set(:@running, true)
        program.instance_variable_get(:@input_reader)
          .instance_variable_set(:@running, false)
      end
      allow(program).to receive(:teardown_terminal)

      result = program.run
      expect(result).to eq(quit_after_init_model)
    end

    it "returns the final model state" do
      program = described_class.new(quit_after_init_model, output: output)
      allow(program).to receive(:setup_terminal) do
        program.instance_variable_set(:@running, true)
        program.instance_variable_get(:@input_reader)
          .instance_variable_set(:@running, false)
      end
      allow(program).to receive(:teardown_terminal)

      model = program.run
      expect(model).to be_a(Chamomile::Model)
    end
  end

  describe "#send_msg" do
    it "pushes messages to the queue" do
      program = described_class.new(quit_after_init_model, output: output)
      program.send_msg(Chamomile::QuitMsg.new)
      queue = program.instance_variable_get(:@msgs)
      expect(queue.pop).to be_a(Chamomile::QuitMsg)
    end
  end
end
