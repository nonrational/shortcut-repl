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
    3.times { puts curr = curr.build_next }
  end

  task :cutover do
    load_paths!
    cutover = Scrb::BulkUnfinishedStoryMigration.new
    puts "Moving #{cutover.incomplete_stories.count} unfinished stories from #{cutover.previous_iteration.name} to #{cutover.current_iteration.name}"
    cutover.run
  end

  desc "Create the next iteration"
  task :create_next do
    load_paths!
    curr = Scrb::Iteration.find_futuremost
    curr.build_next.save
  end

  namespace :ready_sort do
    desc "Sort all the stories in the ready column in the current iteration by epic and priority"
    task :run do
      load_paths!
      Scrb::IterationReadySort.new.run
    end

    task :check do
      load_paths!
      Scrb::Iteration.next(3).each do |iteration|
        sort = Scrb::IterationReadySort.new(iteration: iteration)
        result_char = sort.sorted? ? "✅" : "❌"
        puts "#{result_char} – #{sort.iteration.name}"
      end
    end

    desc "Preview the stories that would be sorted in the ready column in the current iteration by epic and priority"
    task :preview do
      load_paths!
      puts Scrb::IterationReadySort.new.preview
    end
  end
end

namespace :project_sync do
  desc "Ensure that all stories with a project have the correct product area set"
  task :run do
    load_paths!
    Scrb::BulkProjectSync.new.run
  end
end

namespace :config do
  desc "Export the config.yml file as a base64 encoded string"
  task :export do
    load_paths!
    config = Base64.encode64(File.read("config.yml")).tr("\n", "")
    puts "export SCRB_CONFIG='#{config}'"
  end

  desc "Check config is valid"
  task :check do
    load_paths!
    necessary_keys = YAML.load_file("config.yml.example").keys
    raise "bad" unless Scrb.config.keys.sort == necessary_keys.sort
    puts "Looks good!"
  end
end
