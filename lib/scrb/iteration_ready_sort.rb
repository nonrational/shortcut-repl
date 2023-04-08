module Scrb
  class IterationReadySort
    attr_reader :iteration

    def initialize(attrs)
      @iteration = attrs[:iteration] || Iteration.find_current
    end

    def run
      sorted_stories.reverse.each_with_index do |story, i|
        # move story to the top of the iteration
        ScrbClient.put("/stories/#{story.id}", body: {move_to: :first}.to_json)
      end
    end

    def sorted_stories
      ready_stories.sort_by { |s| sort_order_for(s) }
    end

    def in_order?
      sorted_stories.map(&:id) == ready_stories.map(&:id)
    end

    # for debugging purposes only
    def preview
      sorted_stories.map do |s|
        [s.name, s.priority_position + story_type_position(s), epic_product_area_position(s), s.priority&.name, s.product_area&.name, s.story_type]
      end
    end

    def sort_order_for(story)
      [
        story.priority_position + story_type_position(story),
        epic_product_area_position(story),
        story.id
      ]
    end

    def story_type_position(story)
      {
        feature: 0,
        bug: -1,
        chore: 1
      }[story.story_type.to_sym] || 0
    end

    def epic_product_area_position(story)
      # TODO: consider deadlines in sorting
      # TODO: consider a story's position within its epic
      in_progress_epics.find_index { |e| e.id == story.epic_id } || (story.product_area_position * 3)
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
      @ready_stories ||= iteration.stories.filter(&:ready?).sort_by(&:position)
    end
  end
end
