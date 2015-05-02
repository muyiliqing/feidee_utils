require 'rake/testtask'
require 'fileutils'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
end

namespace :sync do
  desc "Sync source file with the main project."
  task :source do
    FileUtils.cp_r "/Users/ditsing/Git/cloud-ruby-dev/lib/feidee_utils/lib", "."
    FileUtils.cp_r "/Users/ditsing/Git/cloud-ruby-dev/lib/feidee_utils/test", "."
  end
end

desc "Run tests"
task :default => :test
