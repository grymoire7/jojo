require_relative "../test_helper"
require_relative "../../lib/jojo/recommendation_parser"

describe Jojo::RecommendationParser do
  it "parses valid recommendations with all fields" do
    parser = Jojo::RecommendationParser.new("test/fixtures/recommendations.md")
    recommendations = parser.parse

    _(recommendations).must_be_kind_of Array
    _(recommendations.size).must_equal 2

    first = recommendations.first
    _(first[:recommender_name]).must_equal "Jane Smith"
    _(first[:recommender_title]).must_equal "Senior Engineering Manager"
    _(first[:relationship]).must_equal "Former Manager at Acme Corp"
    _(first[:quote]).must_include "excellent engineer"
  end

  it "handles missing optional fields" do
    parser = Jojo::RecommendationParser.new("test/fixtures/recommendations_minimal.md")
    recommendations = parser.parse

    _(recommendations.size).must_equal 1
    _(recommendations.first[:recommender_name]).must_equal "Alice Lee"
    _(recommendations.first[:recommender_title]).must_be_nil
    _(recommendations.first[:relationship]).must_equal "Colleague"  # default
    _(recommendations.first[:quote]).wont_be_empty
  end

  it "returns nil when file does not exist" do
    parser = Jojo::RecommendationParser.new("test/fixtures/nonexistent.md")
    recommendations = parser.parse

    _(recommendations).must_be_nil
  end

  it "returns empty array when file has no valid recommendations" do
    parser = Jojo::RecommendationParser.new("test/fixtures/recommendations_empty.md")
    recommendations = parser.parse

    _(recommendations).must_be_kind_of Array
    _(recommendations).must_be_empty
  end

  it "skips recommendations missing required name" do
    parser = Jojo::RecommendationParser.new("test/fixtures/recommendations_malformed.md")
    recommendations = parser.parse

    # Should have 1 valid, skip 1 invalid
    _(recommendations.size).must_equal 1
  end

  it "skips recommendations missing quote" do
    parser = Jojo::RecommendationParser.new("test/fixtures/recommendations_no_quote.md")
    recommendations = parser.parse

    _(recommendations).must_be_empty
  end

  it "handles multi-paragraph quotes" do
    parser = Jojo::RecommendationParser.new("test/fixtures/recommendations_long.md")
    recommendations = parser.parse

    quote = recommendations.first[:quote]
    _(quote).must_include "first paragraph"
    _(quote).must_include "second paragraph"
  end
end
