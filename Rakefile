require "bundler/setup"
require "minitest/test_task"

task default: "test:all"

# Minitest::TestTask generates a :slow sub-task that shells out to `rake <name>`.
# It is namespace-unaware, so these must be defined outside any namespace block
# with the full "test:unit" name so the generated `rake test:unit` resolves correctly.
Minitest::TestTask.create("test:unit") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_prelude = 'require "test_helper"'
  t.test_globs = ["test/unit/**/*_test.rb"]
end

Minitest::TestTask.create("test:integration") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_prelude = 'require "test_helper"'
  t.test_globs = ["test/integration/**/*_test.rb"]
end

Minitest::TestTask.create("test:minitest") do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_prelude = 'require "test_helper"'
  t.test_globs = ["test/unit/**/*_test.rb", "test/integration/**/*_test.rb"]
end

namespace :test do
  desc "Run Standard Ruby style checks"
  task :standard do
    puts "Running Standard Ruby style checks..."
    system("bundle exec standardrb")
  end

  desc "Run all tests and style checks"
  task all: [:standard, "test:minitest"]
end
