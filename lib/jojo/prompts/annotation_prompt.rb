module Jojo
  module Prompts
    module Annotation
      def self.generate_annotations_prompt(job_description:, resume:, research: nil)
        <<~PROMPT
          You are an expert at analyzing job descriptions and matching candidate qualifications.

          Your task is to identify specific phrases in the job description that match the candidate's experience, and provide evidence from their resume/research.

          # Context

          ## Job Description

          #{job_description}

          #{"## Company Research\n\n#{research}" if research}

          ## Candidate's Resume

          #{resume}

          # Instructions

          ## YOUR TASK:
          Extract specific, matchable phrases from the job description and match them to concrete evidence from the candidate's resume.

          ## WHAT TO EXTRACT:
          - Technical skills (e.g., "Python", "distributed systems", "React")
          - Years of experience (e.g., "5+ years of Ruby")
          - Specific tools/frameworks (e.g., "PostgreSQL", "Docker")
          - Domain knowledge (e.g., "fintech experience", "healthcare domain")
          - Measurable achievements (e.g., "scaled to 1M users")
          - Soft skills with context (e.g., "team leadership", "mentoring")

          ## MATCH CLASSIFICATION:

          **strong** - Direct experience with specific numbers/outcomes
          - Example: "5+ years Python" → "Built Python applications for 7 years at Acme Corp"

          **moderate** - Related experience or transferable skills
          - Example: "team leadership" → "Led team of 3 engineers on authentication project"

          **mention** - Tangential connection or potential to learn
          - Example: "GraphQL" → "Familiar with GraphQL concepts, built REST APIs with similar patterns"

          ## CRITICAL REQUIREMENTS:

          1. Extract text EXACTLY as it appears in job description (critical for matching)
          2. Extract phrases, not full sentences (2-8 words typically)
          3. Provide concrete evidence from resume (specific numbers, companies, projects)
          4. Quality over quantity: 5-8 strong, 3-5 moderate, 0-3 mention
          5. Only annotate if you have real evidence (don't fabricate)
          6. Be truthful and accurate (based on actual resume content)

          # Output Format

          Return ONLY a valid JSON array with this structure:

          [
            {
              "text": "exact phrase from job description",
              "match": "specific evidence from resume",
              "tier": "strong|moderate|mention"
            }
          ]

          ## Example Output:

          [
            {
              "text": "5+ years of Python",
              "match": "Built Python applications for 7 years at Acme Corp and Beta Inc",
              "tier": "strong"
            },
            {
              "text": "distributed systems",
              "match": "Designed fault-tolerant message queue handling 10K msgs/sec",
              "tier": "strong"
            },
            {
              "text": "team leadership",
              "match": "Led team of 3 engineers on authentication project",
              "tier": "moderate"
            }
          ]

          # Important:

          - Output ONLY the JSON array (no commentary, no markdown, no extra text)
          - Ensure valid JSON syntax
          - Extract text EXACTLY as it appears in job description
          - Provide specific, truthful evidence from resume
          - Focus on quality matches, not quantity
        PROMPT
      end
    end
  end
end
