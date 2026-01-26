# frozen_string_literal: true

module Jojo
  module Workflow
    STEPS = [
      {
        key: :job_description,
        label: "Job Description",
        dependencies: [],
        command: :job_description,
        paid: false,
        output_file: "job_description.md"
      },
      {
        key: :research,
        label: "Research",
        dependencies: [:job_description],
        command: :research,
        paid: true,
        output_file: "research.md"
      },
      {
        key: :resume,
        label: "Resume",
        dependencies: [:job_description, :research],
        command: :resume,
        paid: true,
        output_file: "resume.md"
      },
      {
        key: :cover_letter,
        label: "Cover Letter",
        dependencies: [:resume],
        command: :cover_letter,
        paid: true,
        output_file: "cover_letter.md"
      },
      {
        key: :annotations,
        label: "Annotations",
        dependencies: [:job_description],
        command: :annotate,
        paid: true,
        output_file: "job_description_annotations.json"
      },
      {
        key: :faq,
        label: "FAQ",
        dependencies: [:job_description, :resume],
        command: :faq,
        paid: true,
        output_file: "faq.json"
      },
      {
        key: :branding,
        label: "Branding Statement",
        dependencies: [:job_description, :resume, :research],
        command: :branding,
        paid: true,
        output_file: "branding.md"
      },
      {
        key: :website,
        label: "Website",
        dependencies: [:resume, :annotations, :faq],
        command: :website,
        paid: false,
        output_file: "website/index.html"
      },
      {
        key: :pdf,
        label: "PDF",
        dependencies: [:resume, :cover_letter],
        command: :pdf,
        paid: false,
        output_file: "resume.pdf"
      }
    ].freeze

    def self.file_path(step_key, employer)
      step = STEPS.find { |s| s[:key] == step_key }
      raise ArgumentError, "Unknown step: #{step_key}" unless step

      File.join(employer.base_path, step[:output_file])
    end

    def self.status(step_key, employer)
      step = STEPS.find { |s| s[:key] == step_key }
      raise ArgumentError, "Unknown step: #{step_key}" unless step

      output_path = file_path(step_key, employer)
      output_exists = File.exist?(output_path)

      # Check if all dependencies are met
      deps_met = step[:dependencies].all? do |dep_key|
        File.exist?(file_path(dep_key, employer))
      end

      return :blocked unless deps_met
      return :ready unless output_exists

      # Check for staleness
      output_mtime = File.mtime(output_path)
      stale = step[:dependencies].any? do |dep_key|
        dep_path = file_path(dep_key, employer)
        File.exist?(dep_path) && File.mtime(dep_path) > output_mtime
      end

      stale ? :stale : :generated
    end

    def self.all_statuses(employer)
      STEPS.each_with_object({}) do |step, hash|
        hash[step[:key]] = status(step[:key], employer)
      end
    end

    def self.missing_dependencies(step_key, employer)
      step = STEPS.find { |s| s[:key] == step_key }
      raise ArgumentError, "Unknown step: #{step_key}" unless step

      step[:dependencies].reject do |dep_key|
        File.exist?(file_path(dep_key, employer))
      end.map do |dep_key|
        STEPS.find { |s| s[:key] == dep_key }[:label]
      end
    end

    def self.progress(employer)
      statuses = all_statuses(employer)
      generated_count = statuses.values.count(:generated)
      total = STEPS.length

      ((generated_count.to_f / total) * 100).round
    end
  end
end
