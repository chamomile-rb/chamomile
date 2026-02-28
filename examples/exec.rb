# frozen_string_literal: true

require_relative "../lib/chamomile"
require "tempfile"

class EditorLauncher
  include Chamomile::Model
  include Chamomile::Commands

  def initialize
    @file = Tempfile.new(["chamomile_", ".txt"])
    @file.write("Edit this file!\n")
    @file.flush
    @launched = false
  end

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      return quit if msg.key == "q"

      if msg.key == "e"
        @launched = true
        editor = ENV["EDITOR"] || "vi"
        return exec(editor, @file.path)
      end
    end
    nil
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
