# lib/jojo/commands/resume/prompt.rb
module Jojo
  module Commands
    module Resume
      module Prompt
        def self.generate_prompt(job_description:, generic_resume:, voice_and_tone:, research: nil, job_details: nil, relevant_projects: [])
          <<~PROMPT
            You are an expert resume writer helping tailor a generic resume to a specific job opportunity.

            Your task is to transform the generic resume using CONSERVATIVE TAILORING WITH STRATEGIC PRUNING:
            - Maintain truthfulness and structure
            - Filter out less relevant content (keep 60-80% most relevant)
            - Optimize keyword usage and phrasing

            # Job Information

            ## Job Description

            #{job_description}

            #{format_job_details(job_details) if job_details}

            #{"## Research Insights\n\n#{research}" if research}

            # Source Material

            ## Generic Resume

            #{generic_resume}

            #{projects_section(relevant_projects)}

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

            ## CRITICAL OUTPUT FORMAT:
            - OUTPUT THE RESUME DIRECTLY AS RAW MARKDOWN - NO CODE BLOCKS, NO COMMENTARY
            - DO NOT wrap output in ```markdown...``` code blocks
            - DO NOT add introductory text like "Here is the tailored resume..."
            - DO NOT add explanations or commentary
            - Start IMMEDIATELY with the resume content (e.g., contact info, headers)
            - The output should be a pure markdown file ready to save

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

            # CRITICAL ANTI-FABRICATION RULES

            ## NEVER ADD TECHNOLOGIES/SKILLS/TOOLS NOT IN GENERIC RESUME:
            - FORBIDDEN: If generic resume lists "Vue", DO NOT add "React" or "Vue/React"
            - FORBIDDEN: If generic resume lists "PostgreSQL", DO NOT add "MySQL" or "NoSQL databases"
            - FORBIDDEN: If generic resume lists "Docker", DO NOT add "Kubernetes" or "container orchestration"
            - FORBIDDEN: If generic resume lists "Aider", DO NOT add "Cursor", "GitHub Copilot", or other AI tools
            - FORBIDDEN: If projects mention "Claude" for one project, DO NOT add it as a general development tool
            - ALLOWED: If generic resume lists "Vue", you can say "Vue.js" or "modern JavaScript frameworks"

            ## NEVER ADD EXPERIENCES NOT IN GENERIC RESUME:
            - FORBIDDEN: Adding technologies to "Technologies used:" that weren't in original
            - FORBIDDEN: Claiming experience with tools/frameworks not mentioned in generic resume
            - FORBIDDEN: Inferring skills from similar technologies (Vue != React, Java != Kotlin, Aider != Cursor)
            - FORBIDDEN: Adding development tools even if they're in the same category (AI tools, IDEs, etc.)
            - ALLOWED: Rephrasing existing experiences with different action verbs
            - ALLOWED: Emphasizing existing relevant skills

            ## TRANSFERABLE SKILLS - THE RIGHT WAY:
            If job requires X but resume has similar Y:
            - WRONG: Add X to skills list
            - RIGHT: Emphasize Y and let employer see transferability

            Example: Job wants "React", resume has "Vue"
            - WRONG: "Technologies: Vue, React, Python"
            - RIGHT: "Technologies: Vue, Python" (let Vue speak for itself)

            Example: Job wants "Cursor", resume has "Aider"
            - WRONG: "Development Tools: Aider, Cursor, Git"
            - RIGHT: "Development Tools: Aider, Git" (Aider demonstrates AI-assisted development)

            ## THE ABSOLUTE RULE:
            Every technology, skill, tool, framework, development tool, AI tool, IDE, or achievement in the tailored resume MUST exist EXACTLY as written in the generic resume or relevant projects. No exceptions. No inference. No "close enough." No adding similar tools in the same category.

            When in doubt: OMIT, don't fabricate.

            # Important:
            - Do NOT add experiences, skills, or achievements not in the generic resume or projects
            - Do NOT modify dates or factual details
            - Focus on SELECTING and REPHRASING existing content strategically
            - OUTPUT THE RAW MARKDOWN RESUME ONLY - no code blocks, no preamble, no commentary whatsoever
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
            ## Relevant Projects and Achievements

            The following projects and achievements are particularly relevant to this role:

            #{projects.map { |p| "- **#{p[:title]}**: #{p[:description]}" }.join("\n")}

            Consider emphasizing these in the tailored resume where appropriate.
          SECTION
        end

        private_class_method :format_job_details, :projects_section
      end
    end
  end
end
