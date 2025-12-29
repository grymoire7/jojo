module Jojo
  module OverwriteHelper
    def with_overwrite_check(path, overwrite_flag, &block)
      # Check if file exists
      return yield unless File.exist?(path)

      # Check override mechanisms in precedence order
      return yield if should_overwrite?(overwrite_flag)

      # Prompt user or fail in non-TTY
      if $stdout.isatty
        filename = File.basename(path)
        yield if yes?("#{filename} exists. Overwrite?")
      else
        raise Thor::Error, "Cannot prompt in non-interactive mode. Use --overwrite or set JOJO_ALWAYS_OVERWRITE=true"
      end
    end

    private

    def env_overwrite?
      %w[1 true yes].include?(ENV['JOJO_ALWAYS_OVERWRITE']&.downcase)
    end

    def should_overwrite?(flag)
      # --overwrite flag wins
      return true if flag == true
      # --no-overwrite flag blocks env var
      return false if flag == false
      # Check environment variable
      env_overwrite?
    end
  end
end
