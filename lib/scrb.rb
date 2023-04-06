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
end
