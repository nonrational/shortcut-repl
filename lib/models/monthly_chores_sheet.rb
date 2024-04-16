require "google/apis/sheets_v4"

class MonthlyChoresSheet
  include ActiveModel::Model

  attr_accessor :epic_name

  def create_epic_and_stories
    raise "epic_name is required" unless epic_name.present?

    if epic.nil?
      puts "Creating Epic: #{epic_attrs[:name]}"
      @epic = Epic.create(epic_attrs)
    else
      puts "Found Epic: #{epic.name}"
    end

    story_row_data.filter { |s| s[:name].present? }.each do |story_attrs|
      puts "Creating Story: #{story_attrs[:name]}"
      Story.create(story_attrs)
      # ap story_attrs
    rescue => e
      binding.pry
    end
  end

  def epic
    @epic ||= Epic.search(epic_attrs[:name]).find { |e| e.name == epic_attrs[:name] }
  end

  def epic_attrs
    {
      name: epic_name,
      description: "Monthly Tech Chores :tada:",
      objective_ids: [14005], # this is the tech debt / misc objective,
      planned_start_date: DateTime.now.beginning_of_month.iso8601,
      deadline: DateTime.now.end_of_month.iso8601
    }
  end

  # https://developer.shortcut.com/api/rest/v3#Create-Story
  def story_row_data
    sheet.data[0].row_data.drop(1).map do |row|
      {
        name: row.values[0].formatted_value,
        story_type: row.values[1].formatted_value,
        description: description_with_attribution(row.values[2].formatted_value),
        project_id: row.values[3].formatted_value,
        group_id: product_group_id,
        epic_id: epic&.id,
        workflow_state_id: ready_workflow_state_id
      }
    end
  end

  def description_with_attribution(desc)
    (desc || "") + "\n\n\n[📝 Edit Template](https://docs.google.com/spreadsheets/d/#{spreadsheet_id}/edit)"
  end

  def drive_v3
    @drive_v3 ||= Google::Apis::DriveV3::DriveService.new.tap { |s| s.authorization = auth_client }
  end

  def sheets_v4
    @sheets_v4 ||= Google::Apis::SheetsV4::SheetsService.new.tap { |s| s.authorization = auth_client }
  end

  def sheet
    @sheet ||= begin
      spreadsheet.sheets.first
    end
  end

  def spreadsheet
    @spreadsheet ||= sheets_v4.get_spreadsheet(spreadsheet_id, include_grid_data: true, ranges: [spreadsheet_range])
  end

  def ready_workflow_state_id
    @ready_workflow_state_id ||= Workflow.default.workflow_states.find { |s| s.name =~ /Ready/ }.id
  end

  def product_group_id
    @product_group_id ||= Group.all.find { |g| g.name =~ /Product/ }.id
  end

  def objective_ids
    [Scrb.fetch_config!("technical-objective-id")]
  end

  def spreadsheet_id
    Scrb.fetch_config!("chores-epic-sheet-id")
  end

  def spreadsheet_range
    Scrb.fetch_config!("chores-epic-sheet-range")
  end

  def auth_client
    @auth_client ||= GoogleCredentials.load!
  end
end
