require "minitest/test_task"

task default: "test:usual"

namespace :test do
  Minitest::TestTask.create(:unit) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.warning = false
    t.test_globs = ["test/unit/**/*_test.rb"]
  end

  Minitest::TestTask.create(:integration) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.warning = false
    t.test_globs = ["test/integration/**/*_test.rb"]
  end

  Minitest::TestTask.create(:minitest) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.warning = false
    t.test_globs = ["test/unit/**/*_test.rb", "test/integration/**/*_test.rb", "test/service/**/*_test.rb"]
  end

  Minitest::TestTask.create(:free) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.warning = false
    t.test_globs = ["test/unit/**/*_test.rb", "test/integration/**/*_test.rb"]
  end

  desc "Run service tests (WARNING: may incur costs)"
  task :service do
    puts "WARNING: You are about to run service tests which may incur costs. Do you want to continue? (y/n)"
    answer = $stdin.gets.chomp.downcase
    unless answer == "y"
      puts "Aborting service tests."
      exit
    end
    system("bundle exec ruby -Ilib:test -e 'Dir.glob(\"./test/service/**/*_test.rb\").each { |f| require f }'")
  end

  desc "Run Standard Ruby style checks"
  task :standard do
    puts "Running Standard Ruby style checks..."
    system("bundle exec standardrb")
  end

  desc "Run the non-service tests and style checks"
  task usual: [:standard, :free]

  desc "Run all tests and style checks (may incur costs)"
  task all: [:standard, :minitest]
end
