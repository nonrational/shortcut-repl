class SheetRow
  include ActiveModel::Model
  attr_accessor :row_data, :row_index, :sheet_name

  # TODO: Move this config?
  # A	    B	    C	  D	        E	    F	      G       H	    I	      J	    K	  L	            M N O	P	      Q       R	  S
  # index	Name	Doc	Shortcut	Owner	Urgency	Status	Begin	Target	Start	End	Last Mention	P	D	E	Source	Design	Eng	Notes

  def cell_range_by_column_index(col_alpha)
    [sheet_name, "!", col_alpha.to_s.upcase, row_index].join
  end

  def cell_range_by_column_name(col_name)
    cell_range_by_column_index(column_map[col_name.to_sym])
  end

  def number
    fetch(:number).formatted_value&.to_i
  end

  def name
    fetch(:hyperlinked_name).formatted_value
  end

  def name_hyperlink
    fetch(:hyperlinked_name).hyperlink
  end

  def doctype
    etch(:hyperlinked_doctype).formatted_value
  end

  def doctype_hyperlink
    fetch(:hyperlinked_doctype).hyperlink
  end

  def shortcut_id
    fetch(:shortcut_id).formatted_value
  end

  def owner_name
    fetch(:owner_name).formatted_value
  end

  def urgency
    fetch(:urgency).formatted_value
  end

  def target_date
    @target_date ||= begin
      Date.iso8601(fetch(:target_date).formatted_value)
    rescue
      nil
    end
  end

  def status
    fetch(:status).formatted_value
  end

  private

  def fetch(col_name)
    col_sym = column_map[col_name.to_sym]
    raise "#{column} not found" if col_sym.nil?
    value_at(col_sym)
  end

  def value_at(col_sym)
    column = col_sym.to_s.upcase
    cell_value = row_data.values[column.chars.reduce(0) { |acc, char| acc * 26 + (char.ord - "A".ord) }]

    cell_value || EmptyValue.new
  end

  class EmptyValue
    def formatted_value
      nil
    end

    def hyperlink
      nil
    end
  end

  def column_map
    # todo: build this with a zip.
    @column_map ||= {
      number: :A,
      hyperlinked_name: :B,
      hyperlinked_doctype: :C,
      shortcut_id: :D,
      owner_name: :E,
      urgency: :F,
      status: :G,
      start_iteration: :H,
      target_iteration: :I,
      start_date: :J,
      target_date: :K,
      last_mention: :L,
      notes: :S
    }
  end
end