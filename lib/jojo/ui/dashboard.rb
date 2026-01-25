# frozen_string_literal: true

module Jojo
  module UI
    class Dashboard
      STATUS_ICONS = {
        generated: "✅",
        stale: "🍞",
        ready: "⭕",
        blocked: "🔒"
      }.freeze

      FILLED_CHAR = "█"
      EMPTY_CHAR = "░"

      def self.progress_bar(percent, width: 10)
        filled = (percent / 100.0 * width).round
        empty = width - filled

        FILLED_CHAR * filled + EMPTY_CHAR * empty
      end

      def self.status_icon(status)
        STATUS_ICONS[status] || "?"
      end

      def self.paid_icon(is_paid)
        is_paid ? "💰" : "  "
      end

      def self.workflow_line(number, step, status, width: 54)
        label = step[:label]
        paid = paid_icon(step[:paid])
        status_str = status_icon(status)
        status_label = status.to_s.capitalize

        # Format: "  N. Label                    💰   ✅ Generated"
        label_width = 28
        padded_label = label.ljust(label_width)

        "  #{number}. #{padded_label}#{paid}   #{status_str} #{status_label}"
      end
    end
  end
end
