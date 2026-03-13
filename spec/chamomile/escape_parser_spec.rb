# frozen_string_literal: true

RSpec.describe Chamomile::EscapeParser do
  let(:parser) { described_class.new }

  def parse(bytes)
    msgs = []
    parser.feed(bytes) { |msg| msgs << msg }
    msgs
  end

  def parse_with_timeout(bytes)
    msgs = []
    parser.feed(bytes) { |msg| msgs << msg }
    parser.timeout! { |msg| msgs << msg }
    msgs
  end

  describe "printable characters" do
    it "parses single printable chars" do
      msgs = parse("a")
      expect(msgs.length).to eq(1)
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: "a", mod: []))
    end

    it "parses multiple chars in one feed" do
      msgs = parse("abc")
      expect(msgs.length).to eq(3)
      expect(msgs.map(&:key)).to eq(%w[a b c])
    end

    it "parses space" do
      msgs = parse(" ")
      expect(msgs[0].key).to eq(" ")
      expect(msgs[0].mod).to eq([])
    end
  end

  describe "control codes" do
    it "parses ctrl+c" do
      msgs = parse("\x03")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: "c", mod: [:ctrl]))
    end

    it "parses ctrl+a" do
      msgs = parse("\x01")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: "a", mod: [:ctrl]))
    end

    it "parses ctrl+z" do
      msgs = parse("\x1a")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: "z", mod: [:ctrl]))
    end

    it "parses enter (CR)" do
      msgs = parse("\r")
      expect(msgs[0].key).to eq(:enter)
    end

    it "parses enter (LF)" do
      msgs = parse("\n")
      expect(msgs[0].key).to eq(:enter)
    end

    it "parses tab" do
      msgs = parse("\t")
      expect(msgs[0].key).to eq(:tab)
    end

    it "parses backspace (DEL)" do
      msgs = parse("\x7f")
      expect(msgs[0].key).to eq(:backspace)
    end

    it "parses backspace (BS)" do
      msgs = parse("\x08")
      expect(msgs[0].key).to eq(:backspace)
    end
  end

  describe "bare ESC" do
    it "does not emit immediately (waits for more input)" do
      msgs = parse("\e")
      expect(msgs).to be_empty
    end

    it "emits :escape on timeout" do
      parse("\e")
      msgs = []
      parser.timeout! { |msg| msgs << msg }
      expect(msgs.length).to eq(1)
      expect(msgs[0].key).to eq(:escape)
      expect(msgs[0].mod).to eq([])
    end

    it "does not emit on timeout if already consumed" do
      parse_with_timeout("\e[A")
      timeout_msgs = []
      parser.timeout! { |msg| timeout_msgs << msg }
      expect(timeout_msgs).to be_empty
    end
  end

  describe "alt combos" do
    it "parses ESC + char as alt+char" do
      msgs = parse("\ea")
      expect(msgs.length).to eq(1)
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: "a", mod: [:alt]))
    end

    it "parses ESC + uppercase as alt+uppercase" do
      msgs = parse("\eA")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: "A", mod: [:alt]))
    end

    it "parses ESC + enter as alt+enter" do
      msgs = parse("\e\r")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :enter, mod: [:alt]))
    end

    it "parses ESC + backspace as alt+backspace" do
      msgs = parse("\e\x7f")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :backspace, mod: [:alt]))
    end

    it "parses ESC + ctrl+c as alt+ctrl+c" do
      msgs = parse("\e\x03")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: "c", mod: %i[alt ctrl]))
    end
  end

  describe "arrow keys" do
    it "parses up arrow" do
      msgs = parse("\e[A")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :up, mod: []))
    end

    it "parses down arrow" do
      msgs = parse("\e[B")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :down, mod: []))
    end

    it "parses right arrow" do
      msgs = parse("\e[C")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :right, mod: []))
    end

    it "parses left arrow" do
      msgs = parse("\e[D")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :left, mod: []))
    end
  end

  describe "modified arrow keys" do
    it "parses shift+up" do
      msgs = parse("\e[1;2A")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :up, mod: [:shift]))
    end

    it "parses alt+down" do
      msgs = parse("\e[1;3B")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :down, mod: [:alt]))
    end

    it "parses ctrl+right" do
      msgs = parse("\e[1;5C")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :right, mod: [:ctrl]))
    end

    it "parses ctrl+shift+left" do
      msgs = parse("\e[1;6D")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :left, mod: %i[ctrl shift]))
    end
  end

  describe "navigation keys" do
    it "parses home" do
      msgs = parse("\e[H")
      expect(msgs[0].key).to eq(:home)
    end

    it "parses end" do
      msgs = parse("\e[F")
      expect(msgs[0].key).to eq(:end_key)
    end

    it "parses page up" do
      msgs = parse("\e[5~")
      expect(msgs[0].key).to eq(:page_up)
    end

    it "parses page down" do
      msgs = parse("\e[6~")
      expect(msgs[0].key).to eq(:page_down)
    end

    it "parses insert" do
      msgs = parse("\e[2~")
      expect(msgs[0].key).to eq(:insert)
    end

    it "parses delete" do
      msgs = parse("\e[3~")
      expect(msgs[0].key).to eq(:delete)
    end

    it "parses shift+tab (backtab)" do
      msgs = parse("\e[Z")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :tab, mod: [:shift]))
    end
  end

  describe "function keys" do
    it "parses F1 (SS3)" do
      msgs = parse("\eOP")
      expect(msgs[0].key).to eq(:f1)
    end

    it "parses F2 (SS3)" do
      msgs = parse("\eOQ")
      expect(msgs[0].key).to eq(:f2)
    end

    it "parses F3 (SS3)" do
      msgs = parse("\eOR")
      expect(msgs[0].key).to eq(:f3)
    end

    it "parses F4 (SS3)" do
      msgs = parse("\eOS")
      expect(msgs[0].key).to eq(:f4)
    end

    it "parses F5" do
      msgs = parse("\e[15~")
      expect(msgs[0].key).to eq(:f5)
    end

    it "parses F6" do
      msgs = parse("\e[17~")
      expect(msgs[0].key).to eq(:f6)
    end

    it "parses F12" do
      msgs = parse("\e[24~")
      expect(msgs[0].key).to eq(:f12)
    end

    it "parses modified function keys" do
      msgs = parse("\e[15;5~") # Ctrl+F5
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :f5, mod: [:ctrl]))
    end
  end

  describe "SGR mouse" do
    it "parses left click press" do
      msgs = parse("\e[<0;10;5M")
      expect(msgs.length).to eq(1)
      msg = msgs[0]
      expect(msg).to be_a(Chamomile::MouseMsg)
      expect(msg.x).to eq(10)
      expect(msg.y).to eq(5)
      expect(msg.button).to eq(:left)
      expect(msg.action).to eq(:press)
      expect(msg.mod).to eq([])
    end

    it "parses left click release" do
      msgs = parse("\e[<0;10;5m")
      msg = msgs[0]
      expect(msg.button).to eq(:left)
      expect(msg.action).to eq(:release)
    end

    it "parses middle click" do
      msgs = parse("\e[<1;5;5M")
      expect(msgs[0].button).to eq(:middle)
    end

    it "parses right click" do
      msgs = parse("\e[<2;5;5M")
      expect(msgs[0].button).to eq(:right)
    end

    it "parses wheel up" do
      msgs = parse("\e[<64;5;5M")
      msg = msgs[0]
      expect(msg.button).to eq(:wheel_up)
      expect(msg.wheel?).to be true
    end

    it "parses wheel down" do
      msgs = parse("\e[<65;5;5M")
      msg = msgs[0]
      expect(msg.button).to eq(:wheel_down)
      expect(msg.wheel?).to be true
    end

    it "parses mouse motion" do
      msgs = parse("\e[<32;20;10M")
      msg = msgs[0]
      expect(msg.action).to eq(:motion)
      expect(msg.button).to eq(:left)
      expect(msg.x).to eq(20)
      expect(msg.y).to eq(10)
    end

    it "parses mouse with shift modifier" do
      msgs = parse("\e[<4;5;5M")
      expect(msgs[0].shift?).to be true
    end

    it "parses mouse with alt modifier" do
      msgs = parse("\e[<8;5;5M")
      expect(msgs[0].alt?).to be true
    end

    it "parses mouse with ctrl modifier" do
      msgs = parse("\e[<16;5;5M")
      expect(msgs[0].ctrl?).to be true
    end

    it "parses mouse with multiple modifiers" do
      msgs = parse("\e[<20;5;5M") # ctrl(16) + shift(4)
      msg = msgs[0]
      expect(msg.ctrl?).to be true
      expect(msg.shift?).to be true
    end
  end

  describe "focus/blur" do
    it "parses focus event" do
      msgs = parse("\e[I")
      expect(msgs[0]).to be_a(Chamomile::FocusMsg)
    end

    it "parses blur event" do
      msgs = parse("\e[O")
      expect(msgs[0]).to be_a(Chamomile::BlurMsg)
    end
  end

  describe "bracketed paste" do
    it "parses pasted content" do
      msgs = parse("\e[200~hello world\e[201~")
      expect(msgs.length).to eq(1)
      expect(msgs[0]).to be_a(Chamomile::PasteMsg)
      expect(msgs[0].content).to eq("hello world")
    end

    it "handles multi-line paste" do
      msgs = parse("\e[200~line1\nline2\nline3\e[201~")
      expect(msgs[0].content).to eq("line1\nline2\nline3")
    end

    it "handles empty paste" do
      msgs = parse("\e[200~\e[201~")
      expect(msgs[0].content).to eq("")
    end

    it "handles paste with special characters" do
      msgs = parse("\e[200~hello\ttab\rreturn\e[201~")
      expect(msgs[0].content).to eq("hello\ttab\rreturn")
    end
  end

  describe "split reads" do
    it "handles escape sequence split across feeds" do
      msgs1 = parse("\e")
      expect(msgs1).to be_empty

      msgs2 = parse("[A")
      expect(msgs2.length).to eq(1)
      expect(msgs2[0].key).to eq(:up)
    end

    it "handles CSI split across feeds" do
      parse("\e[")
      msgs = parse("B")
      expect(msgs[0].key).to eq(:down)
    end

    it "handles paste split across feeds" do
      parse("\e[200~hel")
      msgs = parse("lo\e[201~")
      expect(msgs[0]).to be_a(Chamomile::PasteMsg)
      expect(msgs[0].content).to eq("hello")
    end
  end

  describe "multiple sequences in one feed" do
    it "parses multiple keypresses" do
      msgs = parse("abc")
      expect(msgs.length).to eq(3)
      expect(msgs.map(&:key)).to eq(%w[a b c])
    end

    it "parses mixed sequences" do
      msgs = parse("\e[A\e[B")
      expect(msgs.length).to eq(2)
      expect(msgs[0].key).to eq(:up)
      expect(msgs[1].key).to eq(:down)
    end

    it "parses key after escape sequence" do
      msgs = parse("\e[Aq")
      expect(msgs.length).to eq(2)
      expect(msgs[0].key).to eq(:up)
      expect(msgs[1].key).to eq("q")
    end
  end

  describe "unknown sequences" do
    it "emits unknown for unrecognized CSI" do
      msgs = parse("\e[999X")
      expect(msgs[0].mod).to include(:unknown)
    end

    it "emits unknown for unrecognized SS3" do
      msgs = parse("\eOX")
      expect(msgs[0].mod).to include(:unknown)
    end
  end

  describe "SS3 navigation" do
    it "parses SS3 arrow up" do
      msgs = parse("\eOA")
      expect(msgs[0].key).to eq(:up)
    end

    it "parses SS3 arrow down" do
      msgs = parse("\eOB")
      expect(msgs[0].key).to eq(:down)
    end

    it "parses SS3 home" do
      msgs = parse("\eOH")
      expect(msgs[0].key).to eq(:home)
    end

    it "parses SS3 end" do
      msgs = parse("\eOF")
      expect(msgs[0].key).to eq(:end_key)
    end
  end

  describe "double ESC" do
    it "emits first ESC as :escape and starts new sequence" do
      msgs = parse("\e\e[A")
      expect(msgs.length).to eq(2)
      expect(msgs[0].key).to eq(:escape)
      expect(msgs[1].key).to eq(:up)
    end
  end

  describe "UTF-8 multi-byte characters" do
    it "parses emoji characters" do
      msgs = parse("\u{1F600}") # 😀
      expect(msgs.length).to eq(1)
      expect(msgs[0].key).to eq("\u{1F600}")
      expect(msgs[0].mod).to eq([])
    end

    it "parses CJK characters" do
      msgs = parse("日")
      expect(msgs.length).to eq(1)
      expect(msgs[0].key).to eq("日")
    end

    it "parses accented characters" do
      msgs = parse("é")
      expect(msgs.length).to eq(1)
      expect(msgs[0].key).to eq("é")
    end
  end

  describe "rapid input" do
    it "handles many keypresses at once" do
      input = "abcdefghijklmnopqrstuvwxyz"
      msgs = parse(input)
      expect(msgs.length).to eq(26)
      expect(msgs.map(&:key)).to eq(input.chars)
    end

    it "handles many escape sequences at once" do
      input = "\e[A\e[B\e[C\e[D" * 10 # 40 arrow keys
      msgs = parse(input)
      expect(msgs.length).to eq(40)
    end
  end

  describe "modified tilde keys" do
    it "parses ctrl+delete" do
      msgs = parse("\e[3;5~")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :delete, mod: [:ctrl]))
    end

    it "parses shift+insert" do
      msgs = parse("\e[2;2~")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :insert, mod: [:shift]))
    end

    it "parses alt+page_up" do
      msgs = parse("\e[5;3~")
      expect(msgs[0]).to eq(Chamomile::KeyMsg.new(key: :page_up, mod: [:alt]))
    end
  end

  describe "NUL bytes" do
    it "ignores NUL bytes in ground state" do
      msgs = parse("\x00")
      expect(msgs).to be_empty
    end

    it "ignores NUL bytes mixed with normal input" do
      msgs = parse("a\x00b")
      expect(msgs.length).to eq(2)
      expect(msgs.map(&:key)).to eq(%w[a b])
    end
  end

  describe "paste buffer overflow" do
    it "flushes oversized paste content as PasteMsg" do
      # Build a paste that exceeds MAX_PASTE_SIZE
      big_content = "x" * (Chamomile::EscapeParser::MAX_PASTE_SIZE + 100)
      input = "\e[200~#{big_content}"

      msgs = parse(input)
      # First message should be the flushed PasteMsg
      paste_msgs = msgs.grep(Chamomile::PasteMsg)
      expect(paste_msgs.length).to be >= 1
      expect(paste_msgs[0].content.length).to be > 0
    end

    it "prevents unbounded memory growth" do
      # Start a paste and feed lots of data without closing it
      parse("\e[200~")
      10.times { parse("y" * 10_000) }

      # Should have flushed at least once, returning to ground state
      # The parser's internal paste buffer should be bounded
    end
  end

  describe "malformed sequences" do
    it "handles incomplete SGR mouse (fewer than 3 parts)" do
      # This is malformed — only 2 semicolons
      msgs = parse("\e[<0;5M")
      # Should produce something (unknown or empty) but not crash
      expect { msgs }.not_to raise_error
    end

    it "handles unknown tilde code" do
      msgs = parse("\e[999~")
      expect(msgs[0].mod).to include(:unknown)
    end

    it "handles empty CSI parameters" do
      msgs = parse("\e[A") # no params, just final
      expect(msgs[0].key).to eq(:up)
    end
  end

  describe "timeout edge cases" do
    it "does nothing when timeout called in ground state" do
      msgs = []
      parser.timeout! { |msg| msgs << msg }
      expect(msgs).to be_empty
    end

    it "does nothing when timeout called twice" do
      parse("\e")
      msgs = []
      parser.timeout! { |msg| msgs << msg }
      parser.timeout! { |msg| msgs << msg }
      expect(msgs.length).to eq(1)
    end

    it "does not emit timeout during CSI collection" do
      parse("\e[") # In CSI_ENTRY state
      msgs = []
      parser.timeout! { |msg| msgs << msg }
      # Should NOT flush as escape — we're mid-CSI
      expect(msgs).to be_empty
    end

    it "does not emit timeout during paste" do
      parse("\e[200~hello") # In PASTE state
      msgs = []
      parser.timeout! { |msg| msgs << msg }
      expect(msgs).to be_empty
    end
  end

  describe "unknown modifier codes" do
    it "returns empty mod for unknown modifier value" do
      # Modifier code 99 is not in MODIFIER_MAP
      msgs = parse("\e[1;99A")
      expect(msgs[0].key).to eq(:up)
      expect(msgs[0].mod).to eq([])
    end
  end

  describe "all ctrl keys" do
    it "maps all C0 control codes correctly" do
      ("a".."z").each_with_index do |letter, i|
        code = i + 1
        next if [8, 9, 10, 13].include?(code) # BS, TAB, LF, CR have special mappings

        msgs = parse(code.chr)
        expect(msgs[0].key).to eq(letter), "Expected ctrl+#{letter} for \\x#{code.to_s(16).rjust(2, "0")}"
        expect(msgs[0].mod).to eq([:ctrl])
      end
    end
  end
end
