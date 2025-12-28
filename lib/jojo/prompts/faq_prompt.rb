module Jojo
  module Prompts
    module Faq
      def self.generate_faq_prompt(job_description:, resume:, research:, job_details:, base_url:, seeker_name:, voice_and_tone:)
        <<~PROMPT
          #{job_description}
        PROMPT
      end
    end
  end
end
