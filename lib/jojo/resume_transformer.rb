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

    private

    def get_field(data, field_path)
      parts = field_path.split(".")
      current = data

      parts.each do |key|
        return nil if current.nil?

        current = if current.is_a?(Array)
          current.first&.dig(key)
        else
          current.dig(key)
        end
      end

      current
    end
  end
end
