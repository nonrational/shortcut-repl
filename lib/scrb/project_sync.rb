require "cgi"

module Scrb
  class ProjectSync
    include ActiveModel::Model

    attr_accessor :project_name, :product_area_name, :stories, :has_more_stories, :next_token

    def run
      loop do
        self.stories = fetch_next_page

        if stories.any?
          story_ids = stories.map { |e| e["id"] }
          puts "#{story_ids.length} updates, field: #{product_area_field.name}, value: #{product_area_field_value.value}"
          data = {story_ids: story_ids, custom_fields_add: [{field_id: product_area_field.id, value_id: product_area_field_value.id}]}
          result = ScrbClient.put("/stories/bulk", body: data.to_json)
          binding.pry unless result.code == 200
          puts result.first["app_url"]
        end

        break unless has_more_stories
      end
    end

    def fetch_next_page
      search_attrs = { detail: :slim, query: query, page_size: 25 }
      search_attrs[:next] = next_token if next_token

      first_page = search_stories(search_attrs)

      self.has_more_stories = first_page[:content]["next"].present?
      self.next_token = CGI.parse(URI.parse(first_page[:content]["next"]).query)["next"].first if has_more_stories

      first_page[:content]["data"] || []
    end

    def query
      @query ||= "project:#{project_name} !product-area:#{product_area_name} !is:archived"
    end

    def product_area_field_value
      @product_area_field_value ||= product_area_field.find_value(product_area_name)
    end

    def product_area_field
      @product_area_field ||= CustomField.find_field("product area")
    end

    def search_stories(attrs)
      puts "fetching #{attrs}"
      ShortcutRuby::Shortcut.new(ENV.fetch("SHORTCUT_API_TOKEN")).search_stories(attrs)
    end
  end

  class BulkProjectSync
    def run
      project_product_areas.each do |project, product_area|
        ProjectSync.new(project_name: project, product_area_name: product_area).run
      end
    end

    def project_product_areas
      @project_product_areas ||= {
        process: :process,
        backend: :backend,
        design: :design,
        frontend: :frontend,
        infrastructure: :infrastructure,
        "pid token contract": :"PID Token",
        scoping: :scoping,
        website: :website
      }
    end
  end
end
