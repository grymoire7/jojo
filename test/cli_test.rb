require_relative 'test_helper'
require_relative '../lib/jojo/cli'

describe Jojo::CLI do
  it "exists" do
    _(defined?(Jojo::CLI)).wont_be_nil
  end

  it "inherits from Thor" do
    _(Jojo::CLI.ancestors).must_include Thor
  end

  it "has setup command" do
    _(Jojo::CLI.commands.key?('setup')).must_equal true
  end

  it "has generate command" do
    _(Jojo::CLI.commands.key?('generate')).must_equal true
  end

  it "has research command" do
    _(Jojo::CLI.commands.key?('research')).must_equal true
  end

  it "has resume command" do
    _(Jojo::CLI.commands.key?('resume')).must_equal true
  end

  it "has cover_letter command" do
    _(Jojo::CLI.commands.key?('cover_letter')).must_equal true
  end

  it "has website command" do
    _(Jojo::CLI.commands.key?('website')).must_equal true
  end

  it "has version command" do
    _(Jojo::CLI.commands.key?('version')).must_equal true
  end

  it "has test command" do
    _(Jojo::CLI.commands.key?('test')).must_equal true
  end
end
