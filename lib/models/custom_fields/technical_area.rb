class TechnicalArea < CustomField::Value
  include ActiveModel::Model

  def self.field
    @field ||= CustomField.find_field("Technical Area")
  end

  def self.all
    @all ||= field.values.map { |v| new(v) }.filter(&:enabled)
  end

  def self.find_by_id(value_id)
    all.find { |v| v.id == value_id }
  end

  def priority
    @priority ||= config_priorities[canonical_name] || config_priorities[name] || default_priority
  end

  def config_priorities
    Scrb.fetch_config!("technical-area-priorities")
  end

  def default_priority
    99
  end
end
