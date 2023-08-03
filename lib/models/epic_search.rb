class EpicSearch
  include ActiveModel::Model
  include Searchable

  def search_path
    "/search/epics"
  end

  def item_class
    Epic
  end

  alias_method :epics, :items
end
