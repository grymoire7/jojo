# test/unit/erb_renderer_test.rb
require_relative "../test_helper"
require_relative "../../lib/jojo/erb_renderer"

describe Jojo::ErbRenderer do
  it "renders ERB template with data" do
    template_path = "test/fixtures/templates/resume_template.md.erb"
    data = {
      "name" => "Jane Doe",
      "email" => "jane@example.com",
      "phone" => "+1-555-0123",
      "location" => "SF, CA",
      "summary" => "Experienced engineer",
      "skills" => ["Ruby", "Python"],
      "experience" => [
        {
          "title" => "Senior Dev",
          "company" => "TechCo",
          "start_date" => "2020-01",
          "end_date" => "present",
          "description" => "Built things",
          "technologies" => ["Ruby", "Rails"]
        }
      ],
      "education" => [
        {
          "degree" => "BS CS",
          "institution" => "State U",
          "year" => "2015"
        }
      ],
      "projects" => [
        {
          "name" => "CLI Tool",
          "description" => "Command line tool",
          "skills" => ["Ruby"]
        }
      ],
      "recommendations" => [
        {
          "name" => "Jane Smith",
          "title" => "Manager",
          "quote" => "Great engineer"
        }
      ]
    }

    renderer = Jojo::ErbRenderer.new(template_path)
    result = renderer.render(data)

    _(result).must_include "# Jane Doe"
    _(result).must_include "jane@example.com"
    _(result).must_include "Experienced engineer"
    _(result).must_include "Ruby • Python"
    _(result).must_include "### Senior Dev at TechCo"
    _(result).must_include "> Great engineer"
    _(result).must_include "Jane Smith"
  end

  it "handles missing optional fields" do
    template_path = "test/fixtures/templates/resume_template.md.erb"
    data = {
      "name" => "John Doe",
      "email" => "john@example.com",
      "phone" => "555-0100",
      "location" => "NYC",
      "summary" => "Engineer",
      "skills" => ["Python"],
      "experience" => [],
      "education" => [],
      "projects" => []
    }

    renderer = Jojo::ErbRenderer.new(template_path)
    result = renderer.render(data)

    _(result).must_include "# John Doe"
    _(result).wont_include "## Recommendations"
  end
end
