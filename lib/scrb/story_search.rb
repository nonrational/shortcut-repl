module Scrb
  class StorySearch
    include ActiveModel::Model
    include Scrb::Searchable

    def search_path
      "/search/stories"
    end

    alias_method :stories, :items
  end
end
