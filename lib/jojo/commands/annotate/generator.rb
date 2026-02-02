# lib/jojo/commands/annotate/generator.rb
require "json"
require_relative "prompt"

module Jojo
  module Commands
    module Annotate
      class Generator
        attr_reader :employer, :ai_client, :verbose, :overwrite_flag, :cli_instance

        def initialize(employer, ai_client, verbose: false, overwrite_flag: nil, cli_instance: nil)
          @employer = employer
          @ai_client = ai_client
          @verbose = verbose
          @overwrite_flag = overwrite_flag
          @cli_instance = cli_instance
        end

        def generate
          say("Gathering inputs for annotation generation...")
          inputs = gather_inputs

          say("Building annotation prompt...")
          prompt = build_prompt(inputs)

          say("Generating annotations using AI (reasoning model)...")
          annotations_json = ai_client.reason(prompt)

          say("Parsing JSON response...")
          annotations = parse_annotations(annotations_json)

          say("Saving annotations to #{employer.job_description_annotations_path}...")
          save_annotations(annotations)

          logsay("Annotation generation complete! Generated #{annotations.length} annotations.")
          annotations
        end

        private

        def gather_inputs
          unless File.exist?(employer.job_description_path)
            raise "Job description not found at #{employer.job_description_path}"
          end
          job_description = File.read(employer.job_description_path)

          unless File.exist?(employer.resume_path)
            message = "Error: Resume not found at #{employer.resume_path}"
            log(message, step: :annotations, status: "failed")
            raise message
          end
          resume = File.read(employer.resume_path)

          research = read_research

          {
            job_description: job_description,
            resume: resume,
            research: research
          }
        end

        def read_research
          unless File.exist?(employer.research_path)
            logsay("Warning: Research not found, annotations will be based on job description only")
            return nil
          end

          File.read(employer.research_path)
        end

        def build_prompt(inputs)
          Prompt.generate_annotations_prompt(
            job_description: inputs[:job_description],
            resume: inputs[:resume],
            research: inputs[:research]
          )
        end

        def parse_annotations(json_string)
          # Strip markdown code fences if present (defensive programming)
          # AI models sometimes wrap JSON in ```json ... ``` despite instructions
          cleaned_json = json_string.strip.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "")

          JSON.parse(cleaned_json, symbolize_names: true)
        rescue JSON::ParserError => e
          log("Error: Failed to parse AI response as JSON: #{e.message}", status: "failed")
          raise "AI returned invalid JSON: #{e.message}"
        end

        def save_annotations(annotations)
          json_output = JSON.pretty_generate(annotations)
          if cli_instance
            cli_instance.with_overwrite_check(employer.job_description_annotations_path, overwrite_flag) do
              File.write(employer.job_description_annotations_path, json_output)
            end
          else
            File.write(employer.job_description_annotations_path, json_output)
          end
        end

        def log(message, **metadata)
          employer.status_logger.log(message, step: :annotations, **metadata)
        end

        def say(message)
          puts "  [AnnotationGenerator] #{message}" if verbose
        end

        def logsay(message)
          log message
          say message
        end
      end
    end
  end
end
