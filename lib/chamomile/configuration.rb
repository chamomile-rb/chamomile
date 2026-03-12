# frozen_string_literal: true

module Chamomile
  # Block-style configuration for Chamomile.run.
  #
  #   Chamomile.run(MyApp.new) do |config|
  #     config.alt_screen = true
  #     config.mouse      = :cell_motion
  #     config.fps        = 30
  #   end
  class Configuration
    attr_accessor :alt_screen, :mouse, :bracketed_paste,
                  :report_focus, :fps, :catch_panics

    def initialize
      @alt_screen      = true
      @mouse           = :none
      @bracketed_paste = true
      @report_focus    = false
      @fps             = 60
      @catch_panics    = true
    end

    def to_h
      {
        alt_screen: @alt_screen,
        mouse: @mouse,
        bracketed_paste: @bracketed_paste,
        report_focus: @report_focus,
        fps: @fps,
        catch_panics: @catch_panics,
      }
    end
  end
end
