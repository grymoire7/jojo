module Jojo
  module Prompts
    module CoverLetter
      def self.generate_prompt(job_description:, tailored_resume:, generic_resume:, voice_and_tone:, company_name:, research: nil, job_details: nil, highlight_projects: [])
        <<~PROMPT
          You are an expert cover letter writer helping craft a compelling narrative that complements a tailored resume.

          Your task is to create a cover letter that tells the "WHY THIS COMPANY/ROLE" story, not a resume summary.

          # Job Information

          ## Job Description

          #{job_description}

          #{format_job_details(job_details) if job_details}

          #{research ? "## Company Research\n\n#{research}" : "Note: No company research available - analyze based on job description only."}

          # Candidate Information

          ## Tailored Resume (What They're Submitting)

          #{tailored_resume}

          ## Full Background (For Additional Context)

          #{generic_resume}

          #{projects_section(highlight_projects)}

          # Cover Letter Instructions

          ## FOCUS (The "Why" Story):
          - Express genuine enthusiasm for THIS specific company
          - Explain why this role aligns with career goals/journey
          - Connect personal values to company mission/culture
          - Share what excites you about the opportunity
          - Reference specific company insights from research when available

          ## STRUCTURE (Flexible, Adapt to Company Culture):
          - Typical range: 200-400 words, 2-4 paragraphs
          - Adapt length/formality based on company culture signals
          - Modern startups: brief, direct, authentic
          - Traditional corporations: professional, structured, polished
          - Job level matters: senior roles allow more strategic narrative

          ## CONTENT STRATEGY:
          - DO NOT duplicate resume bullet points
          - DO reference 1-2 key experiences briefly with "why" context
          - DO connect career narrative dots between experiences
          - DO show understanding of company mission/values/culture
          - DO make it personal and authentic
          - DO NOT fabricate experiences or achievements

          ## VOICE AND TONE:
          #{voice_and_tone}

          Match company culture from research:
          - Mirror their language style
          - Reflect their values authentically
          - Adapt formality level appropriately

          # Constraints

          ## PRESERVE (Truthfulness):
          - All experiences must be from the resumes
          - No fabrication of skills, achievements, or qualifications
          - Maintain factual accuracy in all claims
          - Reference only real experiences from candidate's background

          ## CRITICAL: NO TECHNOLOGY/SKILL FABRICATION
          When mentioning technical skills or tools:
          ❌ FORBIDDEN: Claiming experience with technologies not in the resume
          ❌ FORBIDDEN: Inferring skills from similar ones (Vue ≠ React, PostgreSQL ≠ MySQL)
          ✅ ALLOWED: Mentioning technologies exactly as they appear in resume
          ✅ ALLOWED: Describing transferable skills without claiming direct experience

          If resume says "Vue" and job wants "React":
          ❌ WRONG: "I have experience with React and Vue frameworks"
          ✅ RIGHT: "I've built production applications with Vue" (let transferability speak for itself)

          ## AVOID:
          - Generic openings ("I am excited to apply...")
          - Resume repetition (listing bullet points)
          - Overly formal corporate-speak (unless company culture demands it)
          - Fabricated enthusiasm or false connections

          # Output Requirements

          ## Format:
          - Clean markdown
          - Professional but warm structure
          - Natural paragraph breaks
          - ATS-friendly (no special formatting)

          ## Quality Standards:
          - Authentic voice (not templated)
          - Specific to THIS company and role
          - Complements resume (doesn't duplicate)
          - Demonstrates research/understanding
          - Clear connection between candidate and opportunity

          # Important:
          - Output ONLY the cover letter text, no commentary
          - DO NOT include date, address header, or signature block (just the letter body)
          - Focus on authentic storytelling, not generic templates
          - Use research insights to show genuine interest in the company
        PROMPT
      end

      def self.format_job_details(job_details)
        return "" unless job_details

        <<~DETAILS
          ## Structured Job Details

          #{job_details.map { |k, v| "- #{k}: #{v}" }.join("\n")}
        DETAILS
      end

      def self.projects_section(projects)
        return "" if projects.empty?

        <<~SECTION
          ## Projects to Highlight

          Consider naturally weaving these relevant projects into the narrative:

          #{projects.map { |p| "- **#{p[:title]}**: #{p[:description]}" }.join("\n")}

          Use these to demonstrate concrete examples of your qualifications.
        SECTION
      end

      private_class_method :format_job_details, :projects_section
    end
  end
end
