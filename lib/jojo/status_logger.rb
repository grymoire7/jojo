require "json"

module Jojo
  class StatusLogger
    attr_reader :log_path

    def initialize(log_path)
      @log_path = log_path
    end

    def log(message = nil, **metadata)
      entry = {timestamp: timestamp}.merge(metadata)
      entry[:message] = message if message

      File.open(log_path, "a") do |f|
        f.write(entry.to_json + "\n")
      end
    end

    private

    def timestamp
      Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end
  end
end
