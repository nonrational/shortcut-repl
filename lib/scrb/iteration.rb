module Scrb
  class Iteration
    include ActiveModel::Model

    def self.find_current
      all.find(&:current?)
    end

    def self.find_previous
      all.select(&:finished?).max_by(&:end_date)
    end

    def self.all
      ::Scrb.shortcut.iterations.list[:content].map { |h| Iteration.new(h) }
    end

    def move_unfinished_to(iteration)
      stories.each do |s|
        # s.update(...)
      end
    end

    attr_reader :created_at, :start_date, :end_date
    attr_accessor :app_url, :associated_groups, :entity_type, :follower_ids, :global_id,
      :group_ids, :group_mention_ids, :id, :label_ids, :labels, :member_mention_ids, :mention_ids,
      :name, :stats, :status, :updated_at

    def stories
      @stories ||= ::Scrb.shortcut.iterations(id).stories.list[:content].map { |s| Story.new(s) }
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
end
