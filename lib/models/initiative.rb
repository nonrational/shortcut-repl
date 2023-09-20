# An initiative represents a line-item in a planning spreadsheet and a corresponding shortcut epic.
class Initiative
  attr_reader :row

  def initialize(raw_row)
    @row = SheetRow.new(raw_row)
  end

  def story?
    /story-/.match?(row.raw_shortcut_id)
  end

  def epic?
    /epic-/.match?(row.raw_shortcut_id)
  end

  def epic_id
    @epic_id ||= row.raw_shortcut_id.split("-")[1].to_i if epic?
  end

  def epic
    @epic ||= Scrb.current_epics.find { |e| e.id == epic_id } if epic?
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
      ["epic", epic.id, epic.name, row.target_date, epic.target_date&.to_date&.iso8601].join(",")
    elsif epic?
      ["epic", row.raw_shortcut_id, "ERR!", nil, nil].join(",")
    elsif story?
      ["story", "ERR!", "ERR!", nil, nil].join(",")
    else
      ["ERR!", "ERR!", "ERR!", nil, nil].join(",")
    end
  end
end
