module Scrb
  class StorySearch
    include ActiveModel::Model
    include Scrb::Searchable

    def search_path
      "/search/stories"
    end

    def item_class
      Scrb::Story
    end

    alias_method :stories, :items
  end
end
