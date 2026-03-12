# frozen_string_literal: true

# Hello — DSL style
# Run: ruby examples/hello_dsl.rb
# Compare: examples/hello_explicit.rb

require_relative "../lib/chamomile"
require "flourish"

class Hello
  include Chamomile::Application

  on_key("q") { quit }

  def view
    vertical(align: :left) do
      text "Hello from Chamomile!", bold: true, color: "#7d56f4"
      text ""
      text "Press q to quit."
    end
  end
end

Chamomile.run(Hello.new)
