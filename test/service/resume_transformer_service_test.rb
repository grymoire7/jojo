require_relative "../test_helper"
require_relative "../../lib/jojo/resume_transformer"
require_relative "../../lib/jojo/ai_client"
require_relative "../../lib/jojo/config"
require "yaml"

describe "Jojo::ResumeTransformer Service Tests" do
  before do
    # Skip these tests if no API key is available
    skip "ANTHROPIC_API_KEY not set" unless ENV["ANTHROPIC_API_KEY"]

    @config = Jojo::Config.new("test/fixtures/valid_config.yml")
    @ai_client = Jojo::AIClient.new(@config, verbose: true)
    @config_hash = YAML.load_file("test/fixtures/valid_config.yml")
    @job_context = {
      job_description: "Looking for a Senior Ruby on Rails developer with PostgreSQL and Docker experience. Must have strong backend skills and experience with microservices architecture."
    }
    @transformer = Jojo::ResumeTransformer.new(
      ai_client: @ai_client,
      config: @config_hash,
      job_context: @job_context
    )
  end

  describe "#filter_field with real AI" do
    it "filters skills array and returns valid JSON indices" do
      data = {"skills" => ["Ruby", "Python", "JavaScript", "Java", "C++", "Go", "PHP", "Rust"]}

      @transformer.send(:filter_field, "skills", data)

      # Verify the result is still an array
      _(data["skills"]).must_be_kind_of Array

      # Verify we kept some but not all (around 70%)
      _(data["skills"].length).must_be :>, 0
      _(data["skills"].length).must_be :<=, 8

      # Verify all kept items were in original list
      data["skills"].each do |skill|
        _(["Ruby", "Python", "JavaScript", "Java", "C++", "Go", "PHP", "Rust"]).must_include skill
      end

      puts "\nFiltered skills: #{data["skills"].inspect}"
    end
  end

  describe "#reorder_field with real AI" do
    it "reorders experience array and maintains all items when can_remove is false" do
      data = {
        "experience" => [
          {"company" => "TechCorp", "title" => "Senior Engineer", "description" => "Led Ruby on Rails team"},
          {"company" => "StartupXYZ", "title" => "Developer", "description" => "Built Python APIs"},
          {"company" => "ConsultingCo", "title" => "Junior Dev", "description" => "Frontend JavaScript work"}
        ]
      }

      original_count = data["experience"].length

      @transformer.send(:reorder_field, "experience", data, can_remove: false)

      # Verify count is preserved
      _(data["experience"].length).must_equal original_count

      # Verify all original items are still present
      _(data["experience"]).must_be_kind_of Array
      companies = data["experience"].map { |exp| exp["company"] }.sort
      _(companies).must_equal ["ConsultingCo", "StartupXYZ", "TechCorp"]

      puts "\nReordered experience:"
      data["experience"].each_with_index do |exp, i|
        puts "  #{i + 1}. #{exp["company"]} - #{exp["title"]}"
      end
    end

    it "allows reordering with removal when can_remove is true" do
      data = {"skills" => ["Ruby", "Python", "JavaScript", "Cobol", "Fortran"]}

      @transformer.send(:reorder_field, "skills", data, can_remove: true)

      # Verify we got an array
      _(data["skills"]).must_be_kind_of Array

      # Verify we can have fewer items
      _(data["skills"].length).must_be :>, 0
      _(data["skills"].length).must_be :<=, 5

      puts "\nReordered/filtered skills: #{data["skills"].inspect}"
    end
  end

  describe "#rewrite_field with real AI" do
    it "rewrites summary text tailored to job description" do
      data = {"summary" => "Experienced software engineer with broad technical background across multiple domains"}

      original_summary = data["summary"]

      @transformer.send(:rewrite_field, "summary", data)

      # Verify we got a string back
      _(data["summary"]).must_be_kind_of String

      # Verify it's not empty
      _(data["summary"].length).must_be :>, 0

      # Verify it changed
      _(data["summary"]).wont_equal original_summary

      puts "\nOriginal summary: #{original_summary}"
      puts "Tailored summary: #{data["summary"]}"
    end
  end

  describe "error handling with real AI" do
    it "raises PermissionViolation if AI tries to remove items from reorder-only field" do
      # Use a job description that might tempt AI to filter
      @transformer = Jojo::ResumeTransformer.new(
        ai_client: @ai_client,
        config: @config_hash,
        job_context: {
          job_description: "Looking ONLY for Ruby developers. No other languages."
        }
      )

      data = {"languages" => ["English", "Spanish", "French", "German", "Japanese"]}

      # This should work (reorder all 5 languages) or raise PermissionViolation
      # We can't predict AI behavior, so we test it handles the response correctly
      begin
        @transformer.send(:reorder_field, "languages", data, can_remove: false)
        # If successful, verify all items preserved
        _(data["languages"].length).must_equal 5
        puts "\nAI correctly preserved all languages during reorder"
      rescue Jojo::PermissionViolation => e
        # If AI tried to remove items, verify error was caught
        _(e.message).must_include "removed items"
        puts "\nAI attempted to remove items, PermissionViolation raised correctly"
      end
    end
  end
end
