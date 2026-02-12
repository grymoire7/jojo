# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/jojo/time_formatter"

class TimeFormatterTest < JojoTest
  def test_returns_just_now_for_recent_times
    assert_equal "just now", Jojo::TimeFormatter.time_ago(Time.now - 30)
  end

  def test_returns_minutes_ago
    assert_equal "5 minutes ago", Jojo::TimeFormatter.time_ago(Time.now - 300)
  end

  def test_returns_hours_ago
    assert_equal "2 hours ago", Jojo::TimeFormatter.time_ago(Time.now - 7200)
  end

  def test_returns_days_ago
    assert_equal "3 days ago", Jojo::TimeFormatter.time_ago(Time.now - 259_200)
  end
end
