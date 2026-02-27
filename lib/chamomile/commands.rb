module Chamomile
  BatchCmd    = Data.define(:cmds)
  SequenceCmd = Data.define(:cmds)

  module Commands
    def quit
      -> { QuitMsg.new }
    end

    def none
      nil
    end

    def batch(*cmds)
      valid = cmds.flatten.compact
      return nil if valid.empty?
      -> { BatchCmd.new(cmds: valid) }
    end

    def sequence(*cmds)
      valid = cmds.flatten.compact
      return nil if valid.empty?
      -> { SequenceCmd.new(cmds: valid) }
    end

    def tick(duration, &block)
      -> {
        sleep(duration)
        block ? block.call : TickMsg.new(time: Time.now)
      }
    end

    def every(duration, &block)
      -> {
        now = Time.now
        next_tick = (now + duration) - (now.to_f % duration)
        sleep(next_tick - Time.now)
        block ? block.call : TickMsg.new(time: Time.now)
      }
    end

    def cmd(callable)
      -> { callable.call }
    end

    module_function :quit, :none, :batch, :sequence, :tick, :every, :cmd
  end
end
