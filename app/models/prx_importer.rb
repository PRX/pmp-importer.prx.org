# fix: alternate is to the api url, shoud be the page
# fix: author link
# fix: topics

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
    self.doc   = find_or_init_story_doc(story)

    set_account
    set_series
    set_images
    set_audio

    set_attributes
    set_links
    set_tags

    doc.save

    return doc
  end

  def set_account
    account_doc = find_or_create_account_doc(story.account)

    # what rel to use?
    # set the rels based on the account type
    rel =  if pmp_doc_profile(account_doc) == 'property'
      "urn:collectiondoc:collection:property" 
    else
      "urn:collectiondoc:collection:contributor"
    end

    # set the urn based on the type of account
    add_link_to_doc(doc, 'collection', { href: account_doc.href, title: account_doc.name, rels:[rel] })
  end

  def find_or_create_account_doc(account)
    adoc = nil

    # first go looking for it

    adoc = retrieve_doc('Account', account.self.href)

    # if this is a station account, look not just with the tag
    adoc = find_station_organization(account) unless adoc

    # fine, I'll add an account doc since it doesn't exist
    adoc = create_account_doc(account) unless adoc

    adoc
  end

  def find_station_organization(account)
    return nil unless account.type == 'StationAccount'

    station = nil
  
    # retrieve the station account from the prx api
    # get the call letters to search
    call_letters = account.shortName.match(/[W|K]\w{3}(-[F|A]M)*/).to_s

    # get the station from the call letters
    station = pmp_doc_find_first(profile: 'organization', text: call_letters.to_s) if !call_letters.blank?

    # add a mapping to the station guid for the account url (so we can use that next time)
    PMPGuidMapping.create(source_name: source_name, source_type: 'Account', source_id: prx_url(account.self.href), guid: station.guid) if station

    station
  end


  def create_account_doc(account)
    # what profile for an account doc?

    case account.type
    when 'StationAccount'
      adoc           = pmp.doc_of_type('organization')
    when 'GroupAccount'
      adoc           = pmp.doc_of_type('property')
    when 'IndividualAccount'
      adoc           = pmp.doc_of_type('contributor')
      adoc.firstName = account.opener.firstName
      adoc.lastName  = account.opener.lastName
      adoc.bio       = account.description
    else  #  or anything else
      adoc           = pmp.doc_of_type('contributor')
    end

    adoc.guid  = find_or_create_guid('Account', account)
    adoc.title = account.name

    # links
    # fix: this should be page not api
    add_link_to_doc(doc, 'alternate', { href: prx_url(account.self.href) })

    # image
    if account.image
      image_doc = find_or_create_image_doc(account.image)
      add_link_to_doc(doc, 'item', { href: image_doc.href, title: image_doc.title, rels: ['urn:collectiondoc:image'] })
    end

    # tags
    set_standard_tags(doc, account)

    # guid
    adoc.save

    adoc
  end


  def set_series
    retrieve_doc('Series', series.self.href) || create_series_doc(series)
  end

  def create_series_doc(series)
    sdoc = pmp.doc_of_type('series')
    sdoc.guid  = find_or_create_guid('Series', series)
    sdoc.title = series.name

    # links
    # fix: this should be page not api url
    sdoc.links['alternate'] = PMP::Link.new(href: prx_url(series.self.href))

    # image
    if series.image
      image_doc = find_or_create_image_doc(series.image)
      add_link_to_doc(sdoc, 'item', { href: image_doc.href, title: image_doc.title, rels: ['urn:collectiondoc:image'] })
    end

    # tags
    set_standard_tags(sdoc, series)

    # guid
    sdoc.save

    sdoc
  end


  def set_images
    return unless story.image

    image_doc = find_or_create_image_doc(story.image)
    add_link_to_doc(doc, 'item', { href: image_doc.href, title: image_doc.title, rels: ['urn:collectiondoc:image'] })
  end

  def find_or_create_image_doc(image)
    retrieve_doc('Image', image.self.href) || create_image_doc(image)
  end

  # retreive the image and detect features of it (height, width) ?
  def create_image_doc(image)
    idoc = nil

    idoc = pmp.doc_of_type('image')
    idoc.guid = find_or_create_guid('Image', image)

    idoc.title  = image.attributes[:caption] || image.attributes[:filename]
    idoc.byline = image.attributes[:credit]

    add_link_to_doc(idoc, 'enclosure', { href: prx_url(image.enclosure.href), type: image.enclosure.type, meta: {crop: 'medium'} })

    set_standard_tags(idoc, image)

    idoc
  end


  def set_audio
    return unless story.audio && story.audio.size > 0

    Array(story.audio).each do |audio|
      audio_doc = find_or_create_audio_doc(audio, story.id)
      add_link_to_doc(doc, 'item', { href: audio_doc.href, title: audio_doc.title, rels: ['urn:collectiondoc:audio'] })
    end
  end

  def find_or_create_audio_doc(audio, prx_piece_id)
    retrieve_doc('Audio', audio.self.href) || create_audio_doc(audio, prx_piece_id)
  end

  def create_audio_doc(audio, prx_piece_id)
    adoc = nil

    adoc = pmp.doc_of_type('audio')
    adoc.guid  = find_or_create_guid('Audio', audio)
    adoc.title = audio.attributes[:label] || audio.attributes[:filename]

    enclosure_url = count_audio_url(audio.enclosure.href, audio.id, prx_piece_id, adoc.guid)

    add_link_to_doc(adoc, 'enclosure', { href: enclosure_url, type: audio.enclosure.type, meta: {duration: audio.duration, size: audio.size} })

    set_standard_tags(adoc, audio)

    adoc
  end


  def set_attributes
    doc.hreflang       = "en"
    doc.title          = story.title
    doc.desciption     = strip_tags(story.description)
    doc.contentencoded = story.description
    doc.published      = story.published # Time ?
    doc.byline         = "" # I don't know, based on the account?
  end


  def set_links
    # this is wrong, need the page not the api url
    # doc.links['alternate'] = PMP::Link.new(href: prx_url(story.links[:self].href)) 

    # doc.links['author']    = PMP::Link.new(href: 'http://...')
  end

  def set_tags
    set_standard_tags(doc, story)
  end

  def set_standard_tags(tag_doc, prx_obj)
    add_tag_to_doc(tag_doc, 'prx_test') unless Rails.env.production?
    add_tag_to_doc(tag_doc, prx_tag(prx_obj.self.href))
  end


  def retrieve_story(prx_story_id)
    prx.get.story.first.where(id: prx_story_id)
  end

  def find_or_init_story_doc(story)
    sdoc = retrieve_doc('Story', story.self.href)

    if !sdoc
      sdoc = pmp.doc_of_type('story')
      sdoc.guid = find_or_create_guid('Story', story)
    end

    sdoc
  end

  def retrieve_doc(type, url)
    doc = nil

    url = prx_url(url)

    guid = PMPGuidMapping.find_guid(source_name, type, url)
    doc = pmp_doc_find_first(guid: guid) if guid

    # no guid yet? look to see if the prx id is tagging a doc
    if !doc
      doc = pmp_doc_find_first(tag: prx_tag(url))
      PMPGuidMapping.create(source_name: source_name, source_type: type, source_id: url, guid: doc.guid) if doc
    end

    doc
  end

  # https://count.prx.org/redirect?location=http://www.prx.org&action=request&action_value=%7Bsrc%3A+pmp%7D&referrer=https://api.pmp.io
  def count_audio_url(prx_audio_url, prx_audio_file_id, prx_piece_id, audio_doc_guid)
    params = {
      location:     prx_url(prx_audio_url),
      action:       'request',
      referrer:     pmp_url('docs', audio_doc_guid),
      action_value: { audioFileId: prx_audio_file_id, pieceId: prx_piece_id }.to_json
    }.merge(options)

    uri = URI::HTTPS.build(host: 'count.prx.org', path: '/redirect', query: params.to_query)
    uri.to_s
  end

  def prx
    HyperResource.new(root: prx_endpoint)
  end

  def prx_endpoint
    options[:prx_endpoint] || 'https://hal.prx.org/api/v1'
  end

  def prx_tag(url)
    vals = url.to_s.split('/')
    id   = vals.pop.to_i
    type = vals.pop.to_s

    "_prx_#{type}__#{id}_"
  end

  def prx_url(*path)
    url = path.collect(&:to_s).join('/')

    return url if url.start_with?('http')

    URI.join(prx_endpoint, url).to_s
  end

  def find_or_create_guid(type, prx_obj)
    PMPGuidMapping.find_or_create_guid(source_name, type, prx_url(prx_obj.self.href))
  end

end
