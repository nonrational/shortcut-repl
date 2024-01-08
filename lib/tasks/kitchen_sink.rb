class KitchenSink
  def self.run_interactive
    puts "Sorting epics by planning sheet order..."
    PlanningSheet.new.push_sheet_order_to_shortcut!
    PlanningSheet.new.sync_names_from_shortcut!
    puts "Sorting ready stories by priority..."
    IterationReadySort.new.run

    PlanningSheet.new.sync_names_from_shortcut!
    PlanningSheet.new.sync_story_stats_from_shortcut!
    PlanningSheet.new.sync_participants_from_shortcut!

    puts "Checking Sheet rows against Shortcut epics..."
    PlanningSheet.new.initiatives.each do |i|
      ap({
        # TODO: Should we use the epic name instead?
        name: i.row.name,
        row_status: i.row.status,
        epic_state: i.epic.workflow_state.name,
        row_target: i.row.target_date,
        epic_target: i.epic.planned_ends_at&.to_date
      })

      print "Which is more correct? row/epic/[skip]: "
      winner = $stdin.gets

      if /ro?w?/i.match?(winner)
        # copy row to epic
        i.push_dates_and_status_to_epic
      elsif /ep?i?c?/i.match?(winner)
        # copy epic to row
        puts "not implemented yet"
      end
    end
  rescue => e
    binding.pry
  end

  def planning_sheet
    @planning_sheet ||= PlanningSheet.new
  end
end
