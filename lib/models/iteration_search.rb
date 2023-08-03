class IterationSearch
  include ActiveModel::Model
  include Searchable

  def search_path
    "/search/iterations"
  end

  def item_class
    Iteration
  end

  alias_method :iterations, :items
end
