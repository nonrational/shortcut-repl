module Scrb
  class EpicSearch
    include ActiveModel::Model
    include Scrb::Searchable

    def search_path
      "/search/epics"
    end

    def item_class
      Scrb::Epic
    end

    alias_method :epics, :items
  end
end
