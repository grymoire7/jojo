# lib/jojo/resume_transformer.rb
module Jojo
  class ResumeTransformer
    def initialize(ai_client:, config:, job_context:)
      @ai_client = ai_client
      @config = config
      @job_context = job_context
    end

    def transform(data)
      # To be implemented
      data
    end
  end
end
