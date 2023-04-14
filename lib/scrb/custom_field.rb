module Scrb
  class CustomField
    include ActiveModel::Model
    attr_accessor :id, :name, :description, :entity_type, :fixed_position, :updated_at, :field_type,
      :position, :canonical_name, :enabled, :created_at, :values, :story_types

    def self.all
      ScrbClient.get("/custom-fields").map { |r| CustomField.new(r) }
    end

    def self.enabled
      all.filter(&:enabled)
    end

    def self.find_field(name_pattern)
      all.find { |f| f.name.match(/#{name_pattern}/i) }
    end

    class Value
      include ActiveModel::Model
      attr_accessor :id, :value, :position, :color_key, :enabled, :entity_type
      alias_method :name, :value

      def canonical_name
        value.downcase.dasherize
      end
    end

    def enabled_values
      @enabled_values ||= values.map { |v| Value.new(v) }.filter(&:enabled)
    end

    def find_value_by_id(value_id)
      enabled_values.find { |v| v.id == value_id }
    end

    def find_value_by_name(value_pattern)
      enabled_values.find { |v| v.value.match(/#{value_pattern}/i) }
    end
  end
end
