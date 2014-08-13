require 'hyperresource'
require 'pmp'

class PRXImporter < ApplicationImporter

  attr_accessor :doc, :story

  def source_name
    'prx'
  end

  def import(options={})
    super

    # expect a prx story id as an option
    self.story = retrieve_story(options[:prx_story_id])

    self.doc = new_story_doc 

    set_identity
    set_attributes
    set_account
    set_series
    set_audio
    set_images
    set_tags

    # if story save fails, delete audio and images (rollback)
    # can probably keep guid mappings?

    doc.save
  end

  def new_story_doc
    d = pmp.doc_of_type('story')
    d.tags = ['prx_test'] unless Rails.env.production?
    d
  end

  def set_identity
    return if !doc.guid.blank?
    doc.guid = PMPGuidMapping.find_or_create_guid(source_name, 'Story', story['id'])
  end

  def set_account
    # a collection for now

    # check to see if the account is in the mapping table

    # if not, query the pmp for it

    # if not, then make a new one with new guid mapping and save
  end

  def find_or_create_account
    # assume it will have a tag for the id?
  end

  def set_series
  end

  def set_audio
  end

  def set_images
  end

  def set_attributes
    doc.title = story['title']
  end

  def set_tags
  end

  def retrieve_story(prx_story_id)
    story = prx.get.story.first.where(id: prx_story_id).body
    raise "PRX Story id does not match: '#{prx_story_id}' != '#{story['id']}'" if (prx_story_id.to_s != story['id'].to_s)
    story
  end

  def prx
    HyperResource.new(root: prx_endpoint)
  end

  def prx_endpoint
    options[:prx_endpoint] || 'https://hal.prx.org/api/v1'
  end

end
