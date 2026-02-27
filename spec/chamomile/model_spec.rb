# frozen_string_literal: true

RSpec.describe Chamomile::Model do
  let(:bare_class) do
    Class.new do
      include Chamomile::Model
    end
  end

  let(:complete_class) do
    Class.new do
      include Chamomile::Model

      def update(_msg)
        [self, nil]
      end

      def view
        "hello"
      end
    end
  end

  describe "#init" do
    it "returns nil by default" do
      expect(bare_class.new.init).to be_nil
    end
  end

  describe "#update" do
    it "raises NotImplementedError if not implemented" do
      expect { bare_class.new.update(:any) }.to raise_error(NotImplementedError)
    end

    it "works when implemented" do
      model = complete_class.new
      result = model.update(:any)
      expect(result).to eq([model, nil])
    end
  end

  describe "#view" do
    it "returns empty string by default" do
      expect(bare_class.new.view).to eq("")
    end

    it "returns custom view when implemented" do
      expect(complete_class.new.view).to eq("hello")
    end
  end
end
