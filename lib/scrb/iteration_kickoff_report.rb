require "table_print"
module Scrb
  class IterationKickoffReport
    def print
      tp.set :max_width, 60

      tp epics_with_cards_in_iteration.map { |e| epic_to_csv_row(e) }

      tp stories_in_iteration_without_epics.map { |e| story_to_csv_row(e) }
    end

    def story_to_csv_row(s)
      {type: "story", app_url: " #{s.app_url} ", name: s.name, owners: s.owner_members.map { |m| m&.first_name }.join(" / "), state: s.workflow_state&.name, target: "N/A"}
    end

    def epic_to_csv_row(e)
      {type: "epic", app_url: " #{e.app_url} ", name: e.name, owners: e.owner_members.map { |m| m&.first_name }.join(" / "), state: e.workflow_state&.name, target: "N/A"}
    end

    def current_iteration_stories
      @current_iteration_stories ||= begin
        puts "Fetching stories for iteration #{Scrb.current_iteration.name}..."
        Scrb.current_iteration.stories
      end
    end

    def stories_in_iteration_without_epics
      @stories_in_iteration_without_epics ||= begin
        current_iteration_stories.filter { |s| s.epic_id.nil? }
      end
    end

    def epics_with_cards_in_iteration
      @epics_with_cards_in_iteration ||= begin
        epic_ids = current_iteration_stories.reject { |s| s.epic_id.nil? }.map(&:epic_id)
        Scrb::Epic.all.filter { |e| epic_ids.include?(e.id) }
      end
    end
  end
end
