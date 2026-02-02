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

  describe "shared setup (lazy-loaded)" do
    before do
      @tmpdir = Dir.mktmpdir
      @original_dir = Dir.pwd
      Dir.chdir(@tmpdir)

      # Create minimal config
      File.write("config.yml", <<~YAML)
        seeker_name: "Test User"
        base_url: "https://example.com"
        reasoning_ai_service: openai
        reasoning_ai_model: gpt-4
        text_generation_ai_service: openai
        text_generation_ai_model: gpt-4
      YAML

      # Create employer directory
      FileUtils.mkdir_p("employers/acme-corp")
      File.write("employers/acme-corp/job_description.md", "Test job")
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@tmpdir)
    end

    it "creates employer from slug" do
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

      employer = base.send(:employer)

      _(employer).must_be_kind_of Jojo::Employer
      _(employer.slug).must_equal "acme-corp"
    end

    it "caches employer instance" do
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

      employer1 = base.send(:employer)
      employer2 = base.send(:employer)

      _(employer1.object_id).must_equal employer2.object_id
    end

    it "creates config" do
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

      config = base.send(:config)

      _(config).must_be_kind_of Jojo::Config
    end

    it "creates status_logger for employer" do
      base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

      logger = base.send(:status_logger)

      _(logger).must_be_kind_of Jojo::StatusLogger
    end
  end
end
