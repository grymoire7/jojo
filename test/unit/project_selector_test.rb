require_relative '../test_helper'
require_relative '../../lib/jojo/project_selector'
require_relative '../../lib/jojo/employer'

describe Jojo::ProjectSelector do
  before do
    @employer = Jojo::Employer.new('Test Corp')
    @employer.create_directory!

    # Create job_details.yml fixture
    File.write(@employer.job_details_path, <<~YAML)
      required_skills:
        - Ruby on Rails
        - PostgreSQL
      desired_skills:
        - leadership
    YAML

    @projects = [
      {
        title: 'Project Alpha',
        description: 'Web app project',
        skills: ['Ruby on Rails', 'PostgreSQL', 'web development']
      },
      {
        title: 'Project Beta',
        description: 'Unrelated project',
        skills: ['Python', 'MongoDB']
      },
      {
        title: 'Leadership Award',
        description: 'Employee award',
        skills: ['leadership', 'teamwork']
      }
    ]
  end

  after do
    FileUtils.rm_rf('employers/test-corp')
  end

  it "selects projects based on skill matching" do
    selector = Jojo::ProjectSelector.new(@employer, @projects)
    selected = selector.select_for_landing_page(limit: 3)

    _(selected.size).must_equal 3
    _(selected.first[:title]).must_equal 'Project Alpha'
    _(selected.first[:score]).must_be :>, 0
  end
end
