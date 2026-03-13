# frozen_string_literal: true

# Editor Launcher — DSL style
# Run: ruby examples/exec_dsl.rb
# Compare: examples/exec_explicit.rb

require_relative "../lib/chamomile"
# (styling is included in chamomile)
require "tempfile"

class EditorLauncher
  include Chamomile::Application

  def initialize
    @file = Tempfile.new(["chamomile_", ".txt"])
    @file.write("Edit this file!\n")
    @file.flush
    @launched = false
  end

  on_key("q") { quit }
  on_key("e") {
    @launched = true
    editor = ENV["EDITOR"] || "vi"
    exec(editor, @file.path)
  }

  def view
    vertical(align: :left) do
      text "Editor Launcher", bold: true, color: "#7d56f4"
      text ""
      if @launched
        text "Editor was launched for: #{@file.path}"
        text "Press e to edit again, q to quit."
      else
        text "Press e to launch $EDITOR"
        text "Press q to quit."
      end
    end
  end
end

Chamomile.run(EditorLauncher.new)
