require "google/apis/sheets_v4"

class PlanningSheet
  def organize_documents!
    results = initiatives.map do |i|
      puts "[#{i.row_index}] #{i.row.name}"
      i.move_document_to_correct_drive_location
    end

    binding.pry
  end

  def push_sheet_order_to_shortcut!
    initiatives.each_cons(2) do |pre, post|
      puts "#{pre.epic.name}(#{pre.row_index}) is before #{post.epic.name}(#{post.row_index})"

      post.epic.update(after_id: pre.epic.id).tap do |res|
        binding.pry unless res.success?
      end
    end

    :ok
  end

  def sync_names_from_shortcut!
    initiatives.map do |i|
      # this doesn't have a success? method
      result = i.pull_name_from_epic
      binding.pry unless result.updated_cells == 1
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

  def pull_all_story_stats_from_epics!
    initiatives.each { |i| i.pull_story_stats_from_epic }
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
