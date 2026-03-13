# frozen_string_literal: true

require_relative "../lib/chamomile"
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
    lines = []
    lines << "Editor Launcher"
    lines << "==============="
    lines << ""
    if @launched
      lines << "Editor was launched for: #{@file.path}"
      lines << "Press e to edit again, q to quit."
    else
      lines << "Press e to launch $EDITOR"
      lines << "Press q to quit."
    end
    lines.join("\n")
  end
end

Chamomile.run(EditorLauncher.new)
