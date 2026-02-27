require "io/console"

module Chamomile
  class InputReader
    def initialize(queue)
      @queue   = queue
      @thread  = nil
      @running = false
    end

    def start
      @running = true
      @thread = Thread.new { read_loop }
      @thread.abort_on_exception = false
      @thread
    end

    def stop
      @running = false
      @thread&.kill
      @thread = nil
    end

    private

    def read_loop
      while @running
        begin
          bytes = $stdin.read_nonblock(32)
          next if bytes.nil? || bytes.empty?
          msg = KeyMap.translate(bytes)
          @queue.push(msg)
        rescue IO::WaitReadable
          IO.select([$stdin], nil, nil, 0.05)
        rescue EOFError, Errno::EIO
          @queue.push(QuitMsg.new)
          break
        rescue
          # Swallow other errors in the read loop
        end
      end
    end
  end
end
