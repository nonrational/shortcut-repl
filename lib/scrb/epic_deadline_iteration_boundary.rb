module Scrb
  class EpicDeadlineIterationBoundary
    include ActiveModel::Model

    def run
      # get all epics with a deadline
      # for every epic, find the iteration that contains the deadline
      # update the deadline to the end_date of the iteration
      in_progress_epics.each do |e|
        next if e.deadline.nil?
        if e.target_iteration&.end_date != e.deadline
          puts "Updating epic #{e.name} with deadline #{e.deadline} to #{e.target_iteration&.end_date}"
          e.update(deadline: e.target_iteration&.end_date)
        end
      end
    end

    def in_progress_epics
      @in_progress_epics ||= Scrb::Epic.in_progress
    end
  end
end
