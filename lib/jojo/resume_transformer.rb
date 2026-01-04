# lib/jojo/resume_transformer.rb
require "json"

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

    def set_field(data, field_path, value)
      parts = field_path.split(".")
      *path, key = parts

      if path.empty?
        # Top-level field
        data[key] = value
      else
        # Navigate to parent
        target = path.reduce(data) { |obj, k| obj[k] }

        if target.is_a?(Array)
          # Setting field on array items
          target.each { |item| item[key] = value }
        else
          target[key] = value
        end
      end
    end

    def filter_field(field_path, data)
      items = get_field(data, field_path)
      return unless items.is_a?(Array)

      # Simple, focused prompt
      prompt = <<~PROMPT
        Filter these items by relevance to the job description.
        Keep approximately 70% of the most relevant items.

        Job Description:
        #{@job_context[:job_description]}

        Items (JSON):
        #{items.to_json}

        Return ONLY a JSON array of indices to keep (e.g., [0, 2, 3]).
        No explanations, just the JSON array.
      PROMPT

      response = @ai_client.generate_text(prompt)
      indices = JSON.parse(response)
      filtered = indices.map { |i| items[i] }

      set_field(data, field_path, filtered)
    end
  end
end
