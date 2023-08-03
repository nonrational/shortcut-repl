class BulkMissingIterationAssignment
  include ActiveModel::Model

  def run
    raise "not implmented"
    # get all completed stories without an iteration
    # find what was the current iteration on the date it was completed
    # assign the correct iteration to each completed iterationless story
  end
end
