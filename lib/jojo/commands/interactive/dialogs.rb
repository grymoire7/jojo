# frozen_string_literal: true

# lib/jojo/commands/interactive/dialogs.rb

require "tty-box"

module Jojo
  module Commands
    module Interactive
      class Dialogs
        def self.blocked_dialog(label, missing_deps)
          lines = []
          lines << "  Cannot generate yet. Missing prerequisites:"
          lines << ""
          missing_deps.each do |dep|
            lines << "    • #{dep} (not generated)"
          end
          lines << ""
          lines << "  [Esc] Back"

          TTY::Box.frame(
            lines.join("\n"),
            title: {top_left: " #{label} "},
            padding: [0, 1],
            border: :thick
          )
        end

        def self.ready_dialog(label, inputs, output_files, paid: false)
          paid_str = paid ? " $" : ""

          lines = []
          lines << "  Generate #{label.downcase}?#{paid_str}"
          lines << ""
          lines << "  Inputs:"
          inputs.each do |input|
            age_str = input[:age] ? " (#{input[:age]})" : ""
            lines << "    • #{input[:name]}#{age_str}"
          end
          lines << ""
          lines << "  Output:"
          output_files.each { |f| lines << "    • #{f}" }
          lines << ""
          lines << "  [Enter] Generate    [Esc] Back"

          TTY::Box.frame(
            lines.join("\n"),
            title: {top_left: " #{label} "},
            padding: [0, 1],
            border: :thick
          )
        end

        def self.generated_dialog(label, age, output_files:, paid: false)
          paid_str = paid ? " $" : ""

          lines = []
          output_files.each_with_index do |f, i|
            lines << if i == 0
              "  #{f} already exists (generated #{age})"
            else
              "  #{f}"
            end
          end
          lines << ""
          lines << "  [r] Regenerate#{paid_str}    [v] View    [Esc] Back"

          TTY::Box.frame(
            lines.join("\n"),
            title: {top_left: " #{label} "},
            padding: [0, 1],
            border: :thick
          )
        end

        def self.error_dialog(label, error_message)
          lines = []
          lines << ""
          lines << "  #{label} generation failed:"
          lines << ""
          lines << "  #{error_message}"
          lines << ""
          lines << "  [r] Retry    [v] View full error    [Esc] Back"

          TTY::Box.frame(
            lines.join("\n"),
            title: {top_left: " Error "},
            padding: [0, 1],
            border: :thick
          )
        end

        def self.input_dialog(title, prompt)
          lines = []
          lines << ""
          lines << "  #{prompt}"
          lines << "  > "
          lines << ""

          TTY::Box.frame(
            lines.join("\n"),
            title: {top_left: " #{title} "},
            padding: [0, 1],
            border: :thick
          )
        end
      end
    end
  end
end
