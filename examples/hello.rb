require_relative "../lib/chamomile"

class Hello
  include Chamomile::Model
  include Chamomile::Commands

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      return [self, quit] if msg.key == "q" || msg.ctrl?
    end
    [self, nil]
  end

  def view
    "Hello from Chamomile!\n\nPress q to quit."
  end
end

Chamomile.run(Hello.new)
