require "json"

module Jojo
  class StatusLogger
    attr_reader :employer

    def initialize(employer)
      @employer = employer
    end

    def log(message)
      entry = {
        timestamp: timestamp,
        message: message
      }.to_json + "\n"

      File.open(employer.status_log_path, "a") do |f|
        f.write(entry)
      end
    end

    def log_step(step_name, metadata = {})
      entry = {
        timestamp: timestamp,
        step: step_name
      }.merge(metadata)

      File.open(employer.status_log_path, "a") do |f|
        f.write(entry.to_json + "\n")
      end
    end

    private

    def timestamp
      Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end
  end
end
