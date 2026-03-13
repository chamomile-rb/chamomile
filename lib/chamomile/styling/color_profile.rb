# frozen_string_literal: true

module Chamomile
  module ColorProfile
    TRUE_COLOR = :true_color
    ANSI256 = :ansi256
    ANSI = :ansi
    NO_COLOR = :no_color

    # ANSI256 to ANSI16 lookup table
    ANSI256_TO_ANSI = [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, # 0-15: identity
      0, 4, 4, 4, 12, 12,   # 16-21
      2, 6, 4, 4, 12, 12,   # 22-27
      2, 2, 6, 4, 12, 12,   # 28-33
      2, 2, 2, 6, 12, 12,   # 34-39
      10, 10, 10, 10, 14, 12, # 40-45
      10, 10, 10, 10, 10, 14, # 46-51
      1, 5, 4, 4, 12, 12,   # 52-57
      3, 8, 4, 4, 12, 12,   # 58-63
      2, 2, 6, 4, 12, 12,   # 64-69
      2, 2, 2, 6, 12, 12,   # 70-75
      10, 10, 10, 10, 14, 12, # 76-81
      10, 10, 10, 10, 10, 14, # 82-87
      1, 5, 4, 4, 12, 12,   # 88-93
      3, 3, 8, 4, 12, 12,   # 94-99
      2, 2, 2, 6, 12, 12,   # 100-105
      2, 2, 2, 2, 6, 12,    # 106-111
      10, 10, 10, 10, 14, 12, # 112-117
      10, 10, 10, 10, 10, 14, # 118-123
      1, 5, 5, 4, 12, 12,   # 124-129
      3, 3, 8, 4, 12, 12,   # 130-135
      3, 3, 3, 8, 12, 12,   # 136-141
      2, 2, 2, 2, 6, 12,    # 142-147
      10, 10, 10, 10, 14, 12, # 148-153
      10, 10, 10, 10, 10, 14, # 154-159
      9, 5, 5, 5, 13, 12,   # 160-165
      3, 3, 8, 8, 12, 12,   # 166-171
      3, 3, 3, 8, 12, 12,   # 172-177
      3, 3, 3, 3, 8, 12,    # 178-183
      11, 11, 10, 10, 14, 12, # 184-189
      10, 10, 10, 10, 10, 14, # 190-195
      9, 9, 5, 5, 13, 12,   # 196-201
      9, 9, 9, 13, 13, 12,  # 202-207
      3, 3, 3, 8, 8, 12,    # 208-213
      3, 3, 3, 3, 8, 14,    # 214-219
      11, 11, 11, 11, 7, 12, # 220-225
      11, 11, 11, 11, 11, 15, # 226-231
      0, 0, 0, 0, 0, 0,     # 232-237 (grayscale dark)
      8, 8, 8, 8, 8, 8,     # 238-243
      7, 7, 7, 7, 7, 7,     # 244-249
      15, 15, 15, 15, 15, 15, # 250-255 (grayscale light)
    ].freeze

    class << self
      def detect
        return NO_COLOR if ENV.key?("NO_COLOR")

        colorterm = ENV.fetch("COLORTERM", "")
        return TRUE_COLOR if %w[truecolor 24bit].include?(colorterm)

        term = ENV.fetch("TERM", "")
        return ANSI256 if term.include?("256color")
        return ANSI if term.include?("color") || term.include?("ansi")

        ANSI
      end

      def downsample(color, target_profile)
        return Color::NoColor.new if target_profile == NO_COLOR

        case color
        when Color::TrueColor
          case target_profile
          when TRUE_COLOR then color
          when ANSI256 then truecolor_to_256(color)
          when ANSI then ansi256_to_ansi(truecolor_to_256(color))
          end
        when Color::ANSI256Color
          case target_profile
          when TRUE_COLOR, ANSI256 then color
          when ANSI then ansi256_to_ansi(color)
          end
        else # ANSIColor, NoColor, etc.
          color
        end
      end

      private

      def truecolor_to_256(color)
        # Check grayscale ramp first (232-255)
        if color.r == color.g && color.g == color.b
          return Color::ANSI256Color.new(code: 16) if color.r < 8
          return Color::ANSI256Color.new(code: 231) if color.r > 248

          gray_idx = ((color.r.to_f - 8) / 247 * 24).round
          return Color::ANSI256Color.new(code: 232 + gray_idx)
        end

        # Map to 6x6x6 color cube (indices 16-231)
        r_idx = (color.r.to_f / 255 * 5).round
        g_idx = (color.g.to_f / 255 * 5).round
        b_idx = (color.b.to_f / 255 * 5).round

        cube_idx = 16 + (36 * r_idx) + (6 * g_idx) + b_idx

        # Compare cube color distance vs nearest grayscale
        cube_r = r_idx.positive? ? 55 + (r_idx * 40) : 0
        cube_g = g_idx.positive? ? 55 + (g_idx * 40) : 0
        cube_b = b_idx.positive? ? 55 + (b_idx * 40) : 0
        cube_dist = color_distance(color.r, color.g, color.b, cube_r, cube_g, cube_b)

        gray_avg = (color.r + color.g + color.b) / 3
        gray_idx = ((gray_avg.to_f - 8) / 247 * 24).round.clamp(0, 23)
        gray_val = 8 + (10 * gray_idx)
        gray_dist = color_distance(color.r, color.g, color.b, gray_val, gray_val, gray_val)

        if gray_dist < cube_dist
          Color::ANSI256Color.new(code: 232 + gray_idx)
        else
          Color::ANSI256Color.new(code: cube_idx)
        end
      end

      def ansi256_to_ansi(color)
        idx = color.code.clamp(0, 255)
        Color::ANSIColor.new(code: ANSI256_TO_ANSI[idx])
      end

      def color_distance(r1, g1, b1, r2, g2, b2)
        ((r1 - r2)**2) + ((g1 - g2)**2) + ((b1 - b2)**2)
      end
    end
  end
end
