module Jojo
  module OverwriteHelper
    private

    def env_overwrite?
      %w[1 true yes].include?(ENV['JOJO_ALWAYS_OVERWRITE']&.downcase)
    end
  end
end
