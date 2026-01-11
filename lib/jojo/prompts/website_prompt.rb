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

          ## CRITICAL: NO TECHNOLOGY/SKILL/TOOL FABRICATION
          When mentioning technical expertise, tools, or interests:
          ❌ FORBIDDEN: Claiming experience with technologies not in the resume
          ❌ FORBIDDEN: Claiming interest in or enthusiasm for tools not in the resume
          ❌ FORBIDDEN: Inferring skills from similar ones (Vue ≠ React, Java ≠ Kotlin, Aider ≠ Cursor)
          ❌ FORBIDDEN: Mentioning development tools from job description as if candidate uses them
          ✅ ALLOWED: Mentioning technologies exactly as they appear in resume
          ✅ ALLOWED: Highlighting transferable skills authentically
          ✅ ALLOWED: Acknowledging company's use of tools (e.g., "excited to work with your team's use of Cursor")

          Example: Resume has "Vue", job wants "React"
          ❌ WRONG: "expertise spans...Ruby on Rails, React, AWS"
          ✅ RIGHT: "expertise spans...Ruby on Rails, Vue, AWS"

          Example: Resume has "Aider", job mentions "Cursor" and "Claude"
          ❌ WRONG: "enthusiasm for exploring tools like Cursor and Claude"
          ✅ RIGHT: "experience with AI-assisted development tools like Aider"
          ✅ ALSO RIGHT: "excited to join a team leveraging cutting-edge AI tools"

          # Important:
          - Output ONLY the branding statement text (plain paragraphs)
          - NO headers, NO markdown formatting, NO commentary
          - DO NOT start with "Dear" or "To whom it may concern"
          - DO NOT include name/signature at end
          - DO NOT ask for confirmation or permission to proceed
          - DO NOT say "I've reviewed the context" or similar meta-commentary
          - START IMMEDIATELY with the first paragraph of the branding statement
          - Focus on creating a genuine connection between candidate and opportunity
        PROMPT
      end

      def self.format_job_details(job_details)
        return "" unless job_details

        <<~DETAILS
          ## Structured Job Details

          #{job_details.map { |k, v| "- #{k}: #{v}" }.join("\n")}
        DETAILS
      end

      private_class_method :format_job_details
    end
  end
end
