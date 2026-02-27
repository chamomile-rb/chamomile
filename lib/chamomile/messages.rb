# frozen_string_literal: true

module Chamomile
  QuitMsg = Data.define

  WindowSizeMsg = Data.define(:width, :height)

  KeyMsg = Data.define(:key, :mod) do
    def ctrl?  = mod.include?(:ctrl)
    def shift? = mod.include?(:shift)
    def alt?   = mod.include?(:alt)
    def to_s   = mod.empty? ? key.to_s : "#{mod.join("+")}+#{key}"
  end

  # Mouse button constants
  MOUSE_LEFT    = :left
  MOUSE_MIDDLE  = :middle
  MOUSE_RIGHT   = :right
  MOUSE_NONE    = :none
  MOUSE_WHEEL_UP   = :wheel_up
  MOUSE_WHEEL_DOWN = :wheel_down

  # Mouse action constants
  MOUSE_PRESS   = :press
  MOUSE_RELEASE = :release
  MOUSE_MOTION  = :motion

  MouseMsg = Data.define(:x, :y, :button, :action, :mod) do
    def press?   = action == MOUSE_PRESS
    def release? = action == MOUSE_RELEASE
    def motion?  = action == MOUSE_MOTION
    def ctrl?    = mod.include?(:ctrl)
    def shift?   = mod.include?(:shift)
    def alt?     = mod.include?(:alt)
    def wheel?   = [MOUSE_WHEEL_UP, MOUSE_WHEEL_DOWN].include?(button)
  end

  PasteMsg = Data.define(:content)

  FocusMsg = Data.define
  BlurMsg  = Data.define

  InterruptMsg = Data.define
  SuspendMsg   = Data.define
  ResumeMsg    = Data.define

  ErrorMsg = Data.define(:error)
  TickMsg  = Data.define(:time)
end
