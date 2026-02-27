module Chamomile
  QuitMsg = Data.define

  WindowSizeMsg = Data.define(:width, :height)

  KeyMsg = Data.define(:key, :mod) do
    def ctrl?  = mod.include?(:ctrl)
    def shift? = mod.include?(:shift)
    def alt?   = mod.include?(:alt)
    def to_s   = mod.empty? ? key.to_s : "#{mod.join('+')}+#{key}"
  end

  FocusMsg = Data.define
  BlurMsg  = Data.define

  ErrorMsg = Data.define(:error)
  TickMsg  = Data.define(:time)
end
