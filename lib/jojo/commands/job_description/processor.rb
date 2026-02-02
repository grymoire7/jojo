# lib/jojo/commands/job_description/processor.rb
require "uri"
require "net/http"
require "html_to_markdown"
require_relative "prompt"

module Jojo
  module Commands
    module JobDescription
      class Processor
        class ProcessingError < StandardError; end

        attr_reader :employer, :ai_client, :verbose, :overwrite_flag, :cli_instance

        def initialize(employer, ai_client, overwrite_flag: nil, cli_instance: nil, verbose: false)
          @employer = employer
          @ai_client = ai_client
          @overwrite_flag = overwrite_flag
          @cli_instance = cli_instance
          @verbose = verbose
        end

        # Main entry point: process job description from file or URL
        def process(source)
          log "Processing job description from: #{source}"

          raw_content = fetch_content(source)
          save_raw_content(raw_content) if url?(source)

          job_description = extract_job_description(raw_content)
          save_job_description(job_description)

          job_details = extract_key_details(job_description)
          save_job_details(job_details)

          log "Job description processing complete!"
          {
            job_description: job_description,
            job_details: job_details
          }
        end

        private

        def fetch_content(source)
          if url?(source)
            fetch_from_url(source)
          else
            fetch_from_file(source)
          end
        end

        def url?(source)
          source =~ URI::DEFAULT_PARSER.make_regexp
        end

        def fetch_from_url(url)
          log "Fetching HTML from URL..."

          uri = URI.parse(url)
          response = Net::HTTP.get_response(uri)

          unless response.is_a?(Net::HTTPSuccess)
            raise ProcessingError, "Failed to fetch URL: #{response.code} #{response.message}\n\nPlease check:\n- The URL is correct and accessible\n- You have internet connectivity\n- The website is not blocking automated requests"
          end

          html = response.body
          log "Converting HTML to markdown..."

          markdown = HtmlToMarkdown.new(html).convert
          log "Conversion complete"

          markdown
        rescue URI::InvalidURIError
          raise ProcessingError, "Invalid URL: #{url}\n\nPlease provide a valid URL or file path."
        rescue ProcessingError
          raise
        rescue => e
          raise ProcessingError, "Error fetching URL: #{e.message}\n\nPlease check your internet connection and try again."
        end

        def fetch_from_file(file_path)
          log "Reading job description from file..."

          unless File.exist?(file_path)
            raise ProcessingError, "File not found: #{file_path}\n\nPlease check:\n- The file path is correct\n- The file exists in the specified location"
          end

          File.read(file_path)
        rescue ProcessingError
          raise
        rescue Errno::EACCES
          raise ProcessingError, "Permission denied: #{file_path}\n\nPlease check file permissions and try again."
        rescue => e
          raise ProcessingError, "Error reading file: #{e.message}"
        end

        def extract_job_description(raw_content)
          log "Extracting clean job description using AI..."

          prompt = Prompt.extraction_prompt(raw_content)
          ai_client.reason(prompt)
        end

        def extract_key_details(job_description)
          log "Extracting key details using AI..."

          prompt = Prompt.key_details_prompt(job_description)
          ai_client.generate_text(prompt)
        end

        def save_raw_content(content)
          path = employer.job_description_raw_path
          log "Saving raw content to: #{path}"
          if cli_instance
            cli_instance.with_overwrite_check(path, overwrite_flag) do
              File.write(path, content)
            end
          else
            File.write(path, content)
          end
        end

        def save_job_description(content)
          path = employer.job_description_path
          log "Saving job description to: #{path}"
          if cli_instance
            cli_instance.with_overwrite_check(path, overwrite_flag) do
              File.write(path, content)
            end
          else
            File.write(path, content)
          end
        end

        def save_job_details(yaml_content)
          path = employer.job_details_path
          log "Saving job details to: #{path}"
          if cli_instance
            cli_instance.with_overwrite_check(path, overwrite_flag) do
              File.write(path, yaml_content)
            end
          else
            File.write(path, yaml_content)
          end
        end

        def log(message)
          puts "  [JobProcessor] #{message}" if verbose
        end
      end
    end
  end
end
