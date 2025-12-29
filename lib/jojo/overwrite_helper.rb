module Jojo
  module OverwriteHelper
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
