module Jojo
  class Employer
    attr_reader :name, :slug, :base_path

    def initialize(name)
      @name = name
      @slug = slugify(name)
      @base_path = File.join('employers', @slug)
    end

    def job_description_path
      File.join(base_path, 'job_description.md')
    end

    def research_path
      File.join(base_path, 'research.md')
    end

    def resume_path
      File.join(base_path, 'resume.md')
    end

    def cover_letter_path
      File.join(base_path, 'cover_letter.md')
    end

    def status_log_path
      File.join(base_path, 'status_log.md')
    end

    def website_path
      File.join(base_path, 'website')
    end

    def index_html_path
      File.join(website_path, 'index.html')
    end

    def create_directory!
      FileUtils.mkdir_p(base_path)
      FileUtils.mkdir_p(website_path)
    end

    private

    def slugify(text)
      text
        .downcase
        .gsub(/[^a-z0-9]+/, '-')
        .gsub(/^-|-$/, '')
    end
  end
end
