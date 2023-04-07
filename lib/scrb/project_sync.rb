require "cgi"
require "yaml"

module Scrb
  class ProjectSync
    include ActiveModel::Model

    attr_accessor :project_name, :product_area_name, :stories, :has_more_stories, :next_token

    def run
      return false unless
      loop do
        self.stories = fetch_next_page

        if stories.any?

          puts "#{stories.length} updates, field_name: '#{product_area_field.name}', field_value: '#{product_area_field_value.value}'"

          unless dry_run?
            results = put_stories_bulk_update
            puts results.first["app_url"]
          end
        end

        break unless has_more_stories
      end
    end

    def put_stories_bulk_update
      ScrbClient.put("/stories/bulk", body: {
        story_ids: stories.map { |e| e["id"] },
        custom_fields_add: [
          {
            field_id: product_area_field.id,
            value_id: product_area_field_value.id
          }
        ]
      }.to_json).tap { |res| binding.pry unless res.code == 200 }
    end

    def dry_run?
      ENV["DRY_RUN"].present?
    end

    def fetch_next_page
      search_attrs = {detail: :slim, query: query, page_size: 25}
      search_attrs[:next] = next_token if next_token

      first_page = search_stories(search_attrs)

      self.has_more_stories = first_page[:content]["next"].present?
      self.next_token = CGI.parse(URI.parse(first_page[:content]["next"]).query)["next"].first if has_more_stories

      first_page[:content]["data"] || []
    end

    def query
      @query ||= "project:'#{project_name}' !product-area:'#{product_area_name}'"
    end

    def product_area_field_value
      # querying works better with dasherized values, but we need the spaced version to find the correct field value
      @product_area_field_value ||= product_area_field.find_value(product_area_name.tr("-", " "))
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
      @project_product_areas ||= YAML.load_file("config.yml")["project-product-areas"]
    end
  end
end
