# Rakefile
require "bundler/setup"
Bundler.require
require "active_support"
require "active_model"
require "shortcut_ruby"
require "dotenv/load"

def load_paths!
  path = File.expand_path("..", __FILE__)
  files = Dir.glob("#{path}/**/*.rb").sort
  files.each do |f|
    # puts f
    load f
  end
end

namespace :project_sync do
  desc "Ensure that all stories with a project have the correct product area set"
  task :run do
    load_paths!
    Scrb::BulkProjectSync.new.run
  end
end

namespace :iteration_ready_sort do
  desc "Sort all the stories in the ready column in the current iteration by epic and priority"
  task :run do
    load_paths!
    Scrb::IterationReadySort.new.run
  end
end
