module Scrb
  class IterationKickoffReport
    def print
      puts run
    end

    def run
      epics_with_cards_in_iteration.map do |e|
        [e.app_url, e.name, e.owner_members.map { |m| m&.first_name }.join(" / "), e.workflow_state.name, e.target_iteration&.name || "???"].join(",")
      end
    end

    def epics_with_cards_in_iteration
      @epics_with_cards_in_iteration ||= Scrb::Epic.all.filter(&:stories_in_current_iteration?)
    end
  end
end
