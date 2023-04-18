require "cgi"

module Scrb
  class ProjectSync
    include ActiveModel::Model

    attr_accessor :project_name, :product_area_name, :stories, :has_more_stories, :next_token

    def run
      StorySearch.new(query: query).each_page do |page|
        puts "#{page[:items].length} updates, field_name: '#{product_area_field.name}', field_value: '#{product_area_field_value.value}'"

        unless dry_run?
          update = put_stories_bulk_update(page[:items])
          puts update.first["app_url"]
        end
      end
    end

    def put_stories_bulk_update(stories)
      ScrbClient.put("/stories/bulk", body: {
        story_ids: stories.map(&:id),
        custom_fields_add: [
          {
            field_id: product_area_field.id,
            value_id: product_area_field_value.id
          }
        ]
      }.to_json).tap do |res|
        binding.pry unless res.success?
      end
    end

    def dry_run?
      ENV["DRY_RUN"].present?
    end

    def query
      @query ||= "project:'#{project_name}' !product-area:'#{product_area_name}'"
    end

    def product_area_field_value
      # querying works better with dasherized values, but we need the spaced version to find the correct field value
      @product_area_field_value ||= product_area_field.find_value_by_name(product_area_name.tr("-", " "))
    end

    def product_area_field
      @product_area_field ||= CustomField.find_field("product area")
    end
  end
end
