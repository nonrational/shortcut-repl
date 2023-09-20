class SheetRow
  # A	    B	    C	  D	        E	    F	      G       H	    I	      J	    K	  L	            M N O	P	      Q       R	  S
  # index	Name	Doc	Shortcut	Owner	Urgency	Status	Begin	Target	Start	End	Last Mention	P	D	E	Source	Design	Eng	Notes
  def initialize(raw_row)
    @raw_row = raw_row
  end

  def index
    @index ||= value_at(:a).formatted_value&.to_i
  end

  def name
    @name ||= value_at(:b).formatted_value
  end

  def shortcut_link
    @shortcut_link ||= value_at(:b).hyperlink
  end

  def doc_type
    @doc_type ||= value_at(:c).formatted_value
  end

  def doc_url
    @doc_url ||= value_at(:c).hyperlink
  end

  def raw_shortcut_id
    @raw_shortcut_id ||= value_at(:d).formatted_value
  end

  def owner_name
    @owner_name ||= value_at(:e).formatted_value
  end

  def urgency
    @urgency ||= value_at(:f).formatted_value
  end

  def target_date
    @target_date ||= begin
      Date.iso8601(value_at(:k).formatted_value)
    rescue
      nil
    end
  end

  def status
    @status ||= value_at(:g).formatted_value
  end

  def value_at(col_sym)
    column = col_sym.to_s.upcase
    @raw_row.values[column.chars.reduce(0) { |acc, char| acc * 26 + (char.ord - "A".ord) }]
  end
end
