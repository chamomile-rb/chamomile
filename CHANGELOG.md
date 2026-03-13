# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-12

### Added

- **Styling** (merged from Flourish): `Chamomile::Style`, `Chamomile::Border`, `Chamomile::Color`, `Chamomile::ColorProfile`, `Chamomile::ANSI`, `Chamomile::Wrap`, `Chamomile::Align`, `Chamomile::Join`, `Chamomile::Place`
- **Components** (merged from Petals): `Chamomile::TextInput`, `Chamomile::TextArea`, `Chamomile::Table`, `Chamomile::List`, `Chamomile::Viewport`, `Chamomile::Spinner`, `Chamomile::Progress`, `Chamomile::Timer`, `Chamomile::Stopwatch`, `Chamomile::Paginator`, `Chamomile::Cursor`, `Chamomile::Help`, `Chamomile::FilePicker`, `Chamomile::KeyBinding`, `Chamomile::LogView`, `Chamomile::CommandPalette`, `Chamomile::RenderCache`
- Position constants: `Chamomile::TOP`, `LEFT`, `CENTER`, `BOTTOM`, `RIGHT`
- Module-level helpers: `Chamomile.width`, `.height`, `.size`, `.horizontal`, `.vertical`, `.place`
- Backward-compatible shims: `require "flourish"` and `require "petals"` still work (with deprecation warning)
- `Chamomile::Application` — single mixin that includes both Model and Commands
- Declarative callback DSL: `on_key`, `on_resize`, `on_tick`, `on_mouse`, `on_focus`, `on_blur`, `on_paste`
- `on_start` lifecycle hook — imperative alternative to `start` returning a command
- `parallel`/`serial` command helpers (aliases for `batch`/`sequence`)
- `Frame.build` view DSL with Panel, Text, HorizontalLayout, VerticalLayout, StatusBar widgets
- Event type aliases: `KeyEvent`, `MouseEvent`, `ResizeEvent`, `TickEvent`, `FocusEvent`, `BlurEvent`, `PasteEvent`, `InterruptEvent`, `SuspendEvent`, `ResumeEvent`, `ErrorEvent`, `QuitEvent`
- Command type aliases: `ExecCommand`, `PrintlnCommand`, `WindowTitleCommand`, `CursorShapeCommand`, `CursorPositionCommand`, `CursorVisibilityCommand`, `CancelCommand`, `StreamCommand`

### Changed

- Renamed `Model#init` to `Model#start` — cleaner Ruby idiom; `start`, `update`, `view` now form a consistent verb-trio API
- All event types renamed from `*Msg` to `*Event` (old names kept as backward-compatible aliases)
- All command types renamed from `*Cmd` to `*Command` (old names kept as backward-compatible aliases)
- `WindowSizeMsg` renamed to `ResizeEvent` (old name kept as alias)
- README rewritten: removed Elm Architecture references, uses event-driven terminology
- All examples updated to use `Chamomile::Application` and callback DSL

## [0.1.0] - 2026-02-27

### Added

- Elm Architecture core: Model module, Program event loop, command system
- Message types: KeyMsg, MouseMsg, PasteMsg, FocusMsg, BlurMsg, WindowSizeMsg, TickMsg, and more
- EscapeParser: streaming state-machine parser for ANSI sequences, CSI params, SGR mouse, bracketed paste
- Renderer: FPS-throttled diff rendering (alt-screen), inline mode, synchronized output
- InputReader: background thread stdin reader with EscapeParser integration
- Commands: quit, batch, sequence, tick, every, exec, cursor control, alt screen toggling
- Options: immutable configuration with validation (mouse modes, FPS, filters)
- KeyMap: backward-compatible sequence-to-message translator
- Logging: thread-safe file logger
- Signal handling: SIGWINCH, SIGINT, SIGTERM, SIGTSTP/SIGCONT
- Panic recovery with catch_panics option
- Zero runtime dependencies
