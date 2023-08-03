require "yaml"

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
