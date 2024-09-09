class PartnerImpact < CustomField::Value
  include ActiveModel::Model

  def self.field
    @field ||= CustomField.find_field("Partner Impact")
  end

  def self.all
    @all ||= field.values.map { |v| new(v) }.filter(&:enabled)
  end

  def self.find_by_id(value_id)
    all.find { |v| v.id == value_id }
  end

  def self.find_by_value(value_pattern)
    all.find { |v| v.value.match(/#{value_pattern}/i) }
  end
end
