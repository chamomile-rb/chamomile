# frozen_string_literal: true

RSpec.describe "Chamomile::Model immutability" do
  describe "#with" do
    it "returns a copy with changed attributes" do
      klass = Class.new do
        include Chamomile::Model

        attr_reader :count, :name

        def initialize(count: 0, name: "test")
          @count = count
          @name = name
        end

        def update(_msg) = nil
        def view = "#{name}: #{count}"
      end

      model = klass.new(count: 0, name: "counter")
      new_model = model.with(count: 5)

      expect(new_model.count).to eq(5)
      expect(new_model.name).to eq("counter")
      expect(model.count).to eq(0) # original unchanged
    end
  end

  describe ".frozen_model!" do
    it "freezes the model after initialize" do
      klass = Class.new do
        include Chamomile::Model
        frozen_model!

        attr_reader :count

        def initialize(count: 0)
          @count = count
        end

        def update(_msg) = nil
        def view = "count: #{count}"
      end

      model = klass.new
      expect(model).to be_frozen
    end

    it "raises FrozenError on mutation" do
      klass = Class.new do
        include Chamomile::Model
        frozen_model!

        attr_reader :count

        def initialize(count: 0)
          @count = count
        end

        def update(_msg)
          @count += 1
          nil
        end

        def view = "count: #{count}"
      end

      model = klass.new
      expect { model.update(:any) }.to raise_error(FrozenError)
    end

    it "works with #with to return modified copies" do
      klass = Class.new do
        include Chamomile::Model
        frozen_model!

        attr_reader :count

        def initialize(count: 0)
          @count = count
        end

        def update(_msg) = nil
        def view = "count: #{count}"
      end

      model = klass.new(count: 0)
      new_model = model.with(count: 1)
      expect(new_model.count).to eq(1)
      expect(new_model).to be_frozen
      expect(model.count).to eq(0)
    end

    it "reports frozen_model? correctly" do
      frozen_class = Class.new do
        include Chamomile::Model
        frozen_model!

        def update(_msg) = nil
      end

      mutable_class = Class.new do
        include Chamomile::Model

        def update(_msg) = nil
      end

      expect(frozen_class.frozen_model?).to be true
      expect(mutable_class.frozen_model?).to be false
    end
  end
end
