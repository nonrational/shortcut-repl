# An initiative represents a line-item in a planning spreadsheet and a corresponding shortcut epic.
class SheetInitiative
  include ActiveModel::Model
  attr_accessor :row_data, :row_index, :spreadsheet_id, :spreadsheet_range, :sheet_name

  def row
    @row ||= SheetRow.new(row_data: row_data, row_index: row_index, sheet_name: sheet_name)
  end

  def story?
    /story-/.match?(row.shortcut_id)
  end

  def epic?
    /epic-/.match?(row.shortcut_id)
  end

  def epic_id
    @epic_id ||= row.shortcut_id.split("-")[1].to_i if epic?
  end

  def epic
    @epic ||= Scrb.current_epics.find { |e| e.id == epic_id } if epic?
  end

  def any_mismatch?
    !name_match? or !state_match? or !target_date_match?
  end

  def move_document_to_correct_drive_location
    # We tend to write documents and then share them with the right audience.
  end

  def sheets_v4
    @sheets_v4 ||= Google::Apis::SheetsV4::SheetsService.new
  end

  def auth_client
    @auth_client ||= GoogleCredentials.load!
  end

  def copy_epic_name_to_sheet
    # Create the request with the hyperlinked value
    value_range = Google::Apis::SheetsV4::ValueRange.new(
      range: row.cell_range_by_column_name(:hyperlinked_name),
      values: [
        ["=HYPERLINK(\"#{row.name_hyperlink}\", \"#{epic.name}\")"]  # This sets the value of B2 to a hyperlink.
      ]
    )

    sheets_v4.update_spreadsheet_value(
      spreadsheet_id,
      row.cell_range_by_column_name(:hyperlinked_name),
      value_range,
      value_input_option: "USER_ENTERED",
      options: {authorization: auth_client}
    )
  end

  def synchronize
    # prefer names from epics
    # prefer states from sheet
    # prefer target_dates from sheet
    # maybe check which one was updated more recently?
  end

  def sync_epic!
    attrs = {}
    attrs[:name] = row.name if row.name
    attrs[:epic_state_id] = sheet_status_as_workflow_state.id if sheet_status_as_workflow_state
    attrs[:deadline] = row.target_date.to_datetime.iso8601 if row.target_date

    puts attrs.to_json

    response = epic.update(attrs)

    binding.pry

    if response.success?
      @epic = Epic.new(response)
    else
      binding.pry
    end
  end

  def sheet_status_as_workflow_state
    EpicWorkflow.fetch.find_state_by_name(row.status)
  end

  def sync_status
    {
      name_match: name_match?,
      state_match: state_match?,
      target_date_match: target_date_match?
    }
  end

  def name_match?
    row.name.downcase == epic.name.downcase
  end

  def state_match?
    row.status.delete(" ") == epic.workflow_state.name.delete(" ")
  end

  def target_date_match?
    row.target_date == epic.target_date&.to_date
  end

  def to_s
    if epic.present?
      ["epic", epic.number, epic.name, row.target_date, epic.target_date&.to_date&.iso8601].join(",")
    elsif epic?
      ["epic", row.shortcut_id, "ERR!", nil, nil].join(",")
    elsif story?
      ["story", "ERR!", "ERR!", nil, nil].join(",")
    else
      ["ERR!", "ERR!", "ERR!", nil, nil].join(",")
    end
  end
end