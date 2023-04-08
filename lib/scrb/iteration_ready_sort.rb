module Scrb
  class IterationReadySort
    def run
      sorted_stories.reverse.each_with_index do |story, i|
        # Scrb.shortcut.stories(story.id).update(move_to: :first)
        ScrbClient.put("/stories/#{story.id}", body: {move_to: :first}.to_json)
      end
    end

    def sorted_stories
      ready_stories.sort_by { |s| sort_order_for(s) }
    end

    # for debugging purposes only
    def self.run
      sort = Scrb::IterationReadySort.new
      sort.sorted_stories.map { |s| [s.name, sort.epic_product_area_position(s), s.priority&.name, s.product_area&.name, s.id] }
    end

    def sort_order_for(story)
      [
        epic_product_area_position(story),
        story.priority_position,
        story.id
      ]
    end

    def epic_product_area_position(story)
      # TODO: consider deadlines in sorting
      # TODO: consider a story's position within its epic
      in_progress_epics.find_index { |e| e.id == story.epic_id } || (story.product_area_position * 5)
    end

    def priority_values_by_id
      priority_custom_field.values.group_by(&:id)
    end

    def first_in_progress_epic_position
      @first_in_progress_epic_position ||= in_progress_epics.min_by(&:position).position
    end

    def in_progress_epics_by_id
      @in_progress_epics_by_id ||= in_progress_epics.group_by(&:id)
    end

    def in_progress_epics
      @in_progress_epics ||= Epic.all.filter(&:in_progress?).sort_by(&:position)
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
