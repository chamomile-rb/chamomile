# frozen_string_literal: true

require_relative "../lib/chamomile"

class Hello
  include Chamomile::Application

  on_key("q") { quit }
  on_key(:ctrl_c) { quit }

  def update(msg)
    case msg
    when Chamomile::KeyEvent
      return quit if msg.ctrl?
    end
    nil
  end

  def view
    "Hello from Chamomile!\n\nPress q to quit."
  end
end

Chamomile.run(Hello.new)
