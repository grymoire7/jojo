module Jojo
  module Prompts
    module Resume
      def self.generate_prompt(job_description:, generic_resume:, research: nil, job_details: nil, voice_and_tone:)
        <<~PROMPT
          You are an expert resume writer helping tailor a generic resume to a specific job opportunity.

          Your task is to transform the generic resume using CONSERVATIVE TAILORING WITH STRATEGIC PRUNING:
          - Maintain truthfulness and structure
          - Filter out less relevant content (keep 60-80% most relevant)
          - Optimize keyword usage and phrasing

          # Job Information

          ## Job Description

          #{job_description}

          #{job_details ? format_job_details(job_details) : ""}

          #{research ? "## Research Insights\n\n#{research}" : ""}

          # Source Material

          ## Generic Resume

          #{generic_resume}

          # Tailoring Instructions

          ## PRESERVE (Do not modify):
          - All dates, job titles, company names
          - All degrees, certifications, educational credentials
          - Truthfulness of all achievements and responsibilities

          ## PRUNE (Strategic filtering):
          - Remove skills that don't align with job requirements
          - Remove projects/experiences with low relevance
          - Remove bullet points that don't support the target role
          - KEEP 60-80% of most relevant content

          ## OPTIMIZE (Improve without fabrication):
          - Rewrite professional summary to target this specific role
          - Reorder items within sections (most relevant first)
          - Rephrase bullet points to include job description keywords
          - Match company culture and language from research
          - Use action verbs and quantifiable results from original

          # Output Requirements

          ## Format:
          - Clean markdown matching the generic resume structure
          - Same section headings as original resume
          - ATS-friendly (no tables, simple bullets with -)
          - Target 1-2 pages of content

          ## Voice and Tone:
          #{voice_and_tone}

          ## Quality Standards:
          - Every statement must be truthful (no fabrication)
          - Use strong action verbs (led, built, designed, implemented)
          - Include quantifiable results where present in original
          - Maintain professional formatting and consistency

          # Important:
          - Do NOT add experiences, skills, or achievements not in the generic resume
          - Do NOT modify dates or factual details
          - Focus on SELECTING and REPHRASING existing content strategically
          - Output ONLY the tailored resume markdown, no commentary
        PROMPT
      end

      private

      def self.format_job_details(job_details)
        return "" unless job_details

        <<~DETAILS
          ## Structured Job Details

          #{job_details.map { |k, v| "- #{k}: #{v}" }.join("\n")}
        DETAILS
      end
    end
  end
end
