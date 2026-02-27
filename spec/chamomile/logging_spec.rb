# frozen_string_literal: true

require "tempfile"

RSpec.describe "Chamomile logging" do
  after do
    Chamomile.close_log
  end

  describe ".log_to_file" do
    it "creates a logger writing to the specified file" do
      file = Tempfile.new("chamomile_log")
      path = file.path
      file.close

      Chamomile.log_to_file(path)
      Chamomile.log("test message")

      content = File.read(path)
      expect(content).to include("test message")
    ensure
      file.unlink
    end
  end

  describe ".log" do
    it "does nothing when no logger is configured" do
      expect { Chamomile.log("no crash") }.not_to raise_error
    end

    it "supports log levels" do
      file = Tempfile.new("chamomile_log")
      path = file.path
      file.close

      Chamomile.log_to_file(path)
      Chamomile.log("info msg", level: :info)

      content = File.read(path)
      expect(content).to include("[INFO]")
      expect(content).to include("info msg")
    ensure
      file.unlink
    end
  end

  describe ".close_log" do
    it "stops logging" do
      file = Tempfile.new("chamomile_log")
      path = file.path
      file.close

      Chamomile.log_to_file(path)
      Chamomile.log("before close")
      Chamomile.close_log
      Chamomile.log("after close")

      content = File.read(path)
      expect(content).to include("before close")
      expect(content).not_to include("after close")
    ensure
      file.unlink
    end
  end
end
