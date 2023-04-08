require "csv"
require "awesome_print"
require "hashie"

module Scrb
  def self.shortcut
    ShortcutRuby::Shortcut.new(ENV.fetch("SHORTCUT_API_TOKEN"))
  end

  def self.current_iteration
    shortcut.iterations.list[:content].map { |h| Iteration.new(h) }.select(&:current?)
  end

  def self.priority_custom_field
    @priority_custom_field ||= CustomField.all.find { |cf| cf.name.match(/priority/i) }
  end

  def self.ready_state_name
    @ready_for_name ||= YAML.load_file("config.yml")["ready-state-name"] || "Ready"
  end

  def self.ready_state
    @ready_state ||= ::ScrbClient.get("/workflows").flat_map { |w| w["states"] }.find { |s| s["name"].match(/#{ready_state_name}/i) }
  end
end
