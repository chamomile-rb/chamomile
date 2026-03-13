# frozen_string_literal: true

RSpec.describe Chamomile::CancelToken do
  it "starts uncancelled" do
    token = described_class.new
    expect(token.cancelled?).to be false
  end

  it "becomes cancelled after cancel!" do
    token = described_class.new
    token.cancel!
    expect(token.cancelled?).to be true
  end

  it "is thread-safe" do
    token = described_class.new
    threads = 10.times.map do
      Thread.new { token.cancel! }
    end
    threads.each(&:join)
    expect(token.cancelled?).to be true
  end
end

RSpec.describe "Chamomile::Commands cancellation" do
  include Chamomile::Commands

  describe "#cancellable" do
    it "returns a token and a command" do
      token, cmd = cancellable { |_token| Chamomile::TickMsg.new(time: Time.now) }
      expect(token).to be_a(Chamomile::CancelToken)
      expect(cmd).to be_a(Proc)
    end

    it "executes the block when not cancelled" do
      _, cmd = cancellable { |_token| Chamomile::TickMsg.new(time: Time.now) }
      result = cmd.call
      expect(result).to be_a(Chamomile::TickMsg)
    end

    it "returns nil when cancelled before execution" do
      token, cmd = cancellable { |_token| Chamomile::TickMsg.new(time: Time.now) }
      token.cancel!
      expect(cmd.call).to be_nil
    end

    it "passes the token to the block for cooperative checking" do
      received_token = nil
      token, cmd = cancellable do |t|
        received_token = t
        nil
      end
      cmd.call
      expect(received_token).to eq(token)
    end
  end

  describe "#cancel" do
    it "returns a command that produces a CancelCmd" do
      token = Chamomile::CancelToken.new
      cmd = cancel(token)
      result = cmd.call
      expect(result).to be_a(Chamomile::CancelCmd)
      expect(result.token).to eq(token)
    end
  end

  describe "#stream" do
    it "returns a token and a command" do
      token, cmd = stream { |_push, _token| nil }
      expect(token).to be_a(Chamomile::CancelToken)
      expect(cmd).to be_a(Proc)
    end

    it "produces a StreamCmd when called" do
      token, cmd = stream { |_push, _token| nil }
      result = cmd.call
      expect(result).to be_a(Chamomile::StreamCmd)
      expect(result.token).to eq(token)
    end

    it "returns nil when cancelled before execution" do
      token, cmd = stream { |_push, _token| nil }
      token.cancel!
      expect(cmd.call).to be_nil
    end
  end
end

RSpec.describe "Chamomile::Commands deliver and map" do
  include Chamomile::Commands

  describe "#deliver" do
    it "returns a command that produces the given message" do
      msg = Chamomile::TickMsg.new(time: Time.now)
      cmd = deliver(msg)
      expect(cmd.call).to eq(msg)
    end
  end

  describe "#map" do
    it "transforms a command's result" do
      inner = -> { Chamomile::TickMsg.new(time: Time.now) }
      mapped = map(inner) { |_result| Chamomile::KeyMsg.new(key: "mapped", mod: []) }
      result = mapped.call
      expect(result).to be_a(Chamomile::KeyMsg)
      expect(result.key).to eq("mapped")
    end

    it "returns nil for nil command" do
      expect(map(nil) { |r| r }).to be_nil
    end

    it "returns nil when inner command returns nil" do
      inner = -> {}
      mapped = map(inner) { |_result| Chamomile::TickMsg.new(time: Time.now) }
      expect(mapped.call).to be_nil
    end
  end
end

RSpec.describe "Chamomile::Commands shell and timer" do
  include Chamomile::Commands

  describe "#shell" do
    it "runs a command and returns a ShellResult" do
      cmd = shell("echo hello", envelope: :test)
      result = cmd.call
      expect(result).to be_a(Chamomile::ShellResult)
      expect(result.envelope).to eq(:test)
      expect(result.stdout).to include("hello")
      expect(result.stderr).to eq("")
      expect(result.status).to eq(0)
      expect(result.success).to be true
    end

    it "captures stderr" do
      cmd = shell("echo error >&2", envelope: :err_test)
      result = cmd.call
      expect(result.stderr).to include("error")
    end

    it "reports failure status" do
      cmd = shell("false", envelope: :fail_test)
      result = cmd.call
      expect(result.success).to be false
      expect(result.status).not_to eq(0)
    end

    it "pattern matches on envelope" do
      cmd = shell("echo hi", envelope: :greeting)
      result = cmd.call
      case result
      in { envelope: :greeting, stdout: }
        expect(stdout).to include("hi")
      end
    end
  end

  describe "#timer" do
    it "returns a TimerTick with the given envelope" do
      cmd = timer(0.01, envelope: :ui_tick)
      result = cmd.call
      expect(result).to be_a(Chamomile::TimerTick)
      expect(result.envelope).to eq(:ui_tick)
      expect(result.time).to be_a(Time)
    end
  end
end
