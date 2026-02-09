# Pre-load unicode_utils with deprecation warnings suppressed.
# The gem is unmaintained and triggers Ruby 3.4 frozen string literal warnings.
# (transitive dependency: tty-box -> strings -> unicode_utils)
original_deprecated = Warning[:deprecated]
Warning[:deprecated] = false
require "unicode_utils"
Warning[:deprecated] = original_deprecated

require "thor"
require "dotenv/load"

module Jojo
  VERSION = "0.1.0"
end

require_relative "jojo/state_persistence"
require_relative "jojo/config"
require_relative "jojo/commands/interactive/workflow"
require_relative "jojo/commands/interactive/dashboard"
require_relative "jojo/commands/interactive/dialogs"
require_relative "jojo/application"
require_relative "jojo/overwrite_helper"
require_relative "jojo/ai_client"
require_relative "jojo/commands/interactive/runner"
require_relative "jojo/cli"
