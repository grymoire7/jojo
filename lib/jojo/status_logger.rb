module Jojo
  class StatusLogger
    attr_reader :employer

    def initialize(employer)
      @employer = employer
    end

    def log(message)
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      log_entry = "**#{timestamp}**: #{message}\n\n"

      File.open(employer.status_log_path, 'a') do |f|
        f.write(log_entry)
      end
    end

    def log_step(step_name, metadata = {})
      message_parts = [step_name]

      metadata.each do |key, value|
        message_parts << "#{key.to_s.capitalize}: #{value}"
      end

      log(message_parts.join(" | "))
    end
  end
end
