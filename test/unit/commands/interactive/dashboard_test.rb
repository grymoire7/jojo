# frozen_string_literal: true

require_relative "../../../test_helper"

class Jojo::Commands::Interactive::DashboardTest < JojoTest
  # .status_icon

  def test_status_icon_returns_checkmark_for_generated
    assert_equal "✓", Jojo::Commands::Interactive::Dashboard.status_icon(:generated)
  end

  def test_status_icon_returns_star_for_stale
    assert_equal "*", Jojo::Commands::Interactive::Dashboard.status_icon(:stale)
  end

  def test_status_icon_returns_circle_for_ready
    assert_equal "○", Jojo::Commands::Interactive::Dashboard.status_icon(:ready)
  end

  def test_status_icon_returns_lock_for_blocked
    assert_equal "×", Jojo::Commands::Interactive::Dashboard.status_icon(:blocked)
  end

  # .paid_icon

  def test_paid_icon_returns_money_bag_for_paid_commands
    assert_equal "$", Jojo::Commands::Interactive::Dashboard.paid_icon(true)
  end

  def test_paid_icon_returns_empty_string_for_free_commands
    assert_equal " ", Jojo::Commands::Interactive::Dashboard.paid_icon(false)
  end

  # .progress_bar

  def test_progress_bar_renders_empty_bar_for_zero_percent
    bar = Jojo::Commands::Interactive::Dashboard.progress_bar(0, width: 10)
    assert_equal "░░░░░░░░░░", bar
  end

  def test_progress_bar_renders_full_bar_for_100_percent
    bar = Jojo::Commands::Interactive::Dashboard.progress_bar(100, width: 10)
    assert_equal "██████████", bar
  end

  def test_progress_bar_renders_partial_bar_for_50_percent
    bar = Jojo::Commands::Interactive::Dashboard.progress_bar(50, width: 10)
    assert_equal "█████░░░░░", bar
  end

  def test_progress_bar_renders_partial_bar_for_70_percent
    bar = Jojo::Commands::Interactive::Dashboard.progress_bar(70, width: 10)
    assert_equal "███████░░░", bar
  end

  # .workflow_line

  def test_workflow_line_renders_with_number_label_paid_icon_and_status
    step = {key: :resume, label: "Resume", paid: true}
    line = Jojo::Commands::Interactive::Dashboard.workflow_line(3, step, :generated, width: 50)

    assert_includes line, "3."
    assert_includes line, "Resume"
    assert_includes line, "$"
    assert_includes line, "✓"
  end

  def test_workflow_line_pads_label_to_align_columns
    step = {key: :faq, label: "FAQ", paid: true}
    line = Jojo::Commands::Interactive::Dashboard.workflow_line(6, step, :ready, width: 50)

    # Label should be padded
    assert_match(/FAQ\s+\$/, line)
  end

  # .render

  def test_render_renders_complete_dashboard_with_header_and_workflow
    application = build_dashboard_application
    output = Jojo::Commands::Interactive::Dashboard.render(application)

    assert_includes output, "Jojo"
    assert_includes output, "acme-corp-dev"
    assert_includes output, "Acme Corp"
    assert_includes output, "1."
    assert_includes output, "Job Description"
    assert_includes output, "[q] Quit"
  end

  def test_render_includes_status_legend
    application = build_dashboard_application
    output = Jojo::Commands::Interactive::Dashboard.render(application)

    assert_includes output, "✓ Generated"
    assert_includes output, "* Stale"
    assert_includes output, "○ Ready"
    assert_includes output, "× Blocked"
  end

  private

  def build_dashboard_application
    application = Minitest::Mock.new
    application.expect :slug, "acme-corp-dev"
    application.expect :company_name, "Acme Corp"

    # Mock base_path calls for all_statuses (many calls due to status checks)
    50.times { application.expect :base_path, @tmpdir }

    application
  end
end
