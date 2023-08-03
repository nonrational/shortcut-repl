class Story
  include ActiveModel::Model

  attr_accessor :app_url, :archived, :blocked, :blocker, :branches, :comment_ids, :comments, :commits, :completed,
    :completed_at, :completed_at_override, :created_at, :custom_fields, :cycle_time, :deadline, :description,
    :entity_type, :epic_id, :estimate, :external_id, :external_links, :file_ids, :files, :follower_ids, :global_id,
    :group_id, :group_mention_ids, :id, :iteration_id, :label_ids, :labels, :lead_time, :linked_file_ids, :linked_files,
    :member_mention_ids, :mention_ids, :moved_at, :name, :num_tasks_completed, :owner_ids, :position, :previous_iteration_ids,
    :project_id, :pull_requests, :requested_by_id, :started, :started_at, :started_at_override, :stats, :story_links,
    :story_template_id, :story_type, :task_ids, :tasks, :updated_at, :workflow_id, :workflow_state_id

  alias_method :blocked?, :blocked
  alias_method :blocker?, :blocker
  alias_method :archived?, :archived
  alias_method :started?, :started
  alias_method :completed?, :completed
  [:feature, :bug, :chore].each { |type| define_method("#{type}?") { story_type.to_sym == type } }

  class << self
    def find(id)
      ScrbClient.get("/stories/#{id}")
    end

    def search(query)
      StorySearch.new(query: query).tap(&:fetch_all).stories
    end
  end

  def ready?
    workflow_state_id == Scrb.ready_state.id
  end

  def in_current_iteration?
    iteration_id == Scrb.current_iteration.id
  end

  def workflow
    @workflow ||= Workflow.find(workflow_id)
  end

  def in_workflow_state?(states)
    Array(states).map(&:id).include?(workflow_state_id)
  end

  def workflow_state
    @workflow_state ||= workflow.workflow_states.find { |s| s.id == workflow_state_id }
  end

  def owner_members
    @owner_members ||= owner_ids.map { |uuid| Member.find(uuid) }
  end

  def product_area
    @product_area ||= ProductArea.find_by_id(product_area_value_id)
  end

  def priority
    @priority ||= Scrb.priority_custom_field.find_value_by_id(priority_value_id) || Scrb.default_priority_custom_field
  end

  def product_area_priority
    @product_area_priority ||= product_area&.priority || ProductArea.all.count + 1
  end

  def priority_position
    @priority_position ||= priority.position
  end

  private

  def product_area_value_id
    @product_area_value_id ||= custom_fields.find { |cf| cf["field_id"] == Scrb.product_area_custom_field.id }.try(:[], "value_id")
  end

  def priority_value_id
    @priority_value_id ||= custom_fields.find { |cf| cf["field_id"] == Scrb.priority_custom_field.id }.try(:[], "value_id")
  end
end
