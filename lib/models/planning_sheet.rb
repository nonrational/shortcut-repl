require "google/apis/sheets_v4"

class PlanningSheet
  def sync_names_from_shortcut
    name_mismatch_initiatives.map do |i|
      i.copy_epic_name_to_sheet.tap do |result|
        binding.pry unless result.success?
      end
    end
  end

  def name_mismatch_initiatives
    initiatives.reject(&:name_match?)
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

  def sheets_v4
    @sheets_v4 ||= Google::Apis::SheetsV4::SheetsService.new
  end

  def sheet
    @sheet ||= spreadsheet.sheets.first
  end

  def spreadsheet
    @spreadsheet ||= sheets_v4.get_spreadsheet(spreadsheet_id, include_grid_data: true, ranges: [spreadsheet_range], options: {authorization: auth_client})
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
