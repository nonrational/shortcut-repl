require "google/apis/sheets_v4"

class PlanningSheet
  def self.check
    sheet = new
    mismatched = sheet.initiatives.filter { |i| i.row.name != i.epic.name }

    mismatched.each do |i|
      puts "! [#{i.row.index}] #{i.row.name} ≠ #{i.epic.name}"
    end

    mismatched.count
  end

  def initiatives
    @initiatives ||= sheet.data[0].row_data.map { |row| Initiative.new(row) }.filter(&:epic?).filter { |si| si.epic.present? }
  end

  def sheets_v4
    @sheets_v4 ||= Google::Apis::SheetsV4::SheetsService.new
  end

  def sheet
    @sheet ||= spreadsheet.sheets.first
  end

  def spreadsheet
    @spreadsheet ||= sheets_v4.get_spreadsheet(sheet_id, include_grid_data: true, ranges: ranges, options: {authorization: auth_client})
  end

  def sheet_id
    Scrb.fetch_config!("planning-sheet-ranges")
  end

  def ranges
    Scrb.fetch_config!("planning-sheet-ranges")
  end

  def auth_client
    @auth_client ||= GoogleCredentials.load!
  end
end
