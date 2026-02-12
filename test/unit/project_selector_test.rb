require_relative "../test_helper"
require_relative "../../lib/jojo/project_selector"
require_relative "../../lib/jojo/application"

class ProjectSelectorTest < JojoTest
  def setup
    super
    @application = Jojo::Application.new("test-corp")
    @application.create_directory!

    File.write(@application.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
        - PostgreSQL
      desired_skills:
        - leadership
    YAML

    @projects = [
      {
        title: "Project Alpha",
        description: "Web app project",
        skills: ["Ruby on Rails", "PostgreSQL", "web development"]
      },
      {
        title: "Project Beta",
        description: "Unrelated project",
        skills: ["Python", "MongoDB"]
      },
      {
        title: "Leadership Award",
        description: "Employee award",
        skills: ["leadership", "teamwork"]
      }
    ]
  end

  def test_selects_projects_based_on_skill_matching
    selector = Jojo::ProjectSelector.new(@application, @projects)
    selected = selector.select_for_landing_page(limit: 3)

    assert_equal 2, selected.size  # Only 2 projects match
    assert_equal "Project Alpha", selected.first[:title]
    assert_operator selected.first[:score], :>, 0
  end

  def test_applies_recency_bonus_to_recent_projects
    current_year = Time.now.year
    projects = [
      {
        title: "Old Project",
        description: "From 5 years ago",
        skills: ["Ruby on Rails"],
        year: current_year - 5
      },
      {
        title: "Recent Project",
        description: "From last year",
        skills: ["Ruby on Rails"],
        year: current_year - 1
      }
    ]

    selector = Jojo::ProjectSelector.new(@application, projects)
    selected = selector.select_for_landing_page(limit: 2)

    assert_equal "Recent Project", selected.first[:title]
    assert_operator selected.first[:score], :>, selected.last[:score]
  end

  def test_returns_empty_array_when_no_projects_match
    projects = [
      {
        title: "Unrelated Project",
        description: "No matching skills",
        skills: ["Python", "Java"]
      }
    ]

    selector = Jojo::ProjectSelector.new(@application, projects)
    selected = selector.select_for_landing_page(limit: 3)

    assert_kind_of Array, selected
    assert_empty selected
  end

  def test_filters_zero_score_projects
    projects = [
      {title: "Relevant", skills: ["Ruby on Rails"]},
      {title: "Irrelevant A", skills: ["C++"]},
      {title: "Irrelevant B", skills: ["Haskell"]}
    ]

    selector = Jojo::ProjectSelector.new(@application, projects)
    selected = selector.select_for_landing_page(limit: 5)

    assert_equal 1, selected.size
    assert_equal "Relevant", selected.first[:title]
  end

  def test_handles_missing_year_field
    projects = [
      {title: "No Year Project", skills: ["Ruby on Rails"]}
    ]

    selector = Jojo::ProjectSelector.new(@application, projects)
    selected = selector.select_for_landing_page(limit: 3)

    assert_equal 1, selected.size
    assert_equal "No Year Project", selected.first[:title]
  end

  def test_select_for_resume_respects_limit
    current_year = Time.now.year
    projects = [
      {title: "P1", skills: ["Ruby on Rails", "PostgreSQL"], year: current_year},
      {title: "P2", skills: ["Ruby on Rails"], year: current_year},
      {title: "P3", skills: ["PostgreSQL"], year: current_year},
      {title: "P4", skills: ["leadership"], year: current_year}
    ]

    selector = Jojo::ProjectSelector.new(@application, projects)
    selected = selector.select_for_resume(limit: 2)

    assert_equal 2, selected.size
  end

  def test_select_for_cover_letter_respects_limit
    current_year = Time.now.year
    projects = [
      {title: "P1", skills: ["Ruby on Rails", "PostgreSQL"], year: current_year},
      {title: "P2", skills: ["Ruby on Rails"], year: current_year},
      {title: "P3", skills: ["PostgreSQL"], year: current_year}
    ]

    selector = Jojo::ProjectSelector.new(@application, projects)
    selected = selector.select_for_cover_letter(limit: 2)

    assert_equal 2, selected.size
  end

  def test_empty_job_skills_returns_empty
    # Overwrite job_details with empty skills
    File.write(@application.job_details_path, <<~YAML)
      required_skills: []
      desired_skills: []
    YAML

    projects = [
      {title: "P1", skills: ["Ruby on Rails"]},
      {title: "P2", skills: ["Python"]}
    ]

    selector = Jojo::ProjectSelector.new(@application, projects)
    selected = selector.select_for_landing_page(limit: 5)

    assert_empty selected
  end

  def test_handles_missing_job_details_file
    FileUtils.rm(@application.job_details_path)

    projects = [
      {title: "P1", skills: ["Ruby on Rails"]}
    ]

    selector = Jojo::ProjectSelector.new(@application, projects)
    selected = selector.select_for_landing_page(limit: 5)

    assert_empty selected
  end
end
