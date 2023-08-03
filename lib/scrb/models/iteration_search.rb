module Scrb
  class IterationSearch
    include ActiveModel::Model
    include Scrb::Searchable

    def search_path
      "/search/iterations"
    end

    def item_class
      Scrb::Iteration
    end

    alias_method :iterations, :items
  end
end
