require 'uri'
require 'net/http'
require 'html_to_markdown'

module Jojo
  class JobDescriptionProcessor
    attr_reader :employer, :ai_client, :verbose

    def initialize(employer, ai_client, verbose: false)
      @employer = employer
      @ai_client = ai_client
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
        raise "Failed to fetch URL: #{response.code} #{response.message}"
      end

      html = response.body
      log "Converting HTML to markdown..."

      markdown = HtmlToMarkdown.new(html).convert
      log "Conversion complete"

      markdown
    rescue => e
      raise "Error fetching URL: #{e.message}"
    end

    def fetch_from_file(file_path)
      log "Reading job description from file..."

      unless File.exist?(file_path)
        raise "File not found: #{file_path}"
      end

      File.read(file_path)
    end

    def extract_job_description(raw_content)
      log "Extracting clean job description using AI..."

      prompt = Prompts::JobDescription.extraction_prompt(raw_content)
      ai_client.reason(prompt)
    end

    def extract_key_details(job_description)
      log "Extracting key details using AI..."

      prompt = Prompts::JobDescription.key_details_prompt(job_description)
      ai_client.generate_text(prompt)
    end

    def save_raw_content(content)
      path = employer.job_description_raw_path
      log "Saving raw content to: #{path}"
      File.write(path, content)
    end

    def save_job_description(content)
      path = employer.job_description_path
      log "Saving job description to: #{path}"
      File.write(path, content)
    end

    def save_job_details(yaml_content)
      path = employer.job_details_path
      log "Saving job details to: #{path}"
      File.write(path, yaml_content)
    end

    def log(message)
      puts "  [JobProcessor] #{message}" if verbose
    end
  end
end
