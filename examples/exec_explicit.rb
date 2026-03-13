# frozen_string_literal: true

# Editor Launcher — explicit Chamomile style
# Run: ruby examples/exec_explicit.rb
# Compare: examples/exec_dsl.rb

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
  on_key("e") do
    @launched = true
    editor = ENV["EDITOR"] || "vi"
    exec(editor, @file.path)
  end

  def view
    header = Chamomile::Style.new.bold.foreground("#7d56f4").render("Editor Launcher")
    body = if @launched
             "Editor was launched for: #{@file.path}\nPress e to edit again, q to quit."
           else
             "Press e to launch $EDITOR\nPress q to quit."
           end
    Chamomile.vertical([header, "", body], align: :left)
  end
end

Chamomile.run(EditorLauncher.new)
