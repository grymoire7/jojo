module Jojo
  module Prompts
    module Website
      def self.generate_branding_statement(job_description:, resume:, company_name:, seeker_name:, voice_and_tone:, research: nil, job_details: nil)
        <<~PROMPT
          You are an expert at writing compelling personal branding statements for job application landing pages.

          Your task is to create a personalized 2-3 paragraph branding statement (150-250 words) that positions #{seeker_name} as the ideal candidate for this specific company and role.

          # Context

          ## Job Description

          #{job_description}

          #{format_job_details(job_details) if job_details}

          #{research ? "## Company Research\n\n#{research}" : "Note: No company research available - focus on job description analysis."}

          ## Candidate's Resume

          #{resume}

          # Instructions

          ## FOCUS:
          - Answer the question: "Why is #{seeker_name} perfect for THIS company?"
          - Connect candidate's experience to company's specific needs
          - Reference company culture, mission, or values from research
          - Highlight 2-3 most relevant qualifications from resume
          - Make it specific to this opportunity (not generic)

          ## CONTENT STRATEGY:
          - First paragraph: Hook - what makes this match compelling
          - Second paragraph: Relevant experience and expertise
          - Third paragraph (optional): What candidate brings to the company
          - Be authentic and truthful (based on actual resume)
          - Show understanding of company from research insights
          - Avoid generic phrases like "passionate professional" or "results-driven"

          ## VOICE AND TONE:
          #{voice_and_tone}

          Match the company's culture and communication style based on research.

          # Output Requirements

          ## Format:
          - Plain text paragraphs (NO markdown headers or formatting)
          - Natural paragraph breaks (double newline between paragraphs)
          - Conversational but professional
          - First person perspective

          ## Length:
          - Target: 150-250 words total
          - 2-3 paragraphs

          ## Quality Standards:
          - Specific to THIS company and role (not generic)
          - Based entirely on actual resume content (no fabrication)
          - Shows genuine understanding of company/role
          - Compelling and authentic voice
          - Reads naturally, not templated

          # Important:
          - Output ONLY the branding statement text (plain paragraphs)
          - NO headers, NO markdown formatting, NO commentary
          - DO NOT start with "Dear" or "To whom it may concern"
          - DO NOT include name/signature at end
          - Focus on creating a genuine connection between candidate and opportunity
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
