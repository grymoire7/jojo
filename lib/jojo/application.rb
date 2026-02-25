require "fileutils"
require "yaml"

module Jojo
  class Application
    attr_reader :name, :slug, :base_path

    def initialize(slug)
      @slug = slug
      @name = slug  # Will be updated from job_details.yml if it exists
      @base_path = File.join("applications", @slug)
    end

    def job_description_raw_path = File.join(base_path, "job_description_raw.md")
    def job_description_path = File.join(base_path, "job_description.md")
    def job_description_annotations_path = File.join(base_path, "job_description_annotations.json")
    def job_details_path = File.join(base_path, "job_details.yml")
    def research_path = File.join(base_path, "research.md")
    def resume_path = File.join(base_path, "resume.md")
    def branding_path = File.join(base_path, "branding.md")
    def cover_letter_path = File.join(base_path, "cover_letter.md")
    def resume_pdf_path = File.join(base_path, "resume.pdf")
    def cover_letter_pdf_path = File.join(base_path, "cover_letter.pdf")
    def resume_html_path = File.join(base_path, "resume.html")
    def cover_letter_html_path = File.join(base_path, "cover_letter.html")
    def status_log_path = File.join(base_path, "status.log")
    def website_path = File.join(base_path, "website")
    def faq_path = File.join(base_path, "faq.json")
    def index_html_path = File.join(website_path, "index.html")

    def job_details
      return {} unless File.exist?(job_details_path)

      YAML.load_file(job_details_path) || {}
    rescue
      {}
    end

    def company_name
      job_details["company_name"] || @name
    end

    def status_logger
      @status_logger ||= Jojo::StatusLogger.new(status_log_path)
    end

    def create_directory!
      FileUtils.mkdir_p(base_path)
      FileUtils.mkdir_p(website_path)
    end

    def create_artifacts(job_source, ai_client, overwrite_flag: nil, cli_instance: nil, verbose: false)
      create_directory!

      require_relative "commands/job_description/processor"
      processor = Commands::JobDescription::Processor.new(self, ai_client, overwrite_flag: overwrite_flag, cli_instance: cli_instance, verbose: verbose)
      processor.process(job_source)
    end

    def artifacts_exist?
      File.exist?(job_description_path) || File.exist?(job_details_path)
    end

    private

    def remove_artifacts
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
