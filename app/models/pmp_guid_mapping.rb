class PMPGuidMapping < ActiveRecord::Base

  def self.find_guid(name, type, id)
    guid_mapping = PMPGuidMapping.where(source_name: name, source_type: type, source_id: id).first
    guid_mapping ? guid_mapping.guid : nil
  end

  def self.find_or_create_guid(name, type, id)
    conditions = { source_name: name, source_type: type, source_id: id }
    guid_mapping = PMPGuidMapping.where(conditions).first
    guid_mapping = PMPGuidMapping.create!(conditions.merge(guid: new_guid)) unless guid_mapping
    guid_mapping.guid
  end

  def self.new_guid
    SecureRandom.uuid
  end

end
