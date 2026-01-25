# frozen_string_literal: true

require_relative "../../test_helper"

describe Jojo::UI::Dashboard do
  describe ".status_icon" do
    it "returns checkmark for generated" do
      _(Jojo::UI::Dashboard.status_icon(:generated)).must_equal "✅"
    end

    it "returns bread for stale" do
      _(Jojo::UI::Dashboard.status_icon(:stale)).must_equal "🍞"
    end

    it "returns circle for ready" do
      _(Jojo::UI::Dashboard.status_icon(:ready)).must_equal "⭕"
    end

    it "returns lock for blocked" do
      _(Jojo::UI::Dashboard.status_icon(:blocked)).must_equal "🔒"
    end
  end

  describe ".paid_icon" do
    it "returns money bag for paid commands" do
      _(Jojo::UI::Dashboard.paid_icon(true)).must_equal "💰"
    end

    it "returns empty string for free commands" do
      _(Jojo::UI::Dashboard.paid_icon(false)).must_equal "  "
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
end
