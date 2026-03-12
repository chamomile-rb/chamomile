# frozen_string_literal: true

module Chamomile
  QuitEvent = Data.define
  QuitMsg   = QuitEvent # backward compat

  ResizeEvent   = Data.define(:width, :height)
  WindowSizeMsg = ResizeEvent # backward compat

  KeyEvent = Data.define(:key, :mod) do
    def ctrl?  = mod.include?(:ctrl)
    def shift? = mod.include?(:shift)
    def alt?   = mod.include?(:alt)
    def to_s   = mod.empty? ? key.to_s : "#{mod.join("+")}+#{key}"
  end
  KeyMsg = KeyEvent # backward compat

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

  MouseEvent = Data.define(:x, :y, :button, :action, :mod) do
    def press?   = action == MOUSE_PRESS
    def release? = action == MOUSE_RELEASE
    def motion?  = action == MOUSE_MOTION
    def ctrl?    = mod.include?(:ctrl)
    def shift?   = mod.include?(:shift)
    def alt?     = mod.include?(:alt)
    def wheel?   = [MOUSE_WHEEL_UP, MOUSE_WHEEL_DOWN].include?(button)
  end
  MouseMsg = MouseEvent # backward compat

  PasteEvent = Data.define(:content)
  PasteMsg   = PasteEvent # backward compat

  FocusEvent = Data.define
  FocusMsg   = FocusEvent # backward compat

  BlurEvent = Data.define
  BlurMsg   = BlurEvent # backward compat

  InterruptEvent = Data.define
  InterruptMsg   = InterruptEvent # backward compat

  SuspendEvent = Data.define
  SuspendMsg   = SuspendEvent # backward compat

  ResumeEvent = Data.define
  ResumeMsg   = ResumeEvent # backward compat

  ErrorEvent = Data.define(:error)
  ErrorMsg   = ErrorEvent # backward compat

  TickEvent = Data.define(:time)
  TickMsg   = TickEvent # backward compat
end
