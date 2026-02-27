# frozen_string_literal: true

require "io/console"

module Chamomile
  # Background thread that reads stdin and feeds bytes through EscapeParser.
  class InputReader
    def initialize(queue, input: $stdin)
      @queue   = queue
      @input   = input
      @thread  = nil
      @running = false
      @parser  = EscapeParser.new
    end

    def start
      return @thread if @running

      @running = true
      @thread = Thread.new { read_loop }
      @thread.abort_on_exception = false
      @thread
    end

    def stop
      @running = false
      return unless @thread

      @thread.kill
      @thread = nil
    end

    def running?
      @running
    end

    private

    def read_loop
      while @running
        begin
          if @input.wait_readable(0.05)
            bytes = @input.read_nonblock(256)
            next if bytes.nil? || bytes.empty?

            @parser.feed(bytes) { |msg| @queue.push(msg) }
          else
            @parser.timeout! { |msg| @queue.push(msg) }
          end
        rescue IO::WaitReadable
          # Transient — retry on next iteration
        rescue EOFError, Errno::EIO
          @queue.push(QuitMsg.new)
          break
        rescue StandardError => e
          Chamomile.log("InputReader error: #{e.class}: #{e.message}", level: :warn)
        end
      end
    end
  end
end
