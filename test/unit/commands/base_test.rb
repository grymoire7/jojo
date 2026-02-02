# test/unit/commands/base_test.rb
require_relative "../../test_helper"
require_relative "../../../lib/jojo/commands/base"

describe Jojo::Commands::Base do
  before do
    @mock_cli = Minitest::Mock.new
  end

  describe "#initialize" do
    it "stores cli and options" do
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme", verbose: true)

      _(base.cli.object_id).must_equal @mock_cli.object_id
      _(base.options[:slug]).must_equal "acme"
      _(base.options[:verbose]).must_equal true
    end
  end

  describe "#execute" do
    it "raises NotImplementedError" do
      base = Jojo::Commands::Base.new(@mock_cli)

      _ { base.execute }.must_raise NotImplementedError
    end
  end

  describe "option accessors" do
    it "returns slug from options" do
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")
      _(base.send(:slug)).must_equal "acme-corp"
    end

    it "returns verbose? from options with default false" do
      base = Jojo::Commands::Base.new(@mock_cli)
      _(base.send(:verbose?)).must_equal false
    end

    it "returns overwrite? from options with default false" do
      base = Jojo::Commands::Base.new(@mock_cli)
      _(base.send(:overwrite?)).must_equal false
    end

    it "returns quiet? from options with default false" do
      base = Jojo::Commands::Base.new(@mock_cli)
      _(base.send(:quiet?)).must_equal false
    end
  end

  describe "output helpers" do
    it "delegates say to cli" do
      @mock_cli.expect(:say, nil, ["Hello", :green])
      base = Jojo::Commands::Base.new(@mock_cli)

      base.send(:say, "Hello", :green)

      @mock_cli.verify
    end

    it "delegates yes? to cli" do
      @mock_cli.expect(:yes?, true, ["Continue?"])
      base = Jojo::Commands::Base.new(@mock_cli)

      result = base.send(:yes?, "Continue?")

      _(result).must_equal true
      @mock_cli.verify
    end
  end
end
