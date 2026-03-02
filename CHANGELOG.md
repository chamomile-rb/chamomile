# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Renamed `Model#init` to `Model#start` — cleaner Ruby idiom; `start`, `update`, `view` now form a consistent verb-trio API

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
