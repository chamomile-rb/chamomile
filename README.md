# Chamomile

A Ruby TUI framework based on [The Elm Architecture](https://guide.elm-lang.org/architecture/). Inspired by Go's [Bubble Tea](https://github.com/charmbracelet/bubbletea).

Build rich, interactive terminal applications in Ruby using the **Model / Update / View** pattern.

## Features

- **Elm Architecture** — predictable state management with messages and commands
- **Streaming input parser** — ANSI escape sequences, CSI params, SGR mouse, bracketed paste, focus/blur
- **FPS-throttled renderer** — diff rendering in alt-screen, inline mode for non-fullscreen apps
- **Command system** — async commands via threads, batch/sequence composition, tick/every helpers
- **Full terminal control** — mouse, bracketed paste, focus reporting, cursor shapes, alt screen toggling
- **Signal handling** — SIGWINCH (resize), SIGINT, SIGTERM, SIGTSTP/SIGCONT (suspend/resume)
- **Zero runtime dependencies** — just Ruby >= 3.2

## Installation

```ruby
# Gemfile
gem "chamomile"
```

## Quick Start

```ruby
require "chamomile"

class Counter
  include Chamomile::Model
  include Chamomile::Commands

  def initialize
    @count = 0
  end

  def update(msg)
    case msg
    when Chamomile::KeyMsg
      case msg.key
      when :up,   "k" then @count += 1
      when :down, "j" then @count -= 1
      when "q"         then return quit
      end
    end
    nil
  end

  def view
    "Count: #{@count}\n\nup/k increment | down/j decrement | q quit"
  end
end

Chamomile.run(Counter.new)
```

## How It Works

1. **Model** — your class includes `Chamomile::Model` and holds application state
2. **`init`** — returns an optional command to run at startup (timers, data loading, etc.)
3. **`update(msg)`** — receives messages (key presses, mouse events, ticks), returns a command or nil
4. **`view`** — returns a string to render to the terminal
5. **Commands** — lambdas that run in threads and return messages back to the event loop

## Messages

| Message | Description |
|---------|-------------|
| `KeyMsg` | Key press with `.key` (Symbol or String) and `.mod` (`:ctrl`, `:alt`, `:shift`) |
| `MouseMsg` | Mouse event with position, button, action, modifiers |
| `PasteMsg` | Bracketed paste content |
| `WindowSizeMsg` | Terminal resize with `.width` and `.height` |
| `FocusMsg` / `BlurMsg` | Terminal focus changes |
| `TickMsg` | Timer tick with `.time` |
| `InterruptMsg` | Ctrl+C (handle or let it quit) |
| `SuspendMsg` / `ResumeMsg` | Ctrl+Z suspend and resume |

## Commands

Include `Chamomile::Commands` for these helpers:

```ruby
quit                          # exit the program
tick(1.0)                     # fire a TickMsg after 1 second
every(1.0)                    # fire a TickMsg aligned to wall clock
batch(cmd1, cmd2)             # run commands concurrently
sequence(cmd1, cmd2)          # run commands in order
exec("vim", "file.txt")      # shell out, suspend TUI, resume after
window_title("My App")        # set terminal title
cursor_shape(:bar)            # :block, :bar, :underline, :blinking_*
show_cursor / hide_cursor     # cursor visibility
enter_alt_screen / exit_alt_screen
println("log line")           # print above the TUI area
```

## Options

```ruby
Chamomile.run(model,
  alt_screen: true,          # fullscreen mode (default: true)
  mouse: :cell_motion,       # :none, :cell_motion, :all_motion
  bracketed_paste: true,     # enable paste detection
  report_focus: true,        # enable focus/blur events
  fps: 60,                   # render throttle
  catch_panics: true,        # recover from exceptions
)
```

## Examples

```sh
ruby examples/hello.rb       # minimal hello world
ruby examples/counter.rb     # counter with tick timer
ruby examples/list.rb        # navigable list
ruby examples/mouse.rb       # mouse event display
ruby examples/exec.rb        # shell out to $EDITOR
ruby examples/inline.rb      # non-fullscreen inline mode
```

## Ecosystem

| Gem | Description |
|-----|-------------|
| **chamomile** | Core framework (this gem) |
| **[petals](https://github.com/xjackk/petals)** | Reusable components (Spinner, TextInput, Timer, etc.) |
| **chamomile-lipstick** | ANSI styling — colors, borders, padding (planned) |

## Development

```sh
bundle install
bundle exec rspec        # run tests (269 specs)
bundle exec rubocop      # lint
```

## License

[MIT](LICENSE)
