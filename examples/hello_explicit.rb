# frozen_string_literal: true

# Hello — explicit Chamomile style
# Run: ruby examples/hello_explicit.rb
# Compare: examples/hello_dsl.rb

require_relative "../lib/chamomile"
# (styling is included in chamomile)

class Hello
  include Chamomile::Application

  on_key("q") { quit }

  def view
    header = Chamomile::Style.new.bold.foreground("#7d56f4").render("Hello from Chamomile!")
    Chamomile.vertical([header, "", "Press q to quit."], align: :left)
  end
end

Chamomile.run(Hello.new)
