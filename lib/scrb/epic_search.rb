module Scrb
  class StorySearch
    include ActiveModel::Model
    include Scrb::Searchable

    def search_path
      "/search/epics"
    end

    alias_method :epics, :items
  end
end
