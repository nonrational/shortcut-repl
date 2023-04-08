module Scrb
  class Epic
    include ActiveModel::Model

    def self.all
      ScrbClient.get("/epics").map { |e| Epic.new(e) }
    end

    def self.find(id)
      all.find { |e| e.id == id }
    end

    attr_accessor :app_url, :archived, :started, :entity_type, :labels, :mention_ids, :member_mention_ids, :associated_groups,
      :project_ids, :stories_without_projects, :completed_at_override, :productboard_plugin_id, :started_at, :completed_at,
      :name, :global_id, :completed, :productboard_url, :planned_start_date, :state, :milestone_id, :requested_by_id,
      :epic_state_id, :label_ids, :started_at_override, :group_id, :updated_at, :group_mention_ids, :productboard_id,
      :follower_ids, :owner_ids, :external_id, :id, :position, :productboard_name, :deadline, :stats, :created_at

    alias_method :archived?, :archived
    alias_method :started?, :started
    alias_method :completed?, :completed

    def in_progress?
      !archived? && started? && !completed?
    end
  end
end
