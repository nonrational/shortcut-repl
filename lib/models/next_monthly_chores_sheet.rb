require "google/apis/sheets_v4"

class NextMonthlyChoresSheet
  include ActiveModel::Model

  # By default, this will create chores for the _next_ month,
  # so be sure to backdate this if you're running this on the first of the month.
  attr_writer :as_of

  def next_epic_name
    epic_attrs[:name]
  end

  def create_next_epic
    if epic.present?
      puts "#{epic.name} exists. Bailing out..."
      return
    end

    puts "Creating Epic: #{epic_attrs[:name]}"
    @epic = Epic.create(epic_attrs)

    story_row_data.filter { |s| s[:name].present? }.each do |story_attrs|
      puts "Creating Story: #{story_attrs[:name]}"
      Story.create(story_attrs)
      # ap story_attrs
    rescue => e
      binding.pry
    end
  end

  def as_of
    @as_of ||= Date.today
  end

  def epic
    @epic ||= Epic.search(epic_attrs[:name]).find { |e| e.name == epic_attrs[:name] }
  end

  def starts_at
    @starts_at ||= as_of.at_beginning_of_month.next_month.to_datetime.utc
  end

  def epic_attrs
    {
      name: "#{starts_at.strftime("%B %Y")} Tech Chores",
      description: "Monthly Tech Chores :tada:",
      group_ids: [product_group_id],
      # TODO: Generalize this objective ID
      objective_ids: [14005], # this is the tech debt / misc objective,
      planned_start_date: starts_at.beginning_of_month.iso8601,
      deadline: starts_at.end_of_month.iso8601
    }
  end

  # https://developer.shortcut.com/api/rest/v3#Create-Story
  def story_row_data
    sheet.data[0].row_data.drop(1).map do |row|
      {
        # TODO: Set correct iteration
        # TODO: Set correct Product Area. ProjectSync already has similar logic.
        name: row.values[0].formatted_value,
        story_type: row.values[1].formatted_value,
        description: description_with_attribution(row.values[2].formatted_value),
        group_id: product_group_id,
        epic_id: epic&.id,
        workflow_state_id: ready_workflow_state_id,
        custom_fields: [
          {
            field_id: TechnicalArea.field.id,
            value_id: TechnicalArea.all.find { |ta| ta.name == row.values[9].formatted_value }&.id
          },
          {
            field_id: Priority.field.id,
            value_id: Priority.default.id
          },
          {
            field_id: PartnerImpact.field.id,
            value_id: PartnerImpact.find_by_value("Indirect").id
          }
        ]
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
