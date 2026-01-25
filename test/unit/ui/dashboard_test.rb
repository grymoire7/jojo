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
end
