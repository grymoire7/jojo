# frozen_string_literal: true

# lib/jojo/commands/interactive/dashboard.rb

module Jojo
  module Commands
    module Interactive
      class Dashboard
        STATUS_ICONS = {
          generated: "✓",
          stale: "*",
          ready: "○",
          blocked: "×"
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
          is_paid ? "$" : " "
        end

        def self.workflow_line(number, step, status, width: 54)
          label = step[:label]
          paid = paid_icon(step[:paid])
          status_str = status_icon(status)
          status_label = status.to_s.capitalize

          # Format: "  N. Label                    $   ✓ Generated"
          label_width = 28
          padded_label = label.ljust(label_width)

          "  #{number}. #{padded_label}#{paid}   #{status_str} #{status_label}"
        end

        def self.render(application)
          require "tty-box"

          statuses = Workflow.all_statuses(application)
          width = 56

          lines = []

          # Header
          lines << "  Active: #{application.slug}"
          lines << "  Company: #{application.company_name}"
          lines << ""
          lines << "  Workflow" + " " * 29 + "Status"
          lines << "  " + "─" * 50

          # Workflow items
          Workflow::STEPS.each_with_index do |step, idx|
            status = statuses[step[:key]]
            lines << workflow_line(idx + 1, step, status, width: width)
          end

          lines << ""
          lines << "  Status: ✓ Generated  * Stale  ○ Ready  × Blocked"
          lines << ""
          lines << "  [1-9] Generate item    [a] All ready    [q] Quit"
          lines << "  [o] Open folder    [s] Switch application"

          TTY::Box.frame(
            lines.join("\n"),
            title: {top_left: " Jojo "},
            padding: [0, 1],
            border: :thick
          )
        end
      end
    end
  end
end
