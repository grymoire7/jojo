source "https://rubygems.org"

ruby "3.4.5"

gem "thor", "~> 1.3"
gem "ruby_llm", "~> 1.9"
gem "deepsearch-rb", "~> 0.1"
gem "dotenv", "~> 3.1"
gem "html-to-markdown", "~> 2.16"
gem "reline"
gem "tty-prompt", "~> 0.23"
gem "tty-box", "~> 0.7"          # Box drawing for TUI
gem "tty-cursor", "~> 0.7"       # Cursor movement
gem "tty-reader", "~> 0.9"       # Key input handling
gem "tty-screen", "~> 0.8"       # Terminal dimensions

group :development, :test do
  gem "minitest", "~> 5.25"
  gem "minitest-reporters", "~> 1.7"
  gem "standard", "~> 1.0"
  gem "rake", "~> 13.0"
end

group :test do
  gem "simplecov", require: false
  gem "simplecov_json_formatter", require: false
  gem "vcr"
  gem "webmock"
end
