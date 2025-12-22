require 'thor'
require 'dotenv/load'

module Jojo
  VERSION = '0.1.0'
end

require_relative 'jojo/config'
require_relative 'jojo/employer'
require_relative 'jojo/cli'
