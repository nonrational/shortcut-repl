# An initiative represents a line-item in a planning spreadsheet and a corresponding shortcut epic.
class SheetInitiative
  include ActiveModel::Model
  attr_accessor :row_data, :row_index, :spreadsheet_id, :spreadsheet_range, :sheet_name

  # delegate the name function to row
  delegate :epic_id, :name, to: :row

  def epic?
    epic.present?
  end

  def story?
    story.present?
  end

  def update_sheet
    if epic?
      row.batch_update_values({
        shortcut_id: shortcut_id,
        hyperlinked_name: hyperlinked_epic_name,
        story_completion: stats_summary,
        participants: epic.participant_members.map(&:first_name).join(", "),
        status: sheet_status
      })
    elsif story?
      row.batch_update_values({
        shortcut_id: shortcut_id,
        hyperlinked_name: hyperlinked_story_name,
        story_completion: "-",
        participants: story.owner_members.map(&:first_name).join(", ")
      })
    end
  end

  def update_epic
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
    owner = Member.fuzzy_find_by_name(row.owner_name) unless row.owner_name == "None"

    # TODO: add quarterly labels?

    attrs = {}

    attrs[:planned_start_date] = row.start_date.iso8601 if row.start_date.present?
    attrs[:deadline] = row.target_date.iso8601 if row.target_date.present?
    attrs[:group_id] = product_group_id if product_group_id.present? && epic.group_id != product_group_id

    if owner.present? && owner.id != epic.owner_ids.first
      attrs[:owner_ids] = [owner.id]
    end

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

  def sheet_status
    return "✔️ Done" if epic.workflow_state.name == "Done"

    epic.workflow_state.name
  end

  def hyperlinked_epic_name
    "=HYPERLINK(\"#{epic_uri_with_group_by}\", \"#{safe_epic_name}\")"
  end

  def hyperlinked_story_name
    "=HYPERLINK(\"#{story.app_url}\", \"#{safe_story_name}\")"
  end

  def shortcut_id
    "epic-#{epic.id}" if epic.present?
    "story-#{story.id}" if story.present?

    "N/A"
  end

  def epic_uri_with_group_by
    epic_uri = URI.parse(epic.app_url)

    query_params = URI.decode_www_form(epic_uri.query || "")
    query_params << ["group_by", "workflow_state_id"]

    epic_uri.query = URI.encode_www_form(query_params)
    epic_uri
  end

  def safe_epic_name
    # translate double quotes to single quotes to avoid breaking the google sheet formula
    epic.name.tr('"', "'")
  end

  def safe_story_name
    # translate double quotes to single quotes to avoid breaking the google sheet formula
    story.name.tr('"', "'")
  end

  def stats_summary
    total = epic.stats["num_stories_total"]
    in_progress = epic.stats["num_stories_started"]
    done = epic.stats["num_stories_done"]

    "#{total} / #{in_progress} / #{done} (#{epic.percent_complete})"
  end

  #       _ _   _   _                     _
  #  __ _| | | | |_| |_  ___   _ _ ___ __| |_
  # / _` | | | |  _| ' \/ -_) | '_/ -_|_-<  _|
  # \__,_|_|_|  \__|_||_\___| |_| \___/__/\__|
  #

  def to_s
    "[#{row_index}] #{row.name}"
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

  def story
    @story ||= Story.find_by_id(row.story_id) if row.story_id.present?
  end

  def drive_v3
    @drive_v3 ||= Google::Apis::DriveV3::DriveService.new.tap { |s| s.authorization = auth_client }
  end

  def auth_client
    @auth_client ||= GoogleCredentials.load!
  end

  def in_sync?
    name_match? && status_match? && start_date_match? && target_date_match?
  end

  def in_sync_details
    {
      name: name_match?,
      status: status_match?,
      start_date: start_date_match?,
      target_date: target_date_match?
    }
  end

  def name_match?
    row.name == safe_epic_name
  end

  def status_match?
    row.status == sheet_status
  end

  def start_date_match?
    row.start_date == epic.planned_starts_at
  end

  def target_date_match?
    row.target_date == epic.planned_ends_at
  end
end
