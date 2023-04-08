class Scrb::BulkUnfinishedStoryMigration
  include ActiveModel::Model

  def run
    raise "not implmented"
    # get the current iteration
    # get the previous iteration
    # get all the unfinished stories from the previous iteration
    # update all unfinished stories to the current iteration
  end
end
