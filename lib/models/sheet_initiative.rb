# An initiative represents a line-item in a planning spreadsheet and a corresponding shortcut epic.
class SheetInitiative
  include ActiveModel::Model
  attr_accessor :row_data, :row_index, :spreadsheet_id, :spreadsheet_range, :sheet_name

  # delegate the name function to row
  delegate :epic_id, :name, to: :row

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
    return false unless row.doctype_hyperlink.present?

    # get the document id from the row and move it to the correct folder based on its type.
    doctype_key = row.doctype&.downcase
    target_folder_id = Scrb.fetch_config!("planning-document-folders-by-doctype")[doctype_key]

    # break and return early if we don't have a target folder id
    if target_folder_id.nil?
      # binding.pry
      return false
    end

    file = drive_v3.get_file(row.document_id, fields: "parents", supports_all_drives: true)
    previous_parents = file.parents.join(",")

    return :ok if previous_parents == target_folder_id

    puts "Moving #{row.document_id} from #{previous_parents} to #{target_folder_id}..."

    drive_v3.update_file(
      row.document_id,
      add_parents: target_folder_id,
      remove_parents: previous_parents,
      fields: "id,parents",
      supports_all_drives: true
    )
  end

  #               _      _                  _
  #  _ __ _  _ __| |_   | |_ ___   ___ _ __(_)__
  # | '_ \ || (_-< ' \  |  _/ _ \ / -_) '_ \ / _|
  # | .__/\_,_/__/_||_|  \__\___/ \___| .__/_\__|
  # |_|                               |_|
  def push_dates_and_status_to_epic
    epic_workflow_state = EpicWorkflow.fetch.find_state_by_name(row.status)
    product_group_id = Group.find_by_name("Product").id

    attrs = {
      # TODO: add quarterly labels
      planned_start_date: row.start_date&.to_date&.iso8601,
      deadline: row.target_date&.to_date&.iso8601
    }

    if epic_workflow_state.present? && epic_workflow_state.id != epic.epic_state_id
      attrs[:epic_state_id] = epic_workflow_state.id
    end

    if epic.group_id != product_group_id
      attrs[:group_id] = product_group_id
    end

    ap(attrs)
    binding.pry
    result = epic.update(attrs)
    binding.pry

    @epic = Epic.new(result)
  end

  #            _ _    __                          _
  #  _ __ _  _| | |  / _|_ _ ___ _ __    ___ _ __(_)__
  # | '_ \ || | | | |  _| '_/ _ \ '  \  / -_) '_ \ / _|
  # | .__/\_,_|_|_| |_| |_| \___/_|_|_| \___| .__/_\__|
  # |_|                                     |_|

  def pull_dates_and_status_from_epic
    # TODO
  end

  def pull_target_dates_from_epic
    # TODO
  end

  def pull_status_from_epic
    # TODO: Spacing here might matter. Not sure if this is safe.
    row.update_cell_value(:status, epic.workflow_state.name)
  end

  def pull_name_from_epic
    raw_app_url = epic.app_url
    # append `?group_by=workflow_state_id` to all hyperlinked epics
    uri = URI.parse(raw_app_url)
    query_params = URI.decode_www_form(uri.query || "")
    query_params << ["group_by", "workflow_state_id"]
    uri.query = URI.encode_www_form(query_params)

    # translate double quotes to single quotes to avoid breaking the google sheet formula
    safe_epic_name = epic.name.tr('"', "'")

    row.update_cell_value(:hyperlinked_name, "=HYPERLINK(\"#{uri}\", \"#{safe_epic_name}\")")
  end

  def pull_story_stats_from_epic
    total = epic.stats["num_stories_total"]
    in_progress = epic.stats["num_stories_started"]
    done = epic.stats["num_stories_done"]

    stats_summary = "#{total} / #{in_progress} / #{done} (#{epic.percent_complete})"

    row.update_cell_value(:story_completion, stats_summary)
  end

  def pull_participants_from_epic
    row.update_cell_value(:participants, epic.participant_members.map(&:first_name).join(", "))
  end

  #       _ _   _   _                     _
  #  __ _| | | | |_| |_  ___   _ _ ___ __| |_
  # / _` | | | |  _| ' \/ -_) | '_/ -_|_-<  _|
  # \__,_|_|_|  \__|_||_\___| |_| \___/__/\__|
  #

  def to_s
    puts "[#{row_index}] #{row.name}"
  end

  def row
    @row ||= SheetRow.new(
      spreadsheet_id: spreadsheet_id,
      row_data: row_data,
      row_index: row_index,
      sheet_name: sheet_name
    )
  end

  # does the sheet row list a valid shortcut epic?
  def epic
    @epic ||= Scrb.recent_epics.find { |e| e.id == epic_id } if epic_id.present?
  end

  def drive_v3
    @drive_v3 ||= Google::Apis::DriveV3::DriveService.new.tap { |s| s.authorization = auth_client }
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
end
