# An initiative represents a line-item in a planning spreadsheet and a corresponding shortcut epic.
class SheetInitiative
  include ActiveModel::Model
  attr_accessor :row_data, :row_index, :spreadsheet_id, :spreadsheet_range, :sheet_name

  def pull
    pull_name_from_epic
    pull_target_dates_from_epic
    pull_status_from_epic
    pull_story_stats_from_epic
  end

  def push
    push_dates_and_status_to_epic
  end

  def move_document_to_correct_drive_location
    # TODO: We tend to write documents and then share them with the right audience.
    #       This method should eventually move an individual PAD/RFC to the correct folder.
  end

  #               _      _                  _
  #  _ __ _  _ __| |_   | |_ ___   ___ _ __(_)__
  # | '_ \ || (_-< ' \  |  _/ _ \ / -_) '_ \ / _|
  # | .__/\_,_/__/_||_|  \__\___/ \___| .__/_\__|
  # |_|                               |_|

  def push_dates_and_status_to_epic
    epic_workflow_state = EpicWorkflow.fetch.find_state_by_name(row.status)

    attrs = {deadline: row.target_date&.to_date&.iso8601}

    if epic_workflow_state.present? && epic_workflow_state.id != epic.epic_state_id
      attrs[:epic_state_id] = epic_workflow_state.id
    end

    result = epic.update(attrs)
    binding.pry unless result.success?
    @epic = Epic.new(result)
  end

  #            _ _    __                          _
  #  _ __ _  _| | |  / _|_ _ ___ _ __    ___ _ __(_)__
  # | '_ \ || | | | |  _| '_/ _ \ '  \  / -_) '_ \ / _|
  # | .__/\_,_|_|_| |_| |_| \___/_|_|_| \___| .__/_\__|
  # |_|                                     |_|

  def pull_target_dates_from_epic
    # TODO
  end

  def pull_status_from_epic
    # TODO
  end

  def pull_name_from_epic
    value_range = Google::Apis::SheetsV4::ValueRange.new(
      range: row.cell_range_by_column_name(:hyperlinked_name),
      values: [
        ["=HYPERLINK(\"#{epic.app_url}\", \"#{epic.name}\")"]
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

  def pull_story_stats_from_epic
    value_range = Google::Apis::SheetsV4::ValueRange.new(
      range: row.cell_range_by_column_name(:story_completion),
      values: [[epic.story_completion]]
    )

    sheets_v4.update_spreadsheet_value(
      spreadsheet_id,
      row.cell_range_by_column_name(:story_completion),
      value_range,
      value_input_option: "USER_ENTERED",
      options: {authorization: auth_client}
    )
  end

  #       _ _   _   _                     _
  #  __ _| | | | |_| |_  ___   _ _ ___ __| |_
  # / _` | | | |  _| ' \/ -_) | '_/ -_|_-<  _|
  # \__,_|_|_|  \__|_||_\___| |_| \___/__/\__|
  #

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

  def sheets_v4
    @sheets_v4 ||= Google::Apis::SheetsV4::SheetsService.new
  end

  def auth_client
    @auth_client ||= GoogleCredentials.load!
  end

  def any_mismatch?
    !name_match? or !status_match? or !target_date_match?
  end

  def name_match?
    row.name.downcase == epic.name.downcase
  end

  def status_match?
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
