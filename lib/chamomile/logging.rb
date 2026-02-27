# frozen_string_literal: true

require "logger"

# :nodoc:
module Chamomile
  @logger = nil
  @log_mutex = Mutex.new

  def self.log_to_file(path)
    @log_mutex.synchronize do
      @logger&.close
      @logger = Logger.new(path)
      @logger.formatter = proc { |severity, time, _, msg|
        "#{time.strftime("%Y-%m-%d %H:%M:%S.%L")} [#{severity}] #{msg}\n"
      }
    end
  end

  def self.log(msg, level: :debug)
    @log_mutex.synchronize do
      return unless @logger

      @logger.send(level, msg)
    end
  end

  def self.close_log
    @log_mutex.synchronize do
      @logger&.close
      @logger = nil
    end
  end
end
