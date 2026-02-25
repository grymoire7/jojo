# lib/jojo/commands/faq/prompt.rb
module Jojo
  module Commands
    module Faq
      module Prompt
        def self.generate_prompt(job_description:, resume:, research:, job_details:, base_url:, seeker_name:, voice_and_tone:)
          company_name = (job_details && job_details["company_name"]) ? job_details["company_name"] : "this company"
          company_slug = company_name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")

          <<~PROMPT
            You are an expert at creating engaging FAQ sections for job application landing pages.

            Your task is to generate 5-8 frequently asked questions with comprehensive answers that showcase the candidate's qualifications and fit for this specific role.

            # Context

            ## Job Description

            #{job_description}

            #{"## Company Research\n\n#{research}" if research}

            ## Candidate's Resume

            #{resume}

            ## Additional Information

            - Candidate Name: #{seeker_name}
            - Company Name: #{company_name}
            - Voice and Tone: #{voice_and_tone}
            - Base URL: #{base_url}

            # Instructions

            Generate 5-8 FAQ questions covering these categories:

            1. **Tech stack/Tools** - Specific experience with technologies mentioned in job description
            2. **Remote work** - Setup, preferences, timezone, communication practices
            3. **AI philosophy** - How candidate uses AI tools, philosophy on AI in development
            4. **Why this company/Role** - Tailored motivation based on research insights (if available)
            5. **Role-Specific Questions** - 1-2 questions unique to this job
            6. **Resume & Cover Letter Downloads** - Dedicated FAQ with PDF download links

            ## Answer Guidelines

            - Length: 50-150 words per answer
            - Use specific evidence from resume (numbers, companies, projects)
            - Reference research insights when explaining "why this company"
            - Maintain #{voice_and_tone} voice and tone
            - Be honest and accurate (no fabrication)
            - For the documents FAQ, use HTML links: <a href="URL">Link Text</a>

            ## CRITICAL: NO TECHNOLOGY/SKILL/TOOL FABRICATION

            When answering questions about technical experience, tools, or interests:
            - FORBIDDEN: Mentioning technologies/tools not in the resume
            - FORBIDDEN: Claiming interest in or use of tools from job description not in resume
            - FORBIDDEN: Inferring tools from similar ones (Aider != Cursor != GitHub Copilot)
            - ALLOWED: Mentioning technologies/tools exactly as they appear in resume
            - ALLOWED: Describing transferable skills without fabricating direct experience
            - ALLOWED: Acknowledging interest in company's tools (e.g., "excited to work with your team's use of X")

            Example: Resume has "Aider", job mentions "Cursor"
            - WRONG: "I use tools like Cursor and Aider for AI-assisted development"
            - RIGHT: "I use Aider for AI-assisted development"
            - ALSO RIGHT: "I'm experienced with AI-assisted development tools"

            ## Document URLs

            - Resume: #{base_url}/resume/#{company_slug}
            - Cover Letter: #{base_url}/cover_letter/#{company_slug}

            # Output Format

            OUTPUT THE RAW JSON ARRAY ONLY - NO CODE BLOCKS, NO COMMENTARY
            - DO NOT wrap output in ```json...``` code blocks
            - DO NOT add introductory text or explanations
            - Start IMMEDIATELY with the opening bracket [
            - Return ONLY a valid JSON array with this structure:

            ```json
            [
              {
                "question": "Question text ending with ?",
                "answer": "Answer text with specific evidence..."
              }
            ]
            ```

            ## Example Output

            ```json
            [
              {
                "question": "What's your experience with Python and distributed systems?",
                "answer": "I have 7 years of Python experience, including building distributed systems at Acme Corp that handled 50,000 requests per second. I designed a fault-tolerant message queue using RabbitMQ and implemented service discovery with Consul."
              },
              {
                "question": "How do you approach remote work?",
                "answer": "I've worked remotely for 5 years across Pacific and Eastern time zones. I maintain strong async communication through detailed PR descriptions and documentation. I use Slack for quick questions, Zoom for pair programming, and have a dedicated home office with fiber internet."
              },
              {
                "question": "Where can I find your resume and cover letter?",
                "answer": "You can download my full resume and cover letter tailored specifically for this role: <a href=\\"#{base_url}/resume/#{company_slug}\\">View Resume</a> | <a href=\\"#{base_url}/cover_letter/#{company_slug}\\">View Cover Letter</a>"
              }
            ]
            ```

            # Important

            - OUTPUT THE RAW JSON ARRAY ONLY - no code blocks, no preamble, no commentary whatsoever
            - Ensure valid JSON syntax
            - All questions must end with "?"
            - Include the resume/cover letter download FAQ
            - Focus on quality over quantity (5-8 total FAQs)
          PROMPT
        end
      end
    end
  end
end
