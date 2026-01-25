# frozen_string_literal: true

require_relative "../test_helper"

describe Jojo::Workflow do
  describe "STEPS" do
    it "defines all workflow steps in order" do
      steps = Jojo::Workflow::STEPS

      _(steps).must_be_kind_of Array
      _(steps.length).must_equal 9
      _(steps.first[:key]).must_equal :job_description
      _(steps.last[:key]).must_equal :pdf
    end

    it "includes required fields for each step" do
      Jojo::Workflow::STEPS.each do |step|
        _(step).must_include :key
        _(step).must_include :label
        _(step).must_include :dependencies
        _(step).must_include :command
        _(step).must_include :paid
        _(step).must_include :output_file
      end
    end
  end
end
