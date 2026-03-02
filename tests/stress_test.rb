#!/usr/bin/env ruby
# frozen_string_literal: true

# Chamomile Stress Test
#
# Tests: keyboard input, mouse tracking, paste, focus/blur, resize,
# rapid ticking, alt combos, modifier keys, quit/interrupt handling.
#
# Usage: ruby tests/stress_test.rb

require_relative "../lib/chamomile"

class StressTest
  include Chamomile::Model
  include Chamomile::Commands

  SECTIONS = %i[keys mouse events stress].freeze

  def initialize
    @tab = 0
    @key_log = []
    @mouse_log = []
    @event_log = []
    @tick_count = 0
    @ticks_per_sec = 0
    @last_tick_time = nil
    @tick_burst = 0
    @width = 80
    @height = 24
    @paste_count = 0
    @last_paste_preview = ""
    @focus = true
    @error_msg = nil
  end

  def start
    tick(0.1)
  end

  def update(msg)
    @error_msg = nil

    case msg
    when Chamomile::KeyMsg
      handle_key(msg)
    when Chamomile::MouseMsg
      handle_mouse(msg)
    when Chamomile::PasteMsg
      handle_paste(msg)
    when Chamomile::FocusMsg
      @focus = true
      log_event("Focus gained")
      nil
    when Chamomile::BlurMsg
      @focus = false
      log_event("Focus lost")
      nil
    when Chamomile::WindowSizeMsg
      @width = msg.width
      @height = msg.height
      log_event("Resize: #{msg.width}x#{msg.height}")
      nil
    when Chamomile::TickMsg
      handle_tick(msg)
    when Chamomile::InterruptMsg
      log_event("InterruptMsg received — quitting")
      quit
    else
      log_event("Unknown: #{msg.class.name}")
      nil
    end
  end

  def view
    lines = []
    lines << bar("Chamomile Stress Test", @width)
    lines << ""

    case SECTIONS[@tab]
    when :keys
      lines << section("Keyboard Input")
      lines << "Last #{[@key_log.length, 12].min} keys:"
      @key_log.last(12).each { |k| lines << "  #{k}" }
      lines << "" while lines.length < 18
      lines << "Type keys, arrows, ctrl+combos, alt+combos, function keys"
      lines << "Press Tab to switch sections"
    when :mouse
      lines << section("Mouse Tracking")
      lines << "Last #{[@mouse_log.length, 12].min} events:"
      @mouse_log.last(12).each { |m| lines << "  #{m}" }
      lines << "" while lines.length < 18
      lines << "Click, drag, scroll, shift+click, ctrl+click"
    when :events
      lines << section("Events & Paste")
      lines << "Pastes received: #{@paste_count}"
      lines << "Last paste: #{@last_paste_preview}" unless @last_paste_preview.empty?
      lines << "Focus: #{@focus ? "yes" : "no"}"
      lines << "Window: #{@width}x#{@height}"
      lines << ""
      lines << "Last #{[@event_log.length, 8].min} events:"
      @event_log.last(8).each { |e| lines << "  #{e}" }
      lines << "" while lines.length < 18
      lines << "Paste text, resize terminal, switch focus"
    when :stress
      lines << section("Tick Stress")
      lines << "Ticks: #{@tick_count}"
      lines << "Rate:  ~#{@ticks_per_sec}/sec"
      lines << "Burst: #{@tick_burst} (rapid ticks in last batch)"
      lines << ""
      lines << "The tick counter should increment steadily at ~10/sec."
      lines << "If it freezes or jumps, there's a concurrency issue."
      lines << "" while lines.length < 18
    end

    lines << ""
    lines << status_bar
    lines << @error_msg if @error_msg

    lines.join("\n")
  end

  private

  def handle_key(msg)
    case msg.key
    when :tab
      @tab = (@tab + 1) % SECTIONS.length
    when "q"
      return quit unless msg.ctrl?

      @key_log << format_key(msg)
    else
      @key_log << format_key(msg)
    end
    @key_log.shift while @key_log.length > 50
    nil
  end

  def handle_mouse(msg)
    entry = "#{msg.action} #{msg.button} @ (#{msg.x},#{msg.y})"
    entry += " [#{msg.mod.join(",")}]" unless msg.mod.empty?
    @mouse_log << entry
    @mouse_log.shift while @mouse_log.length > 50
    nil
  end

  def handle_paste(msg)
    @paste_count += 1
    preview = msg.content.gsub("\n", "\\n").gsub("\t", "\\t")
    @last_paste_preview = preview.length > 60 ? "#{preview[0..57]}..." : preview
    log_event("Paste: #{msg.content.length} chars")
    nil
  end

  def handle_tick(msg)
    now = msg.time
    @tick_count += 1

    if @last_tick_time
      delta = now - @last_tick_time
      @ticks_per_sec = (1.0 / delta).round(1) if delta.positive?
      @tick_burst = delta < 0.05 ? @tick_burst + 1 : 0
    end
    @last_tick_time = now

    tick(0.1)
  end

  def log_event(str)
    @event_log << "#{Time.now.strftime("%H:%M:%S")} #{str}"
    @event_log.shift while @event_log.length > 50
  end

  def format_key(msg)
    mods = msg.mod.map(&:to_s).join("+")
    key_str = msg.key.is_a?(Symbol) ? msg.key.to_s : msg.key.inspect
    mods.empty? ? key_str : "#{mods}+#{key_str}"
  end

  def bar(title, width)
    padding = [(width - title.length - 2) / 2, 0].max
    "#{"-" * padding} #{title} #{"-" * padding}"
  end

  def section(name)
    "[#{name}]"
  end

  def status_bar
    tabs = SECTIONS.each_with_index.map do |s, i|
      i == @tab ? "[#{s.upcase}]" : " #{s} "
    end.join(" | ")
    "#{tabs}  |  q=quit  Tab=next"
  end
end

Chamomile.run(StressTest.new, mouse: :all_motion, report_focus: true)
