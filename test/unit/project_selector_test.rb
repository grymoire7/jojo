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
end
