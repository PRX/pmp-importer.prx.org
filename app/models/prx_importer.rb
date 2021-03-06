# fix: analytics image url added to content encoded
# fix: author link
# fix: topics

require 'hyperresource'
require 'pmp'

class PRXImporter < ApplicationImporter

  attr_accessor :doc, :story, :series

  def source_name
    'prx'
  end

  def whitelisted?(account_id)
    PRXAccountWhitelist.allow?(account_id)
  end

  def import(options={})
    super

    # expect a prx story id as an option
    if options[:prx_story_id]
      import_story(options[:prx_story_id])
    elsif options[:prx_series_id]
      import_series(options[:prx_series_id], options[:async])
    end
  end

  def import_series(prx_series_id, async = false)
    self.series = retrieve_series(prx_series_id)

    return unless whitelisted?(series.account.id)

    stories = series.stories.get
    while (stories) do
      stories.each do |s|
        if async
          PRXStoryModifiedWorker.perform_later(s.id)
        else
          PRXImporter.new.import_story(s.id)
        end
      end
      stories = stories.links[:next] ? stories.next.get : nil
    end
  end

  def retrieve_series(prx_series_id)
    prx.get.series.first.where(id: prx_series_id).get
  end

  def import_story(prx_story_id)
    logger.debug("import_story: #{prx_story_id}")

    self.story = retrieve_story(prx_story_id)

    return unless whitelisted?(story.account.id)

    self.doc   = find_or_init_story_doc(story)

    # reset the links in the doc
    doc.links = {}

    set_profile
    set_account
    set_series
    set_images
    set_audio

    set_attributes
    set_links
    set_tags

    doc.save
    logger.debug("import_story: #{prx_story_id} saved as: #{doc.guid}")

    return doc
  end

  def set_profile
    ## if we want to set based on membership in a series
    # profile = if story.links[:series]
    #             'story'
    #           else
    #             'episode'
    #           end
    profile = 'story'

    add_link_to_doc(doc, 'profile', { href: pmp.profile_href_for_type(profile), type: 'application/vnd.collection.doc+json' })
  end

  def set_account
    logger.debug("set_account")
    account_doc = find_or_create_account_doc(story.account)

    # what rel to use?
    # set the rels based on the account type
    rel = if pmp_doc_profile(account_doc) == 'property'
      "urn:collectiondoc:collection:property"
    else
      "urn:collectiondoc:collection:contributor"
    end

    # set the urn based on the type of account
    add_link_to_doc(doc, 'collection', { href: account_doc.href, title: account_doc.title, rels:[rel] })
  end

  def find_or_create_account_doc(account)
    retrieve_doc('Account', account.self.href) ||
    find_station_organization(account) ||
    create_account_doc(account)
  end

  def find_station_organization(account)
    return nil unless account.type == 'StationAccount'

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
    logger.debug("create_account_doc: #{account.id}")
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
    adoc.title = account.attributes[:name]

    # links
    add_link_to_doc(adoc, 'alternate', { href: prx_web_link("#{account.type.tableize}/#{account.id}") })

    # image
    if account.links[:image]
      image_doc = find_or_create_image_doc(account.image)
      add_link_to_doc(adoc, 'item', { href: image_doc.href, title: image_doc.title, rels: ['urn:collectiondoc:image'] })
    end

    # tags
    set_standard_tags(adoc, account.self.href)

    # guid
    adoc.save

    adoc
  end

  def set_series
    logger.debug("set_series")

    return unless story.links[:series]

    series_doc = retrieve_doc('Series', story.series.self.href) || create_series_doc(story.series)

    add_link_to_doc(doc, 'collection', { href: series_doc.href, title: series_doc.title, rels:["urn:collectiondoc:collection:series"] })
  end

  def create_series_doc(series)
    sdoc = pmp.doc_of_type('series')
    sdoc.guid  = find_or_create_guid('Series', series)
    sdoc.title = series.title
    sdoc.description = series.description

    # links
    # fix: this should be page not api url
    add_link_to_doc(sdoc, 'alternate', { href: prx_web_link("series/#{series.id}") })

    # image
    if series.links[:image]
      image_doc = find_or_create_image_doc(series.image)
      add_link_to_doc(sdoc, 'item', { href: image_doc.href, title: image_doc.title, rels: ['urn:collectiondoc:image'] })
    end

    # tags
    set_standard_tags(sdoc, series.self.href)

    # save it
    sdoc.save

    sdoc
  end


  def set_images
    logger.debug("set_images")

    return unless story.links[:image]

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
    idoc.guid   = find_or_create_guid('Image', image)
    idoc.title  = image.attributes[:caption] || image.attributes[:filename]
    idoc.byline = image.attributes[:credit] || ""

    href = image.enclosure.href
    type = image.body['_links']['enclosure']['type']
    add_link_to_doc(idoc, 'enclosure', { href: prx_url(href), type: type, meta: {crop: 'medium'} })

    set_standard_tags(idoc, image.self.href)

    idoc.save

    idoc
  end

  def set_audio
    logger.debug("set_audio")

    Array(story.links[:audio]).each do |audio|
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

    href = audio.enclosure.href
    type = audio.body['_links']['enclosure']['type']

    add_link_to_doc(adoc, 'enclosure', { href: prx_url(href), type: type, meta: {duration: audio.duration, size: audio.size} })

    set_standard_tags(adoc, audio.self.href)

    adoc.save

    adoc
  end

  def set_attributes
    logger.debug("set_attributes")

    doc.hreflang       = "en"
    doc.title          = story.attributes[:title]
    doc.teaser         = story.shortDescription

    description = story.description.blank? ? story.shortDescription : story.description
    doc.description    = strip_tags(description)
    doc.contentencoded = description

    doc.byline         = story.account.attributes[:name]

    doc.published      = DateTime.parse(story.publishedAt)
    doc.valid          = {from: doc.published, to: (doc.published + 1000.years)}
  end

  def set_links
    logger.debug("set_links")

    add_link_to_doc(doc, 'alternate', { href: prx_web_link("pieces/#{story.id}") })
    # add_link_to_doc(doc, 'author', { href: prx_web_link("pieces/#{story.id}") })
    # add_link_to_doc(doc, 'copyright', { href: prx_web_link("pieces/#{story.id}") })
  end

  def set_tags
    logger.debug("set_tags")

    # reset tags before adding them
    doc.tags = []
    doc.itags = []

    set_standard_tags(doc, story.self.href)
    Array(story.attributes[:tags]).each{|t| add_tag_to_doc(doc, t) }
  end

  def retrieve_story(prx_story_id)
    prx.get.story.first.where(id: prx_story_id).get
  end

  def find_or_init_story_doc(story)
    sdoc = retrieve_doc('Story', story.self.href)

    if !sdoc
      sdoc = pmp.doc_of_type('story')
      sdoc.guid = find_or_create_guid('Story', story)
    end

    sdoc
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
    HyperResource.new(root: prx_api_endpoint)
  end

  def prx_api_endpoint
    options[:prx_api_endpoint] || 'https://cms.prx.org/api/v1/'
  end

  def prx_web_endpoint
    options[:prx_web_endpoint] || 'https://www.prx.org/'
  end

  def retrieve_doc(type, url)
    super(type, prx_url(url))
  end

  def prx_url(*path)
    url = path.collect(&:to_s).join('/')

    return url if url.start_with?('http')

    URI.join(prx_api_endpoint, url).to_s
  end

  def prx_web_link(path)
    URI.join(prx_web_endpoint, path).to_s
  end

  def tag_for_url(source, url)
    prx_tag(url)
  end

  def prx_tag(url)
    vals = url.to_s.split('/')
    id   = vals.pop.to_i
    type = vals.pop.to_s
    "#{source_name}:#{type}-#{id}"
  end

  def find_or_create_guid(type, prx_obj)
    PMPGuidMapping.find_or_create_guid(source_name, type, prx_url(prx_obj.self.href))
  end
end
