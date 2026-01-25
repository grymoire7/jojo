# frozen_string_literal: true

module Jojo
  module Workflow
    STEPS = [
      {
        key: :job_description,
        label: "Job Description",
        dependencies: [],
        command: :new,
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
  end
end
