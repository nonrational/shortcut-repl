require "csv"
require "awesome_print"
require "active_support/all"
require "hashie"

module Scrb
  def self.shortcut
    ShortcutRuby::Shortcut.new(ENV.fetch("SHORTCUT_API_TOKEN"))
  end

  def self.current_iteration
    shortcut.iterations.list[:content].map { |h| Iteration.new(h) }.select(&:current?)
  end

  def self.product_area_custom_field
    @product_area_custom_field ||= CustomField.all.find { |cf| cf.name.match(/product area/i) }
  end

  def self.priority_custom_field
    @priority_custom_field ||= CustomField.all.find { |cf| cf.name.match(/priority/i) }
  end

  def self.default_priority_custom_field
    @default_priority_custom_field ||= priority_custom_field.find_value_by_name(config["default-priority-value"])
  end

  def self.ready_state_name
    @ready_for_name ||= config["ready-state-name"] || "Ready"
  end

  def self.workflow_name
    @workflow_name ||= config["workflow-name"] || "Product"
  end

  def self.config
    @config ||= YAML.load_file("config.yml")
  end

  def self.ready_state
    @ready_state ||= ::ScrbClient.get("/workflows").find { |w| w["name"] == config["workflow-name"] }["states"].find { |s| s["name"].match(/#{ready_state_name}/i) }
  end
end
