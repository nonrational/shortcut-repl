module Scrb
  class Priority < CustomField::Value
    include ActiveModel::Model

    def self.all
      @all ||= CustomField.find_field("Priority").values.map { |v| new(v) }.filter(&:enabled)
    end

    def self.find_by_id(value_id)
      all.find { |v| v.id == value_id }
    end

    def self.find_by_value(value_pattern)
      all.find { |v| v.value.match(/#{value_pattern}/i) }
    end

    def self.default
      @default ||= find_by_value(::Scrb.fetch_config!("default-priority-value"))
    end
  end
end
