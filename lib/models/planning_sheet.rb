require "google/apis/sheets_v4"

class PlanningSheet
  def sync_names_from_shortcut
    name_mismatch_initiatives.map do |i|
      # this doesn't have a success? method
      i.pull_name_from_epic
    end
  end

  def confirm_and_copy_each_sheet_status_to_epic
    status_mismatch_initiatives.each do |i|
      ap({name: i.row.name, row_status: i.row.status, epic_state: i.epic.workflow_state.name, app_url: i.epic.app_url})
      print "Is row_status more correct than epic status? y/[n]: "
      copy = gets
      i.copy_sheet_status_to_epic! if /[Yy]/.match?(copy)
    end

    :ok
  rescue => e
    binding.pry
  end

  def status_mismatch_initiatives
    initiatives.reject(&:status_match?)
  end

  def name_mismatch_initiatives
    initiatives.reject(&:name_match?)
  end

  def last_updated_at
    binding.pry
  end

  def initiatives
    @initiatives ||= begin
      sheet.data[0].row_data.drop(1).map.with_index do |row, idx|
        SheetInitiative.new(
          row_data: row,
          row_index: idx + 2, # google sheets use 1-based numbering, and we dropped the index.
          spreadsheet_id: spreadsheet_id,
          spreadsheet_range: spreadsheet_range,
          sheet_name: spreadsheet_range.split("!").first
        )
      end.filter(&:epic?).filter { |si| si.epic.present? }
    end
  end

  def drive_v3
    @drive_v3 ||= Google::Apis::DriveV3::DriveService.new.tap { |s| s.authorization = auth_client }
  end

  def sheets_v4
    @sheets_v4 ||= Google::Apis::SheetsV4::SheetsService.new.tap { |s| s.authorization = auth_client }
  end

  def sheet
    @sheet ||= spreadsheet.sheets.first
  end

  def last_modified_at
    drive_v3.get_file(spreadsheet_id, fields: "modifiedTime").modified_time
  end

  def spreadsheet
    @spreadsheet ||= sheets_v4.get_spreadsheet(spreadsheet_id, include_grid_data: true, ranges: [spreadsheet_range])
  end

  def spreadsheet_id
    Scrb.fetch_config!("planning-sheet-id")
  end

  def spreadsheet_range
    Scrb.fetch_config!("planning-sheet-range")
  end

  def auth_client
    @auth_client ||= GoogleCredentials.load!
  end
end
