class StorySearch
  include ActiveModel::Model
  include Searchable

  def search_path
    "/search/stories"
  end

  def item_class
    Story
  end

  alias_method :stories, :items
end
