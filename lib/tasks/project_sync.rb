require "cgi"

# Sync Project -> Technical Area
class ProjectSync
  include ActiveModel::Model

  attr_accessor :project_name, :target_field_value_name

  def run
    if target_field_value.nil?
      puts "#{target_field.name} '#{target_field_value_name}' not found"
      return
    end

    story_search.each_page do |page|
      puts "#{page[:items].length} updates, field_name: '#{target_field.name}', field_value: '#{target_field_value.value}'"

      unless dry_run?
        update = put_stories_bulk_update(page[:items])

        # print the url of one of the stories updated
        puts update.first["app_url"]
      end
    end
  end

  def story_search
    @stories ||= StorySearch.new(query: query)
  end

  def put_stories_bulk_update(stories)
    ScrbClient.put("/stories/bulk", body: {
      story_ids: stories.map(&:id),
      custom_fields_add: [
        {
          field_id: target_field.id,
          value_id: target_field_value.id
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
    @query ||= "project:'#{project_name}' !#{target_field.canonical_name}:'#{target_field_value_name}'"
  end

  def target_field_value
    # querying works better with dasherized values, but we need the spaced version to find the correct field value
    @target_field_value ||= target_field.find_value_by_name(target_field_value_name.tr("-", " "))
  end

  def target_field
    @target_field ||= TechnicalArea.field
  end
end
