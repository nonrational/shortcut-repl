require "google/apis/sheets_v4"

class PlanningSheet
  def current_epic_initatives
    # TODO: Update `story?` rows as well.
    initiatives.filter(&:epic?).reject do |i|
      # puts "#{i} is in-sync. Skipping..." if i.in_sync?
      i.in_sync?
    end
  end

  def download!
    puts "Fetching initiatives with epics..."
    initiatives

    puts "Updating sheet with #{current_epic_initatives.count} initiatives..."
    current_epic_initatives.each do |i|
      i.update_sheet
    end
  end

  def upload!
    push_sheet_order_to_shortcut!

    current_epic_initatives.each do |i|
      i.update_epic
      puts i.epic.app_url
      # binding.pry
    end
  rescue => e
    binding.pry
  end

  def upload_interactive
    current_epic_initatives.each do |i|
      # calculate the width from the widest value in the table
      width = i.to_table_data.reduce(0) do |acc, row|
        row.reduce(acc) { |acc, v| [acc, v.to_s.size].max }
      end

      # TODO: figure out how to display tablular data in the console.
      header = i.column_headers.map { |v| v.to_s.ljust(width) }.join(" | ")

      table_data = i.to_table_data.map do |row|
        row.map do |v|
          v.to_s.ljust(width + (/\p{Emoji}/.match?(v) ? 1 : 0))
        end.join(" | ")
      end.join("\n")

      puts header, table_data

      print "Which is more correct? row/epic/[skip]: "
      winner = $stdin.gets

      if /ro?w?/i.match?(winner)
        # write row details to epic
        i.update_epic
      elsif /ep?i?c?/i.match?(winner)
        # write epic details to sheet
        i.update_sheet
      end
    end
  rescue => e
    binding.pry
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

  def to_s
    "PlanningSheet[#{spreadsheet_id}]"
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
