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

      def self.status_icon(status)
        STATUS_ICONS[status] || "?"
      end

      def self.paid_icon(is_paid)
        is_paid ? "💰" : "  "
      end
    end
  end
end
