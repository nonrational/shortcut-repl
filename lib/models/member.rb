class Member
  include ActiveModel::Model
  attr_accessor :created_at, :created_without_invite, :disabled, :entity_type, :global_id, :group_ids, :id, :profile, :role, :state, :updated_at

  class << self
    def find(uuid)
      new(ScrbClient.get("/members/#{uuid}"))
    end
  end

  def first_name
    (profile ? profile["name"] : "").split(" ").first
  end
end
