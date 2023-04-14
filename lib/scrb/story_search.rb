require "cgi"

module Scrb
  class StorySearch
    include ActiveModel::Model

    attr_writer :page_size, :detail
    attr_accessor :query

    # private
    attr_accessor :next_token, :has_more_stories
    attr_writer :page_count

    def stories
      @stories ||= []
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
      while (has_more_stories || page_count.zero?) && (curr = fetch_next_page)
        break if curr.empty?
        yield({page: (page_count - 1), stories: curr})
      end
    end

    def fetch_all
      while (has_more_stories || page_count.zero?) && fetch_next_page.any?
        print "."
      end
      puts

      stories
    end

    def fetch_next_page
      result = ScrbClient.get("/search/stories", body: search_attrs.to_json)

      if result.client_error?
        puts "Error: #{result["message"]}"
        return []
      end

      self.page_count += 1
      self.has_more_stories = result["next"].present?
      self.next_token = CGI.parse(URI.parse(result["next"]).query)["next"].first if has_more_stories

      curr_stories = result["data"].map { |s| Story.new(s) }

      stories.push(*curr_stories)

      curr_stories
    end

    def search_attrs
      base_attrs = {detail: detail, query: query, page_size: page_size}
      next_token ? base_attrs.merge(next: next_token) : base_attrs
    end
  end
end
