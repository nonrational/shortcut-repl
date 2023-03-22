require 'csv'
require 'awesome_print'

module Scrb
  def self.shortcut
    token = ENV['SHORTCUT_API_TOKEN']
    raise "Missing SHORTCUT_API_TOKEN" if token.nil?

    ShortcutRuby::Shortcut.new(token)
  end

  def self.current_iteration
    shortcut.iterations.list[:content].map { |h| Iteration.new(h) }.select(&:current?)
  end

  class Story
    include ActiveModel::Model

    attr_accessor :app_url, :archived, :blocked, :blocker, :comment_ids, :completed, :completed_at,
                  :completed_at_override, :created_at, :custom_fields, :cycle_time, :deadline, :entity_type,
                  :epic_id, :estimate, :external_id, :external_links, :file_ids, :follower_ids,
                  :global_id, :group_id, :group_mention_ids, :id, :iteration_id, :label_ids, :labels,
                  :lead_time, :linked_file_ids, :member_mention_ids, :mention_ids, :moved_at, :name,
                  :num_tasks_completed, :owner_ids, :position, :previous_iteration_ids,
                  :project_id, :requested_by_id, :started, :started_at, :started_at_override,
                  :stats, :story_links, :story_template_id, :story_type, :task_ids, :updated_at,
                  :workflow_id, :workflow_state_id

    def update(attrs)
      ::Scrb.shortcut.stories(id).update(attrs)
    end
  end

  class Iteration
    include ActiveModel::Model

    def self.find_current
      ::Scrb.shortcut.iterations.list[:content].map { |h| Iteration.new(h) }.select(&:current?).first
    end

    def self.find_previous
      ::Scrb.shortcut.iterations.list[:content].map { |h| Iteration.new(h) }.select(&:finished?).sort_by(&:end_date).last
    end

    attr_accessor :app_url, :associated_groups, :created_at, :end_date, :entity_type, :follower_ids, :global_id,
                  :group_ids, :group_mention_ids, :id, :label_ids, :labels, :member_mention_ids, :mention_ids,
                  :name, :start_date, :stats, :status, :updated_at

    def stories
      @stories ||= ::Scrb.shortcut.iterations(id).stories.list[:content].map { |s| Scrb::Story.new(s) }
    end

    def current?
      status == "started" # end_date > Date.today and start_date <= Date.today
    end

    def finished?
      status == "done"
    end

    def created_at=(datestr)
      @created_at = Date.parse(datestr)
    end

    def start_date=(datestr)
      @start_date = Date.parse(datestr)
    end

    def end_date=(datestr)
      @end_date = Date.parse(datestr)
    end
  end

  class IterationFinishAutomation
    include ActiveModel::Model
  end

  class CsvImport
    include ActiveModel::Model

    attr_writer :filepath

    def save!
      CSV.foreach(filepath, headers: true) do |row|
        ap row
        result = api.stories.create(row.to_h)
        binding.pry unless result[:code] == "201"
      end
    end

    def api
      ShortcutRuby::Shortcut.new(ENV['SHORTCUT_API_TOKEN'])
    end

    def filepath
      @filepath ||= "stories.csv"
    end
  end
end
