require "yaml"

module Jojo
  class ProjectSelector
    attr_reader :application, :projects

    def initialize(application, projects)
      @application = application
      @projects = projects
    end

    def select_for_landing_page(limit: 5)
      select_projects(limit: limit)
    end

    def select_for_resume(limit: 3)
      select_projects(limit: limit)
    end

    def select_for_cover_letter(limit: 2)
      select_projects(limit: limit)
    end

    private

    def select_projects(limit:)
      scored = projects.map do |project|
        project.merge(score: calculate_score(project))
      end

      # Filter out zero-score projects
      scored = scored.select { |p| p[:score] > 0 }

      scored.sort_by { |p| -p[:score] }.take(limit)
    end

    def calculate_score(project)
      score = 0
      project_skills = project[:skills] || []

      project_skills.each do |skill|
        score += 10 if required_skills.include?(skill)
        score += 5 if desired_skills.include?(skill)
      end

      # Recency bonus
      year = project[:year] || project[:date]&.year || 0

      if year > 0
        current_year = Time.now.year
        score += 5 if (current_year - year) <= 2
      end

      score
    end

    def job_details
      @job_details ||= begin
        return {} unless File.exist?(application.job_details_path)
        YAML.load_file(application.job_details_path)
      end
    end

    def required_skills
      job_details["required_skills"] || []
    end

    def desired_skills
      job_details["desired_skills"] || []
    end
  end
end
