class Scrb::BulkUnfinishedStoryMigration
  include ActiveModel::Model

  def run
    # move all the incomplete stories from the previous iteration to the current iteration
    move_to_current_iteration(incomplete_stories)
  end

  def move_to_current_iteration(stories)
    body = {
      story_ids: stories.map(&:id),
      iteration_id: current_iteration.id
    }.to_json

    ScrbClient.put("/stories/bulk", body: body)
  end

  def incomplete_stories
    @incomplete_stories ||= previous_iteration.stories.reject(&:archived?).reject(&:completed?)
  end

  def previous_iteration
    @previous_iteration ||= Scrb::Iteration.find_previous
  end

  def current_iteration
    @current_iteration ||= Scrb::Iteration.find_current
  end
end
