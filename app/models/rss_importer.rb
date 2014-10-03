require 'hyperresource'
require 'pmp'

class RSSImporter < ApplicationImporter
  attr_accessor :doc, :item, :feed, :feed_doc

  def source_name
    'rss'
  end

  def import(options={})
    super

    # get the feed url
    rss_url = options[:rss_url]
    self.feed = retrieve_feed(rss_url)

    # find or create a pmp series for the feed
    self.feed_doc = find_or_create_feed_doc(feed)

    feed.entries.each do |item|
      self.item = self.doc = nil
      import_item(item)
    end

  end

  def import_item(item)
    logger.debug("import_item: #{item.entry_id}")

    self.item = item
    self.doc  = find_or_init_item_doc(item)

    set_series
    set_image
    set_audio

    set_attributes
    set_links
    set_tags

    doc.save
    logger.debug("import_item: #{item.entry_id} saved as: #{doc.guid}")

    return doc
  end

  def set_tags
    logger.debug("set_tags")

    set_standard_tags(doc, item.entry_id)

    (item.itunes_keywords || '').split(',').each{|kw| add_tag_to_doc(doc, kw)}

    if item.itunes_explicit && item.itunes_explicit != 'no'
      add_tag_to_doc(doc, 'explicit')
    end
  end

  def set_links
    logger.debug("set_links")

    add_link_to_doc(doc, 'alternate', { href: item.url })
    # add_link_to_doc(doc, 'author', { href: prx_web_link("pieces/#{story.id}") })
    # add_link_to_doc(doc, 'copyright', { href: prx_web_link("pieces/#{story.id}") })
  end

  def set_attributes
    logger.debug("set_attributes")

    doc.hreflang       = "en"
    doc.title          = item.title

    doc.teaser         = item.itunes_subtitle
    doc.description    = item.itunes_summary || item.summary || strip_tags(content)
    doc.contentencoded = item.content
    doc.byline         = item.itunes_author || feed_doc.byline

    doc.published      = item.published || item.last_modified
    doc.valid          = {from: doc.published, to: (doc.published + 1000.years)}

  end

  def set_series
    logger.debug("set_series")

    return unless feed_doc

    add_link_to_doc(doc, 'collection', { href: feed_doc.href, title: feed_doc.title, rels:["urn:collectiondoc:collection:series"] })
  end

  def set_image
    logger.debug("set_image")

    return if item.itunes_image.blank?

    image_doc = find_or_create_image_doc(item.itunes_image)
    add_link_to_doc(doc, 'item', { href: image_doc.href, title: image_doc.title, rels: ['urn:collectiondoc:image'] })
  end

  def set_audio
    logger.debug("set_audio")

    audio_doc = find_or_create_audio_doc(item)
    add_link_to_doc(doc, 'item', { href: audio_doc.href, title: audio_doc.title, rels: ['urn:collectiondoc:audio'] })

  end

  def find_or_create_audio_doc(item)
    retrieve_doc('Audio', item.enclosure_url) || create_audio_doc(item)
  end

  def create_audio_doc(item)
    adoc = nil

    adoc = pmp.doc_of_type('audio')
    adoc.guid  = find_or_create_guid('Audio', item.enclosure_url)
    adoc.title = url_filename(item.enclosure_url)

    href     = item.enclosure_url
    type     = item.enclosure_type
    size     = item.enclosure_length
    duration = seconds_for_duration(item.itunes_duration)
    add_link_to_doc(adoc, 'enclosure', { href: href, type: type, meta: {size: size, duration: duration } })

    set_standard_tags(adoc, item.enclosure_url)

    adoc.save

    adoc
  end

  def seconds_for_duration(duration)
    duration.split(':').reverse.inject([0,0]){|info, i| sum = (i.to_i * 60**info[0]) + info[1]; [(info[0]+1), sum] }[1]
  end

  def find_or_init_item_doc(item)
    sdoc = retrieve_doc('RSSItem', item.entry_id)

    if !sdoc
      sdoc = pmp.doc_of_type('story')
      sdoc.guid = find_or_create_guid('RSSItem', item.entry_id)
    end

    sdoc
  end

  def find_or_create_feed_doc(feed)
    # puts "feed: #{feed.inspect}"
    retrieve_doc('RSSFeed', feed.url) || create_feed_doc(feed)
  end

  def create_feed_doc(feed)
    sdoc = pmp.doc_of_type('series')
    sdoc.guid        = find_or_create_guid('RSSFeed', feed.url)
    sdoc.title       = feed.title
    
    sdoc.teaser      = feed.itunes_subtitle || feed.description
    sdoc.description = feed.itunes_summary || feed.description
    sdoc.byline      = extract_byline(feed)

    (feed.itunes_keywords || '').split(',').each{|kw| add_tag_to_doc(sdoc, kw)}

    add_link_to_doc(sdoc, 'alternate', { href: (feed.url || feed.feed_url) })

    # image
    if !feed.itunes_image.blank?
      image_doc = find_or_create_image_doc(feed.itunes_image)
      add_link_to_doc(sdoc, 'item', { href: image_doc.href, title: image_doc.title, rels: ['urn:collectiondoc:image'] })
    end

    # tags
    set_standard_tags(sdoc, feed.url)

    # save it
    sdoc.save

    sdoc
  end

  def find_or_create_image_doc(image_url)
    retrieve_doc('Image', image_url) || create_image_doc(image_url)
  end

  # retreive the image and detect features of it (height, width) ?
  def create_image_doc(image_url)
    idoc = nil

    idoc = pmp.doc_of_type('image')
    idoc.guid   = find_or_create_guid('Image', image_url)
    idoc.title  = url_filename(image_url)
    idoc.byline = ""

    href = image_url
    type = image_mime_type(url_filename(image_url))
    add_link_to_doc(idoc, 'enclosure', { href: image_url, type: type })

    set_standard_tags(idoc, image_url)

    idoc.save

    idoc
  end

  def url_filename(url)
    URI.parse(url).path.split('/').last
  end

  def image_mime_type(filename)
    ext = File.extname(filename)
    return 'image/jpeg' if ['.jpeg', '.jpe', '.jpg', '.jfif'].include?(ext)
    return 'image/gif'  if ['.gif'].include?(ext)
    return 'image/png'  if ['.png', '.x-png'].include?(ext)
    return 'image'
  end

  def extract_byline(feed)
    owners = feed.itunes_owners.collect{|o| puts o.name }.join(', ') if (feed.itunes_owners && feed.itunes_owners.size > 0)
    owners || feed.itunes_author || feed.managingEditor
  end

  def retrieve_feed(rss_url)
    can_process = true

    # pull the feed
    feed = Feedjira::Feed.fetch_and_parse(rss_url, {
      on_success: ->(url, feed){ puts "url: #{url}, feed: #{feed.inspect}" } ,
      on_failure: ->(c, err){ puts "c: #{c.response_code}, err: #{err.inspect}"; can_process = false }
    })

    puts "can_process: #{can_process}, feed: #{feed.class.inspect}: #{feed.inspect}"
    can_process ? feed : nil
  end

  def find_or_create_guid(type, url)
    PMPGuidMapping.find_or_create_guid(source_name, type, url)
  end

end
