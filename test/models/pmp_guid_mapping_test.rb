require 'test_helper'

describe PMPGuidMapping do

  it 'has a table defined' do
    PMPGuidMapping.table_name.must_equal 'pmp_guid_mappings'
  end

  it 'can provide a new guid' do
    PMPGuidMapping.new_guid.wont_be_nil
  end

  it 'returns nil when no guid mapped' do
    PMPGuidMapping.find_guid('test', 'test', 1).must_be_nil
  end

  it 'finds existing guid' do
    guid = SecureRandom.uuid
    PMPGuidMapping.create!(source_name: 'test', source_type:'test', source_id: 2, guid: guid)
    PMPGuidMapping.find_guid('test', 'test', 2).must_equal guid
  end

  it 'finds or creates guid' do
    PMPGuidMapping.find_guid('test', 'test', 3).must_equal nil    
    guid = PMPGuidMapping.find_or_create_guid('test', 'test', 3)
    guid.wont_be_nil
    PMPGuidMapping.find_or_create_guid('test', 'test', 3).must_equal guid
  end

end
