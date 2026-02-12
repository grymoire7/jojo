# frozen_string_literal: true

module Jojo
  module TimeFormatter
    def self.time_ago(time)
      seconds = Time.now - time
      case seconds
      when 0..59
        "just now"
      when 60..3599
        "#{(seconds / 60).to_i} minutes ago"
      when 3600..86399
        "#{(seconds / 3600).to_i} hours ago"
      else
        "#{(seconds / 86400).to_i} days ago"
      end
    end
  end
end
