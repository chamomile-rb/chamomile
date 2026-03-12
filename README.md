# Chamomile

An event-driven Ruby TUI framework. Build interactive terminal applications using declarative callbacks and composable views. Zero runtime dependencies.

## Features

- **Declarative callbacks** — `on_key`, `on_mouse`, `on_tick` DSL for clean event handling
- **Streaming input parser** — ANSI escape sequences, CSI params, SGR mouse, bracketed paste, focus/blur
- **FPS-throttled renderer** — diff rendering in alt-screen, inline mode for non-fullscreen apps
- **Command system** — async commands via threads, parallel/serial composition, tick/every helpers
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
  include Chamomile::Application

  def initialize
    @count = 0
  end

  on_key(:up, "k")   { @count += 1 }
  on_key(:down, "j") { @count -= 1 }
  on_key("q")        { quit }

  def view
    "Count: #{@count}\n\nup/k increment  |  down/j decrement  |  q quit"
  end
end

Chamomile.run(Counter.new)
```

## How It Works

1. **Application** — your class includes `Chamomile::Application` and holds application state
2. **Callbacks** — register event handlers with `on_key`, `on_mouse`, `on_tick`, `on_resize`, etc.
3. **`on_start`** — optional startup hook for timers, data loading, etc.
4. **`view`** — returns a string to render to the terminal
5. **Commands** — lambdas that run in threads and return messages back to the event loop

For complex apps, you can still define `update(msg)` as an escape hatch — it takes precedence over the callback DSL.

## Event Callbacks

```ruby
class MyApp
  include Chamomile::Application

  on_key(:up, "k")  { @y -= 1 }          # multiple keys in one call
  on_key("q")       { quit }              # quit the program
  on_resize         { |e| @w = e.width }  # terminal resize
  on_tick           { refresh_data }       # tick timer events
  on_mouse          { |e| handle(e) }     # mouse events
  on_focus          { @focused = true }    # terminal focus
  on_blur           { @focused = false }   # terminal blur
  on_paste          { |e| @text = e.content }  # paste events
end
```

## Events

| Event | Description |
|-------|-------------|
| `KeyEvent` | Key press with `.key` (Symbol or String) and `.mod` (`:ctrl`, `:alt`, `:shift`) |
| `MouseEvent` | Mouse event with position, button, action, modifiers |
| `PasteEvent` | Bracketed paste content |
| `ResizeEvent` | Terminal resize with `.width` and `.height` |
| `FocusEvent` / `BlurEvent` | Terminal focus changes |
| `TickEvent` | Timer tick with `.time` |
| `InterruptEvent` | Ctrl+C (handle or let it quit) |
| `SuspendEvent` / `ResumeEvent` | Ctrl+Z suspend and resume |

## Commands

Include `Chamomile::Application` (or `Chamomile::Commands`) for these helpers:

```ruby
quit                          # exit the program
tick(1.0)                     # fire a TickEvent after 1 second
every(1.0)                    # fire a TickEvent aligned to wall clock
parallel(cmd1, cmd2)          # run commands concurrently
serial(cmd1, cmd2)            # run commands in order
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
| **[petals](https://github.com/chamomile-rb/petals)** | Reusable TUI components — Spinner, TextInput, Timer, Viewport, Table, List, and more |
| **[flourish](https://github.com/chamomile-rb/flourish)** | Terminal styling — colors, borders, padding, layout composition |

## Development

```sh
bundle install
bundle exec rspec        # run tests
bundle exec rubocop      # lint
```

## License

[MIT](LICENSE)
