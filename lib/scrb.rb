require 'csv'
require 'awesome_print'

module Scrb
  def self.shortcut
    ShortcutRuby::Shortcut.new(ENV['SHORTCUT_API_TOKEN'])
  end

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
      ShortcutRuby::Shortcut.new(ENV['SHORTCUT_API_TOKEN'])
    end

    def filepath
      @filepath ||= "stories.csv"
    end
  end
end
