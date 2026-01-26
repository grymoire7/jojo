# frozen_string_literal: true

require_relative "../../test_helper"

describe Jojo::UI::Dashboard do
  describe ".status_icon" do
    it "returns checkmark for generated" do
      _(Jojo::UI::Dashboard.status_icon(:generated)).must_equal "✓"
    end

    it "returns bread for stale" do
      _(Jojo::UI::Dashboard.status_icon(:stale)).must_equal "*"
    end

    it "returns circle for ready" do
      _(Jojo::UI::Dashboard.status_icon(:ready)).must_equal "○"
    end

    it "returns lock for blocked" do
      _(Jojo::UI::Dashboard.status_icon(:blocked)).must_equal "×"
    end
  end

  describe ".paid_icon" do
    it "returns money bag for paid commands" do
      _(Jojo::UI::Dashboard.paid_icon(true)).must_equal "$"
    end

    it "returns empty string for free commands" do
      _(Jojo::UI::Dashboard.paid_icon(false)).must_equal " "
    end
  end

  describe ".progress_bar" do
    it "renders empty bar for 0%" do
      bar = Jojo::UI::Dashboard.progress_bar(0, width: 10)
      _(bar).must_equal "░░░░░░░░░░"
    end

    it "renders full bar for 100%" do
      bar = Jojo::UI::Dashboard.progress_bar(100, width: 10)
      _(bar).must_equal "██████████"
    end

    it "renders partial bar for 50%" do
      bar = Jojo::UI::Dashboard.progress_bar(50, width: 10)
      _(bar).must_equal "█████░░░░░"
    end

    it "renders partial bar for 70%" do
      bar = Jojo::UI::Dashboard.progress_bar(70, width: 10)
      _(bar).must_equal "███████░░░"
    end
  end

  describe ".workflow_line" do
    it "renders a workflow line with number, label, paid icon, and status" do
      step = {key: :resume, label: "Resume", paid: true}
      line = Jojo::UI::Dashboard.workflow_line(3, step, :generated, width: 50)

      _(line).must_include "3."
      _(line).must_include "Resume"
      _(line).must_include "$"
      _(line).must_include "✓"
    end

    it "pads label to align columns" do
      step = {key: :faq, label: "FAQ", paid: true}
      line = Jojo::UI::Dashboard.workflow_line(6, step, :ready, width: 50)

      # Label should be padded
      _(line).must_match(/FAQ\s+\$/)
    end
  end

  describe ".render" do
    before do
      @temp_dir = Dir.mktmpdir
      @employer = Minitest::Mock.new
      @employer.expect :slug, "acme-corp-dev"
      @employer.expect :company_name, "Acme Corp"

      # Mock base_path calls for all_statuses (many calls due to status checks)
      50.times { @employer.expect :base_path, @temp_dir }
    end

    after do
      FileUtils.rm_rf(@temp_dir)
    end

    it "renders complete dashboard with header and workflow" do
      output = Jojo::UI::Dashboard.render(@employer)

      _(output).must_include "Jojo"
      _(output).must_include "acme-corp-dev"
      _(output).must_include "Acme Corp"
      _(output).must_include "1."
      _(output).must_include "Job Description"
      _(output).must_include "[q] Quit"
    end

    it "includes status legend" do
      output = Jojo::UI::Dashboard.render(@employer)

      _(output).must_include "✓ Generated"
      _(output).must_include "* Stale"
      _(output).must_include "○ Ready"
      _(output).must_include "× Blocked"
    end
  end
end
