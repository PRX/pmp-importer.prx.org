class PMPGuidMapping < ActiveRecord::Base

  def self.find_guid(name, type, id)
    guid_mapping = PMPGuidMapping.where(source_name: name.to_s, source_type: type.to_s, source_id: id.to_s).first
    guid_mapping.try(:guid)
  end

  def self.find_or_create_guid(name, type, id)
    conditions = { source_name: name.to_s, source_type: type.to_s, source_id: id.to_s }
    guid_mapping = PMPGuidMapping.where(conditions).first

    guid_mapping ||= PMPGuidMapping.create!(conditions.merge(guid: PMPGuidMapping.new_guid))

    guid_mapping.guid
  end

  def self.new_guid
    SecureRandom.uuid
  end

end
