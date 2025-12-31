module Jojo
  module Prompts
    module Research
      def self.generate_prompt(job_description:, company_name:, web_results: nil, resume: nil)
        <<~PROMPT
          You are a career coach helping a job seeker research a company and role to prepare
          for tailoring their application materials (resume and cover letter).

          Generate comprehensive research that will help tailor application materials effectively.

          # Available Information

          ## Job Description

          #{job_description}

          ## Company Information

          Company Name: #{company_name}

          #{web_results ? "Web Research Results:\n\n#{web_results}" : "Note: no additional web research available - analyze based on job description only."}

          #{"## Job Seeker's Background\n\n#{resume}" if resume}

          # Your Task

          Analyze the above information and generate a structured research document with the following sections:

          ## 1. Company Profile (~200-300 words)

          - Mission, values, and culture (from web search + job description language)
          - Recent news, achievements, or changes
          - Products/services overview
          - Tech stack and engineering practices (if discoverable)

          ## 2. Role Analysis (~200-300 words)

          - Core responsibilities breakdown
          - Required vs. nice-to-have skills categorized
          - What success looks like in this role (inferred from job description)
          - Team context and reporting structure (if mentioned)

          #{resume ? role_positioning_section : generic_recommendations_section}

          ## 4. Tailoring Recommendations (~200 words)

          - Specific keywords and phrases to incorporate
          - Cultural language to mirror
          #{resume ? "- Projects/experiences from resume to highlight" : "- General guidance on what to emphasize"}
          - Tone/voice suggestions based on company culture

          # Important Instructions

          - Use your reasoning capabilities to read between the lines
          - Infer culture from word choice and phrasing
          - Identify implicit requirements not explicitly stated
          - Be specific and actionable in your recommendations
          - Format output as clean markdown with clear section headers
          #{resume ? "- Focus on how THIS specific candidate can position themselves" : "- Provide general positioning advice"}
        PROMPT
      end

      def self.role_positioning_section
        <<~SECTION
          ## 3. Strategic Positioning (~300-400 words)

          - Gap analysis: What they need vs. what the seeker offers
          - Top 3-5 selling points to emphasize in resume/cover letter
          - Technologies/experiences from resume that align with job requirements
          - Potential concerns to address or reframe
        SECTION
      end

      def self.generic_recommendations_section
        <<~SECTION
          ## 3. Key Requirements (~300 words)

          Note: Without the job seeker's background, providing generic recommendations.

          - Most critical requirements for this role
          - Technologies and skills to emphasize
          - Experience level expectations
          - Suggestions for what a strong candidate would highlight
        SECTION
      end

      private_class_method :role_positioning_section, :generic_recommendations_section
    end
  end
end
