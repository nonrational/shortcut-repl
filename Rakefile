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

load_paths!

namespace :sheet do
  desc "Fetch information from shortcut and update the sheet with it"
  task :pull do
    PlanningSheet.new.download!
  end

  task :"push-interactive" do
    PlanningSheet.new.upload_interactive
  end
end

namespace :iteration do
  desc "Preview the next handful iteration start/end dates"
  task :preview do
    curr = Iteration.find_futuremost
    3.times { puts curr = curr.build_next }
  end

  desc "Move all unfinished stories from the previous iteration to the current iteration"
  task :cutover do
    cutover = BulkUnfinishedStoryMigration.new
    puts "Moving #{cutover.incomplete_stories.count} unfinished stories from #{cutover.previous_iteration.name} to #{cutover.current_iteration.name}"
    cutover.run
  end

  desc "Print a pipe delimited list of all epics that have work scheduled in the current iteration"
  task :kickoff do
    IterationKickoffReport.new.print(:csv)
  end

  desc "Create the next iteration"
  task :create_next do
    curr = Iteration.find_futuremost || Iteration.find_current
    next_iteration = curr.build_next
    puts "Creating #{next_iteration.name} from #{next_iteration.start_date} to #{next_iteration.end_date}"
    curr.build_next.save
  end

  namespace :ready_sort do
    desc "Sort all the stories in the ready column in the current iteration by epic and priority"
    task :run do
      puts "Sorting epics by planning sheet order..."
      # ensure that the priority order reflected in the planning sheet is respected
      PlanningSheet.new.push_sheet_order_to_shortcut!
      # then sort all the "ready" cards in the current iteration
      puts "Sorting ready stories by priority..."
      IterationReadySort.new.run
    end

    task :check do
      Iteration.next(3).each do |iteration|
        sort = IterationReadySort.new(iteration: iteration)
        result_char = sort.sorted? ? "✅" : "❌"
        puts "#{result_char} – #{sort.iteration.name}"
      end
    end

    desc "Preview the stories that would be sorted in the ready column in the current iteration by epic and priority"
    task :preview do
      puts IterationReadySort.new.preview
    end
  end
end

namespace :project_sync do
  desc "Ensure that all stories with a project have the correct product area set"
  task :run do
    BulkProjectSync.new.run
  end
end

namespace :config do
  desc "Export the config.yml file as a base64 encoded string"
  task :export do
    config = Base64.encode64(File.read("config.yml")).tr("\n", "")
    puts "export SCRB_CONFIG='#{config}'"
  end

  desc "Check config is valid"
  task :check do
    expected_keys = YAML.load_file("config.yml.example").keys.to_set
    actual_keys = Scrb.config.keys.to_set

    raise "missing keys: #{(expected_keys - actual_keys).to_a.join(",")}" unless actual_keys.superset?(expected_keys)
    puts "Looks good!"
  end
end
