class EpicWorkflow
  include ActiveModel::Model

  attr_accessor :entity_type, :id, :created_at, :updated_at, :default_epic_state_id, :epic_states

  class << self
    def fetch
      @workflow ||= begin
        workflow = new(ScrbClient.get("/epic-workflow"))
        workflow.epic_states = workflow.epic_states.map { |es| EpicWorkflowState.new(es) }
        workflow
      end
    end
  end

  class EpicWorkflowState
    include ActiveModel::Model
    attr_accessor :description, :entity_type, :name, :global_id, :type, :updated_at, :id, :position, :created_at
  end
end
