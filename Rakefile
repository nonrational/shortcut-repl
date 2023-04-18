# Rakefile
require "bundler/setup"
Bundler.require
require "active_support"
require "active_model"
require "shortcut_ruby"
require "dotenv/load"
require "awesome_print"

def load_paths!
  path = File.expand_path("..", __FILE__)
  files = Dir.glob("#{path}/**/*.rb").sort
  files.each do |f|
    # puts f
    load f
  end
end

namespace :iteration do
  desc "Preview the next handful iteration start/end dates"
  task :preview do
    load_paths!
    curr = Scrb::Iteration.find_futuremost
    6.times { puts curr = curr.build_next }
  end

  desc "Create the next iteration"
  task :create_next do
    load_paths!
    curr = Scrb::Iteration.find_futuremost
    curr.build_next.save
  end
end

namespace :project_sync do
  desc "Ensure that all stories with a project have the correct product area set"
  task :run do
    load_paths!
    Scrb::BulkProjectSync.new.run
  end
end

desc "Export the config.yml file as a base64 encoded string"
task :export_config do
  load_paths!
  config = Base64.encode64(YAML.load_file("config.yml").to_s).tr("\n", "")
  puts "export SCRB_CONFIG='#{config}'"
end

namespace :iteration_ready_sort do
  desc "Sort all the stories in the ready column in the current iteration by epic and priority"
  task :run do
    load_paths!
    Scrb::IterationReadySort.new.run
  end

  desc "Preview the stories that would be sorted in the ready column in the current iteration by epic and priority"
  task :preview do
    load_paths!
    puts Scrb::IterationReadySort.new.preview
  end
end
