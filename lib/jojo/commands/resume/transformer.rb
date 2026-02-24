# lib/jojo/commands/resume/transformer.rb
require "json"
require_relative "../../errors"

module Jojo
  module Commands
    module Resume
      class Transformer
        def initialize(ai_client:, config:, job_context:)
          @ai_client = ai_client
          @config = config
          @job_context = job_context
        end

        def transform(data)
          # Handle both Config objects and hashes
          config_hash = @config.respond_to?(:to_h) ? @config.to_h : @config
          permissions = config_hash.dig("resume_data", "permissions") || {}

          permissions.each do |field_path, perms|
            next unless perms.is_a?(Array)

            # Apply transformations in order
            if perms.include?("remove")
              filter_field(field_path, data)
            end

            if perms.include?("reorder")
              reorder_field(field_path, data, can_remove: perms.include?("remove"))
            end

            if perms.include?("rewrite")
              rewrite_field(field_path, data)
            end
          end

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

        def rewrite_field(field_path, data)
          parts = field_path.split(".")
          *parent_path, key = parts

          if parent_path.empty?
            original = data[key]
            return unless original.is_a?(String)
            data[key] = call_rewrite_ai(original)
          else
            parent = parent_path.reduce(data) { |obj, k| obj[k] }
            if parent.is_a?(Array)
              parent.each do |item|
                original = item[key]
                next unless original.is_a?(String)
                item[key] = call_rewrite_ai(original)
              end
            else
              original = parent&.dig(key)
              return unless original.is_a?(String)
              parent[key] = call_rewrite_ai(original)
            end
          end
        end

        def call_rewrite_ai(original)
          prompt = <<~PROMPT
            Tailor this content for the specific job opportunity.

            CRITICAL: Use ONLY information present in the original content below.
            DO NOT add, invent, or imply experience with any technology, framework, or skill
            that is not explicitly mentioned in the original content.
            DO NOT claim proficiency in languages, tools, or frameworks absent from the original.

            Job Description:
            #{@job_context[:job_description]}

            Original Content:
            #{original}

            Return only the tailored content, no explanations.
          PROMPT

          @ai_client.generate_text(prompt)
        end
      end
    end
  end
end
