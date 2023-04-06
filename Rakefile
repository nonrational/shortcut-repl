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
  task :run do
    load_paths!
    Scrb::BulkProjectSync.new.run
  end
end
