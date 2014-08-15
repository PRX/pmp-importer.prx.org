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
    prx_story_id = options[:prx_story_id]

    self.story = retrieve_story(prx_story_id)
    self.doc   = retrieve_doc(prx_story_id)

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

    return doc
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
    doc.desciption = strip_tags(story['description'])
  end

  def set_tags
    add_tag_to_doc('prx_test', doc) unless Rails.env.production?
    add_tag_to_doc(tag_for_prx_id('Story', story['id']), doc)
  end

  def retrieve_story(prx_story_id)
    prx.get.story.first.where(id: prx_story_id).body
  end

  def retrieve_doc(prx_story_id)
    doc = nil

    # first see if there is a guid already stored for it, and if so, go get it.
    guid = PMPGuidMapping.find_guid(source_name, 'Story', prx_story_id)
    doc = pmp_doc_find_first(guid: guid) if !doc && guid

    # no guid yet? look to see if the prx story id is tagging a doc    
    doc = pmp_doc_find_first(tag: tag_for_prx_id('Story', prx_story_id)) if (!doc && prx_story_id)

    # still can't find it? make a new one
    doc = pmp.doc_of_type('story') unless doc

    doc
  end

  def prx
    HyperResource.new(root: prx_endpoint)
  end

  def prx_endpoint
    options[:prx_endpoint] || 'https://hal.prx.org/api/v1'
  end

  def tag_for_prx_id(type, id)
    "__prx_#{type.downcase}_#{id.to_i}_"
  end

end
