class IterationReadySort
  attr_reader :iteration

  def initialize(attrs = {})
    @iteration = attrs[:iteration] || Iteration.find_current
  end

  def run
    return true, [] if sorted?

    move_results = sorted_stories.reverse.map do |story, i|
      # move story to the top of the iteration
      ScrbClient.put("/stories/#{story.id}", body: {move_to: :first}.to_json)
    end

    [move_results.all?(&:success?), move_results]
  end

  def sorted_stories
    ready_stories.sort_by { |s| sort_order_for(s) }
  end

  def sorted?
    sorted_stories.map(&:id) == ready_stories.map(&:id)
  end

  # for debugging purposes only
  def preview
    sorted_stories.map do |s|
      [s.id, s.name, epic_product_area_position(s), sort_order_for(s)].join(" - ")
    end
  end

  def sort_order_for(story)
    [
      story.priority_position + story_type_modifier(story) + story_blocked_modifier(story),
      story_has_target_date_rank(story),
      epic_product_area_position(story),
      story.id
    ]
  end

  def story_has_target_date_rank(story)
    story.target_date.present? ? -1 : 1
  end

  def story_blocked_modifier(story)
    if story.blocked?
      1
    elsif story.blocker?
      -1
    else
      0
    end
  end

  def story_type_modifier(story)
    {
      feature: 0,
      bug: -1,
      chore: 1
    }[story.story_type.to_sym] || 0
  end

  def epic_product_area_position(story)
    # TODO: consider a story's position within its epic
    in_progress_epics.find_index { |e| e.id == story.epic_id } || story.technical_area_priority
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
