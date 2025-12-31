require "fileutils"
require "yaml"

module Jojo
  class Employer
    attr_reader :name, :slug, :base_path

    def initialize(slug)
      @slug = slug
      @name = slug  # Will be updated from job_details.yml if it exists
      @base_path = File.join("employers", @slug)
    end

    def job_description_raw_path
      File.join(base_path, "job_description_raw.md")
    end

    def job_description_path
      File.join(base_path, "job_description.md")
    end

    def job_description_annotations_path
      File.join(base_path, "job_description_annotations.json")
    end

    def job_details_path
      File.join(base_path, "job_details.yml")
    end

    def research_path
      File.join(base_path, "research.md")
    end

    def resume_path
      File.join(base_path, "resume.md")
    end

    def cover_letter_path
      File.join(base_path, "cover_letter.md")
    end

    def resume_pdf_path
      File.join(base_path, "resume.pdf")
    end

    def cover_letter_pdf_path
      File.join(base_path, "cover_letter.pdf")
    end

    def status_log_path
      File.join(base_path, "status_log.md")
    end

    def website_path
      File.join(base_path, "website")
    end

    def index_html_path
      File.join(website_path, "index.html")
    end

    def faq_path
      File.join(base_path, "faq.json")
    end

    def job_details
      return {} unless File.exist?(job_details_path)

      YAML.load_file(job_details_path) || {}
    rescue
      {}
    end

    def company_name
      job_details["company_name"] || @name
    end

    def create_directory!
      FileUtils.mkdir_p(base_path)
      FileUtils.mkdir_p(website_path)
    end

    def create_artifacts(job_source, ai_client, overwrite_flag: nil, cli_instance: nil, verbose: false)
      # Create directory structure
      create_directory!

      # Process job description using existing processor
      require_relative "job_description_processor"
      processor = JobDescriptionProcessor.new(self, ai_client, overwrite_flag: overwrite_flag, cli_instance: cli_instance, verbose: verbose)
      processor.process(job_source)
    end

    def artifacts_exist?
      File.exist?(job_description_path) || File.exist?(job_details_path)
    end

    private

    def remove_artifacts
      # Remove all files except directories
      [
        job_description_raw_path,
        job_description_path,
        job_details_path,
        job_description_annotations_path,
        research_path,
        resume_path,
        cover_letter_path,
        status_log_path,
        faq_path
      ].each do |path|
        FileUtils.rm_f(path) if File.exist?(path)
      end
    end
  end
end
