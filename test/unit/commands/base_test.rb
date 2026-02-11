# test/unit/commands/base_test.rb
require_relative "../../test_helper"
require_relative "../../../lib/jojo/commands/base"

class Jojo::Commands::BaseTest < JojoTest
  def setup
    super
    @mock_cli = Minitest::Mock.new
  end

  # --- #initialize ---

  def test_stores_cli_and_options
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme", verbose: true)

    _(base.cli.object_id).must_equal @mock_cli.object_id
    _(base.options[:slug]).must_equal "acme"
    _(base.options[:verbose]).must_equal true
  end

  # --- #execute ---

  def test_execute_raises_not_implemented_error
    base = Jojo::Commands::Base.new(@mock_cli)

    _ { base.execute }.must_raise NotImplementedError
  end

  # --- option accessors ---

  def test_returns_slug_from_options
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")
    _(base.send(:slug)).must_equal "acme-corp"
  end

  def test_returns_verbose_from_options_with_default_false
    base = Jojo::Commands::Base.new(@mock_cli)
    _(base.send(:verbose?)).must_equal false
  end

  def test_returns_overwrite_from_options_with_default_false
    base = Jojo::Commands::Base.new(@mock_cli)
    _(base.send(:overwrite?)).must_equal false
  end

  def test_returns_quiet_from_options_with_default_false
    base = Jojo::Commands::Base.new(@mock_cli)
    _(base.send(:quiet?)).must_equal false
  end

  # --- output helpers ---

  def test_delegates_say_to_cli
    @mock_cli.expect(:say, nil, ["Hello", :green])
    base = Jojo::Commands::Base.new(@mock_cli)

    base.send(:say, "Hello", :green)

    @mock_cli.verify
  end

  def test_delegates_yes_to_cli
    @mock_cli.expect(:yes?, true, ["Continue?"])
    base = Jojo::Commands::Base.new(@mock_cli)

    result = base.send(:yes?, "Continue?")

    _(result).must_equal true
    @mock_cli.verify
  end

  # --- shared setup (lazy-loaded) ---

  def test_creates_application_from_slug
    setup_shared_lazy_loaded
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    application = base.send(:application)

    _(application).must_be_kind_of Jojo::Application
    _(application.slug).must_equal "acme-corp"
  end

  def test_caches_application_instance
    setup_shared_lazy_loaded
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    app1 = base.send(:application)
    app2 = base.send(:application)

    _(app1.object_id).must_equal app2.object_id
  end

  def test_creates_config
    setup_shared_lazy_loaded
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    config = base.send(:config)

    _(config).must_be_kind_of Jojo::Config
  end

  def test_creates_status_logger_for_application
    setup_shared_lazy_loaded
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    logger = base.send(:status_logger)

    _(logger).must_be_kind_of Jojo::StatusLogger
  end

  # --- validation helpers: #application ---

  def test_validation_creates_application_from_slug
    setup_validation
    FileUtils.mkdir_p("applications/acme-corp")
    File.write("applications/acme-corp/job_details.yml", "company_name: Acme")

    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    _(base.send(:application)).must_be_instance_of Jojo::Application
    _(base.send(:application).slug).must_equal "acme-corp"
  end

  def test_validation_caches_application_instance
    setup_validation
    FileUtils.mkdir_p("applications/acme-corp")
    File.write("applications/acme-corp/job_details.yml", "company_name: Acme")

    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    first_call = base.send(:application)
    second_call = base.send(:application)

    _(first_call).must_be_same_as second_call
  end

  # --- validation helpers: #require_application! ---

  def test_require_application_passes_when_artifacts_exist
    setup_validation
    FileUtils.mkdir_p("applications/acme-corp")
    File.write("applications/acme-corp/job_description.md", "# Job")

    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")
    # Should not raise
    base.send(:require_application!)
  end

  def test_require_application_exits_when_application_does_not_exist
    setup_validation
    base = Jojo::Commands::Base.new(@mock_cli, slug: "nonexistent")

    @mock_cli.expect(:say, nil, ["Application 'nonexistent' not found.", :red])
    @mock_cli.expect(:say, nil, [String, :yellow])

    assert_raises(SystemExit) do
      base.send(:require_application!)
    end
    @mock_cli.verify
  end

  # --- validation helpers: #require_file! ---

  def test_require_file_does_not_exit_when_file_exists
    setup_validation
    FileUtils.mkdir_p("applications/acme-corp")
    File.write("applications/acme-corp/test.txt", "content")
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    # Should not raise
    base.send(:require_file!, "applications/acme-corp/test.txt", "Test file")
  end

  def test_require_file_exits_with_message_when_file_missing
    setup_validation
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    @mock_cli.expect(:say, nil, ["Test file not found at missing.txt", :red])

    assert_raises(SystemExit) do
      base.send(:require_file!, "missing.txt", "Test file")
    end
    @mock_cli.verify
  end

  def test_require_file_shows_suggestion_when_provided
    setup_validation
    base = Jojo::Commands::Base.new(@mock_cli, slug: "acme-corp")

    @mock_cli.expect(:say, nil, [String, :red])
    @mock_cli.expect(:say, nil, ["  Run 'jojo setup' first", :yellow])

    assert_raises(SystemExit) do
      base.send(:require_file!, "missing.txt", "Config", suggestion: "Run 'jojo setup' first")
    end
    @mock_cli.verify
  end

  private

  def setup_shared_lazy_loaded
    write_test_config

    # Create application directory
    FileUtils.mkdir_p("applications/acme-corp")
    File.write("applications/acme-corp/job_description.md", "Test job")
  end

  def setup_validation
    FileUtils.mkdir_p("applications/acme-corp")
  end
end
