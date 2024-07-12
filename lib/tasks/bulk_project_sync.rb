require "yaml"

class BulkProjectSync
  def run
    project_product_areas.each do |project, value_name|
      ProjectSync.new(project_name: project, target_field_value_name: value_name).run
    end
  end

  def project_product_areas
    @project_product_areas ||= YAML.load_file("config.yml")["project-technical-areas"]
  end
end
