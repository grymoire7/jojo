module Jojo
  module Prompts
    module JobDescription
      # Prompt to extract clean job description from raw HTML/markdown
      def self.extraction_prompt(raw_content)
        <<~PROMPT
          You are helping extract a clean job description from a web page or document.

          The content below may include navigation, footers, ads, and other extraneous text.
          Your task is to extract ONLY the job description itself - the content that describes
          the role, responsibilities, requirements, and company information.

          IMPORTANT:
          - Keep the EXACT wording from the employer - do not paraphrase or rewrite
          - Preserve all formatting (headings, lists, etc.)
          - Include company information if present
          - Remove navigation, footers, sidebars, ads, and unrelated content
          - Output ONLY the job description in markdown format
          - Do not add any commentary or explanations

          RAW CONTENT:

          #{raw_content}

          Please extract the job description:
        PROMPT
      end

      # Prompt to extract structured key details from job description
      def self.key_details_prompt(job_description)
        <<~PROMPT
          You are extracting key details from a job description to create structured data.

          Read the job description below and extract the following information in YAML format:

          - company_name: The name of the company/employer
          - job_title: The exact job title
          - location: Work location (remote, city, etc.)
          - employment_type: Full-time, part-time, contract, etc.
          - experience_level: Junior, mid-level, senior, etc.
          - salary_range: If mentioned (otherwise "not specified")
          - key_technologies: List of 5-10 main technologies/skills mentioned
          - application_deadline: If mentioned (otherwise "not specified")

          JOB DESCRIPTION:

          #{job_description}

          IMPORTANT:
          - Output ONLY valid YAML format
          - Do NOT use markdown code fences (no ```yaml or ```)
          - Do NOT add any explanatory text, commentary, or preamble
          - Do NOT add any text after the YAML
          - Start directly with the YAML structure

          Output the information in this YAML format:

          company_name: ""
          job_title: ""
          location: ""
          employment_type: ""
          experience_level: ""
          salary_range: ""
          key_technologies:
            - ""
          application_deadline: ""
        PROMPT
      end
    end
  end
end
