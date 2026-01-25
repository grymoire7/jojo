require "thor"
require "dotenv/load"

module Jojo
  VERSION = "0.1.0"
end

require_relative "jojo/state_persistence"
require_relative "jojo/config"
require_relative "jojo/workflow"
require_relative "jojo/employer"
require_relative "jojo/overwrite_helper"
require_relative "jojo/ai_client"
require_relative "jojo/prompts/job_description_prompts"
require_relative "jojo/job_description_processor"
require_relative "jojo/cli"
