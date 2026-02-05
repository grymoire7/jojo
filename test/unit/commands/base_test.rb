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
      FileUtils.mkdir_p("applications/acme-corp")
      File.write("applications/acme-corp/job_description.md", "Test job")
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

  describe "validation helpers" do
    before do
      @tmpdir = Dir.mktmpdir
      @original_dir = Dir.pwd
      Dir.chdir(@tmpdir)
      FileUtils.mkdir_p("applications/acme-corp")
    end

    after do
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@tmpdir)
    end

    describe "#application" do
      before do
        FileUtils.mkdir_p("applications/acme-corp")
        File.write("applications/acme-corp/job_details.yml", "company_name: Acme")
      end

      after do
        FileUtils.rm_rf("applications")
      end

      it "creates application from slug" do
        base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

        _(base.send(:application)).must_be_instance_of Jojo::Application
        _(base.send(:application).slug).must_equal "acme-corp"
      end

      it "caches application instance" do
        base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

        first_call = base.send(:application)
        second_call = base.send(:application)

        _(first_call).must_be_same_as second_call
      end
    end

    describe "#require_application!" do
      it "passes when application artifacts exist" do
        FileUtils.mkdir_p("applications/acme-corp")
        File.write("applications/acme-corp/job_description.md", "# Job")

        base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")
        # Should not raise
        base.send(:require_application!)

        FileUtils.rm_rf("applications")
      end

      it "exits when application does not exist" do
        base = Jojo::Commands::Base.new(@mock_cli, slug: "nonexistent")

        @mock_cli.expect(:say, nil, ["Application 'nonexistent' not found.", :red])
        @mock_cli.expect(:say, nil, [String, :yellow])

        assert_raises(SystemExit) do
          base.send(:require_application!)
        end
        @mock_cli.verify
      end
    end

    describe "#require_application!" do
      it "does not exit when employer artifacts exist" do
        File.write("applications/acme-corp/job_description.md", "Test")
        base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

        # Should not raise
        base.send(:require_application!)
      end

      it "exits with message when employer not found" do
        base = Jojo::Commands::Base.new(@mock_cli, slug: "nonexistent")

        @mock_cli.expect(:say, nil, ["Application 'nonexistent' not found.", :red])
        @mock_cli.expect(:say, nil, [String, :yellow])

        assert_raises(SystemExit) { base.send(:require_application!) }
        @mock_cli.verify
      end
    end

    describe "#require_file!" do
      it "does not exit when file exists" do
        File.write("applications/acme-corp/test.txt", "content")
        base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

        # Should not raise
        base.send(:require_file!, "applications/acme-corp/test.txt", "Test file")
      end

      it "exits with message when file missing" do
        base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

        @mock_cli.expect(:say, nil, ["Test file not found at missing.txt", :red])

        assert_raises(SystemExit) do
          base.send(:require_file!, "missing.txt", "Test file")
        end
        @mock_cli.verify
      end

      it "shows suggestion when provided" do
        base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

        @mock_cli.expect(:say, nil, [String, :red])
        @mock_cli.expect(:say, nil, ["  Run 'jojo setup' first", :yellow])

        assert_raises(SystemExit) do
          base.send(:require_file!, "missing.txt", "Config", suggestion: "Run 'jojo setup' first")
        end
        @mock_cli.verify
      end
    end
  end
end
