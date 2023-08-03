class CsvImport
  include ActiveModel::Model

  attr_writer :filepath

  def save!
    CSV.foreach(filepath, headers: true) do |row|
      ap row
      result = api.stories.create(row.to_h)
      binding.pry unless result[:code] == "201"
    end
  end

  def api
    Scrb.shortcut
  end

  def filepath
    @filepath ||= "stories.csv"
  end
end
