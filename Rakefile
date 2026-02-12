require "minitest/test_task"

task default: "test:all"

namespace :test do
  Minitest::TestTask.create(:unit) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.warning = false
    t.test_prelude = 'require "test_helper"'
    t.test_globs = ["test/unit/**/*_test.rb"]
  end

  Minitest::TestTask.create(:integration) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.warning = false
    t.test_prelude = 'require "test_helper"'
    t.test_globs = ["test/integration/**/*_test.rb"]
  end

  Minitest::TestTask.create(:minitest) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.warning = false
    t.test_prelude = 'require "test_helper"'
    t.test_globs = ["test/unit/**/*_test.rb", "test/integration/**/*_test.rb"]
  end

  desc "Run Standard Ruby style checks"
  task :standard do
    puts "Running Standard Ruby style checks..."
    system("bundle exec standardrb")
  end

  desc "Run all tests and style checks"
  task all: [:standard, :minitest]
end
