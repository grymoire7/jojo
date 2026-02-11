# frozen_string_literal: true

require_relative "../../../test_helper"

class Jojo::Commands::Interactive::DashboardTest < JojoTest
  # .status_icon

  def test_status_icon_returns_checkmark_for_generated
    _(Jojo::Commands::Interactive::Dashboard.status_icon(:generated)).must_equal "✓"
  end

  def test_status_icon_returns_star_for_stale
    _(Jojo::Commands::Interactive::Dashboard.status_icon(:stale)).must_equal "*"
  end

  def test_status_icon_returns_circle_for_ready
    _(Jojo::Commands::Interactive::Dashboard.status_icon(:ready)).must_equal "○"
  end

  def test_status_icon_returns_lock_for_blocked
    _(Jojo::Commands::Interactive::Dashboard.status_icon(:blocked)).must_equal "×"
  end

  # .paid_icon

  def test_paid_icon_returns_money_bag_for_paid_commands
    _(Jojo::Commands::Interactive::Dashboard.paid_icon(true)).must_equal "$"
  end

  def test_paid_icon_returns_empty_string_for_free_commands
    _(Jojo::Commands::Interactive::Dashboard.paid_icon(false)).must_equal " "
  end

  # .progress_bar

  def test_progress_bar_renders_empty_bar_for_zero_percent
    bar = Jojo::Commands::Interactive::Dashboard.progress_bar(0, width: 10)
    _(bar).must_equal "░░░░░░░░░░"
  end

  def test_progress_bar_renders_full_bar_for_100_percent
    bar = Jojo::Commands::Interactive::Dashboard.progress_bar(100, width: 10)
    _(bar).must_equal "██████████"
  end

  def test_progress_bar_renders_partial_bar_for_50_percent
    bar = Jojo::Commands::Interactive::Dashboard.progress_bar(50, width: 10)
    _(bar).must_equal "█████░░░░░"
  end

  def test_progress_bar_renders_partial_bar_for_70_percent
    bar = Jojo::Commands::Interactive::Dashboard.progress_bar(70, width: 10)
    _(bar).must_equal "███████░░░"
  end

  # .workflow_line

  def test_workflow_line_renders_with_number_label_paid_icon_and_status
    step = {key: :resume, label: "Resume", paid: true}
    line = Jojo::Commands::Interactive::Dashboard.workflow_line(3, step, :generated, width: 50)

    _(line).must_include "3."
    _(line).must_include "Resume"
    _(line).must_include "$"
    _(line).must_include "✓"
  end

  def test_workflow_line_pads_label_to_align_columns
    step = {key: :faq, label: "FAQ", paid: true}
    line = Jojo::Commands::Interactive::Dashboard.workflow_line(6, step, :ready, width: 50)

    # Label should be padded
    _(line).must_match(/FAQ\s+\$/)
  end

  # .render

  def test_render_renders_complete_dashboard_with_header_and_workflow
    application = build_dashboard_application
    output = Jojo::Commands::Interactive::Dashboard.render(application)

    _(output).must_include "Jojo"
    _(output).must_include "acme-corp-dev"
    _(output).must_include "Acme Corp"
    _(output).must_include "1."
    _(output).must_include "Job Description"
    _(output).must_include "[q] Quit"
  end

  def test_render_includes_status_legend
    application = build_dashboard_application
    output = Jojo::Commands::Interactive::Dashboard.render(application)

    _(output).must_include "✓ Generated"
    _(output).must_include "* Stale"
    _(output).must_include "○ Ready"
    _(output).must_include "× Blocked"
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
