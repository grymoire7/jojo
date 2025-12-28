require_relative '../test_helper'
require_relative '../../lib/jojo/recommendation_parser'

describe Jojo::RecommendationParser do
  it "parses valid recommendations with all fields" do
    parser = Jojo::RecommendationParser.new('test/fixtures/recommendations.md')
    recommendations = parser.parse

    _(recommendations).must_be_kind_of Array
    _(recommendations.size).must_equal 2

    first = recommendations.first
    _(first[:recommender_name]).must_equal 'Jane Smith'
    _(first[:recommender_title]).must_equal 'Senior Engineering Manager'
    _(first[:relationship]).must_equal 'Former Manager at Acme Corp'
    _(first[:quote]).must_include 'excellent engineer'
  end
end
