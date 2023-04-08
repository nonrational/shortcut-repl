module Scrb
  class IterationReadySort
    def sorted_stories
      ready_stories.sort_by do |story|
        [
          in_progress_epics_by_id[story.epic_id]&.first&.position || 99,
          story.priority_position
        ]
      end
    end

    def priority_values_by_id
      priority_custom_field.values.group_by(&:id)
    end

    def in_progress_epics_by_id
      @in_progress_epics ||= Epic.all.filter(&:in_progress?).group_by(&:id)
    end

    def ready_stories
      @ready_stories ||= current_iteration.stories.filter(&:ready?)
    end

    def current_iteration
      @current_iteration ||= Iteration.find_current
    end

    def ready_state_name
      @ready_for_name ||= YAML.load_file("config.yml")["ready-state-name"]
    end
  end
end
