# frozen_string_literal: true

require "uri"

module Jojo
  module UrlDetector
    def self.url?(source)
      source =~ URI::DEFAULT_PARSER.make_regexp
    end
  end
end
