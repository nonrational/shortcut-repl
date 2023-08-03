require "cgi"

module Searchable
  attr_writer :page_size, :detail
  attr_accessor :query

  # private
  attr_accessor :next_token, :has_more_items
  attr_writer :page_count
  attr_reader :path

  def items
    @items ||= []
  end

  def page_count
    @page_count ||= 0
  end

  def page_size
    25
  end

  def detail
    :slim
  end

  def each_page
    while (has_more_items || page_count.zero?) && (curr = fetch_next_page)
      break if curr.empty?
      yield({page: (page_count - 1), items: curr})
    end
  end

  def fetch_all
    while (has_more_items || page_count.zero?) && fetch_next_page.any?
      print "."
    end
    puts

    items
  end

  def fetch_next_page
    raise "No search path defined" if search_path.nil?

    result = ScrbClient.get(search_path, body: search_attrs.to_json)

    if result.client_error?
      puts "Error: #{result["message"]}"
      return []
    end

    self.page_count += 1
    self.has_more_items = result["next"].present?
    self.next_token = CGI.parse(URI.parse(result["next"]).query)["next"].first if has_more_items

    curr_items = result["data"].map { |s| item_class.new(s) }

    items.push(*curr_items)

    curr_items
  end

  def search_attrs
    base_attrs = {detail: detail, query: query, page_size: page_size}
    next_token ? base_attrs.merge(next: next_token) : base_attrs
  end
end
