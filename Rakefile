require 'rake/testtask'
require 'fileutils'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
end

namespace :sync do
  desc "Sync source file with the main project."
  task :source do
    puts "copying source code..."
    FileUtils.cp_r Dir.glob("lib/*"), "/Users/ditsing/Git/cloud-ruby-dev/lib/"
  end
  task :scallion do
    puts "copying source code..."
    FileUtils.cp_r Dir.glob("lib/*"), "/Users/ditsing/Git/scallion/lib/"
  end
end

desc "Run tests"
task :default => :test
task :deploy => :'sync:source'
task :scallion => :'sync:scallion'
