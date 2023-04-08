module Scrb
  class Story
    include ActiveModel::Model

    def self.all
    end

    attr_accessor :app_url, :archived, :blocked, :blocker, :comment_ids, :completed, :completed_at,
      :completed_at_override, :created_at, :custom_fields, :cycle_time, :deadline, :entity_type,
      :epic_id, :estimate, :external_id, :external_links, :file_ids, :follower_ids,
      :global_id, :group_id, :group_mention_ids, :id, :iteration_id, :label_ids, :labels,
      :lead_time, :linked_file_ids, :member_mention_ids, :mention_ids, :moved_at, :name,
      :num_tasks_completed, :owner_ids, :position, :previous_iteration_ids,
      :project_id, :requested_by_id, :started, :started_at, :started_at_override,
      :stats, :story_links, :story_template_id, :story_type, :task_ids, :updated_at,
      :workflow_id, :workflow_state_id

    def ready?
      workflow_state_id == Scrb.ready_state["id"]
    end

    def priority_position
      @priority_position ||= Scrb.priority_custom_field.find_value_by_id(priority_value_id)&.position || 99
    end

    def priority_value_id
      @priority_value_id ||= custom_fields.find { |cf| cf["field_id"] == Scrb.priority_custom_field.id }.try(:[], "value_id")
    end

    alias_method :started?, :started

    def complete?
      workflow_state_id == 1
    end

    def update(attrs)
      ::Scrb.shortcut.stories(id).update(attrs)
    end
  end
end
