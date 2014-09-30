class PMPGuidMapping < ActiveRecord::Base

  def self.find_guid(name, type, id)
    guid_mapping = PMPGuidMapping.where(source_name: name, source_type: type, source_id: id.to_s).first
    guid_mapping ? guid_mapping.guid : nil
  end

  def self.find_or_create_guid(name, type, id)
    conditions = { source_name: name, source_type: type, source_id: id.to_s }
    # puts "\n\nfind_or_create_guid conditions 1: #{conditions.inspect}"
    guid_mapping = PMPGuidMapping.where(conditions).first

    conditions = conditions.merge(guid: new_guid)
    # puts "\n\nfind_or_create_guid conditions 2: #{conditions.inspect}"
    guid_mapping = PMPGuidMapping.create!(conditions) unless guid_mapping
    guid_mapping.guid
  end

  def self.new_guid
    SecureRandom.uuid
  end

end
