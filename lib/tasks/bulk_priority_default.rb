require "yaml"

class BulkPriorityDefault
  def run
    StorySearch.new(query: "!priority: !").each_page do |page|
      ap body_for_page(page)
      ScrbClient.put("/stories/bulk", body: body_for_page(page)).tap do |res|
        binding.pry unless res.success?
      end
    end
  end

  def body_for_page(page)
    {
      story_ids: page[:stories].map(&:id),
      custom_fields_add: [
        {
          field_id: priority_field.id,
          value_id: priority_field_value.id
        }
      ]
    }.to_json
  end

  def priority_field
    @priority_field ||= CustomField.find_field("priority")
  end

  def priority_field_value
    @priority_field_value ||= Priority.default
  end
end
