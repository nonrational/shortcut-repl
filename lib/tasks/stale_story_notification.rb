class StaleStoryNotification
  include ActiveModel::Model

  def run
    puts "#{stale_stories.count} stale stories found"
  end

  def stale_stories
    Scrb.current_iteration.stories.select { |s| s.in_workflow_state?(stale_workflow_states) }
  end

  def stale_workflow_states
    @stale_workflow_states ||= Workflow.default.workflow_states.select { |s| s.name_ilike?(stale_state_name) }
  end

  def stale_state_name
    @stale_state_name ||= Scrb.fetch_config!("stale-state-name")
  end
end
