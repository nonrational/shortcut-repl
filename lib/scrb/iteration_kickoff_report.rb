require "table_print"
module Scrb
  class IterationKickoffReport
    include ActiveModel::Model

    def print(format = :table)
      tp.set :max_width, 60

      if format == :csv
        puts epic_to_csv_row(epics_with_cards_in_iteration.first).keys.join(sep)
        puts epics_with_cards_in_iteration.map { |e| epic_to_csv_row(e).values.join(sep) }.join("\n")
        puts stories_in_iteration_without_epics.map { |e| story_to_csv_row(e).values.join(sep) }.join("\n")
      else
        puts "Fetching stories for iteration #{Scrb.current_iteration.name}..."
        tp stories_in_iteration_without_epics.map { |e| story_to_csv_row(e) }
        tp epics_with_cards_in_iteration.map { |e| epic_to_csv_row(e) }
      end
    end

    def sep
      ";"
    end

    def story_to_csv_row(s)
      {type: "story", app_url: s.app_url, name: s.name, owners: s.owner_members.map { |m| m&.first_name }.join(" / "), state: s.workflow_state&.name, roadmap: false, deadline: nil}
    end

    def epic_to_csv_row(e)
      {type: "epic", app_url: e.app_url, name: e.name, owners: e.owner_members.map { |m| m&.first_name }.join(" / "), state: e.workflow_state&.name, roadmap: e.roadmap?, deadline: e.deadline&.strftime("%Y-%m-%d")}
    end

    def current_iteration_stories
      @current_iteration_stories ||= Scrb.current_iteration.stories
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
