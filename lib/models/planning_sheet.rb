require "google/apis/sheets_v4"

class PlanningSheet
  def download!
    initiatives.map do |i|
      puts i

      res_name = i.pull_name_from_epic
      res_stats = i.pull_story_stats_from_epic
      res_parts = i.pull_participants_from_epic

      (res_name.updated_cells + res_stats.updated_cells + res_parts.updated_cells).tap do |s|
        binding.pry unless s == 3
      end
    end
  end

  def upload
  end

  def organize_documents!
    initiatives.map do |i|
      puts i
      i.move_document_to_correct_drive_location
    end
  end

  def push_sheet_order_to_shortcut!
    initiatives.each_cons(2) do |before, after|
      puts "#{before.epic.name}(#{before.row_index}) is before #{after.epic.name}(#{after.row_index})"

      after.epic.update(after_id: before.epic.id).tap do |res|
        binding.pry unless res.success?
      end
    end

    :ok
  end

  def synchronize_status!
    initiatives.each do |i|
      ap({
        name: i.row.name,
        row_status: i.row.status,
        epic_state: i.epic.workflow_state.name,
        row_target: i.row.target_date,
        epic_target: i.epic.planned_ends_at&.to_date
      })

      print "Push workflow state and target date to Shortcut? y/[n]: "

      copy = $stdin.gets
      i.push_dates_and_status_to_epic if /[Yy]/.match?(copy)
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

  # note that this will obey the filter on the sheet
  def initiatives
    @initiatives ||= raw_initiatives.filter { |si| si.epic.present? }
  end

  def raw_initiatives
    @raw_initiatives ||= begin
      sheet.data[0].row_data.drop(1).map.with_index do |row, idx|
        SheetInitiative.new(
          row_data: row,
          row_index: idx + 2, # google sheets use 1-based numbering, and we dropped the index.
          spreadsheet_id: spreadsheet_id,
          spreadsheet_range: spreadsheet_range,
          sheet_name: spreadsheet_range.split("!").first
        )
      end
    end
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
