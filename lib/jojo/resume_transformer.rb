# lib/jojo/resume_transformer.rb
require "json"
require_relative "errors"

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

    def reorder_field(field_path, data, can_remove:)
      items = get_field(data, field_path)
      return unless items.is_a?(Array)

      original_count = items.length

      # Simple, focused prompt
      prompt = <<~PROMPT
        Reorder these items by relevance to the job description.
        Most relevant should be first.

        Job Description:
        #{@job_context[:job_description]}

        Items (JSON):
        #{items.to_json}

        Return ONLY a JSON array of indices in new order (e.g., [2, 0, 1]).
        #{"CRITICAL: Return ALL #{items.length} indices." unless can_remove}
        No explanations, just the JSON array.
      PROMPT

      response = @ai_client.generate_text(prompt)
      indices = JSON.parse(response)

      # Ruby enforces the permission
      unless can_remove
        if indices.length != original_count
          raise PermissionViolation,
            "LLM removed items from reorder-only field: #{field_path}"
        end

        if indices.sort != (0...original_count).to_a
          raise PermissionViolation,
            "LLM returned invalid indices for field: #{field_path}"
        end
      end

      reordered = indices.map { |i| items[i] }
      set_field(data, field_path, reordered)
    end
  end
end
