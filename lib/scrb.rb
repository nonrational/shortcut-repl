require "csv"
require "awesome_print"
require "active_support/all"
require "hashie"
require "base64"

module Scrb
  class << self
    def shortcut
      ShortcutRuby::Shortcut.new(ENV.fetch("SHORTCUT_API_TOKEN"))
    end

    def current_iteration
      @current_iteration ||= Scrb::Iteration.find_current
    end

    def iterations
      @iterations ||= Scrb::Iteration.all
    end

    def product_area_custom_field
      @product_area_custom_field ||= CustomField.all.find { |cf| cf.name.match(/product area/i) }
    end

    def priority_custom_field
      @priority_custom_field ||= CustomField.all.find { |cf| cf.name.match(/priority/i) }
    end

    def default_priority_custom_field
      @default_priority_custom_field ||= priority_custom_field.find_value_by_name(config["default-priority-value"])
    end

    def ready_state_name
      @ready_for_name ||= config["ready-state-name"] || "Ready"
    end

    def workflow_name
      @workflow_name ||= config["workflow-name"] || "Product"
    end

    def config
      @config ||= ENV["SCRB_CONFIG"].present? ? YAML.load(ENV["SCRB_CONFIG"]) : YAML.load_file("config.yml")
    end

    def ready_state
      @ready_state ||= ::ScrbClient.get("/workflows").find { |w| w["name"] == config["workflow-name"] }["states"].find { |s| s["name"].match(/#{ready_state_name}/i) }
    end
  end
end
