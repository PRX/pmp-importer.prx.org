require 'hyperresource'
require 'pmp'

class RSSImporter < ApplicationImporter
  attr_accessor :feed, :feed_doc

  def source_name
    'rss'
  end

  def import(options={})
    super

    # get the feed url
    rss_url = options[:rss_url]
    self.feed = retrieve_feed(rss_url)

    # find or create a pmp series for the feed
    feed_doc = find_or_create_feed_doc(feed)

    feed.entries.each do |item|
      puts "#{item.entry_id}\n\n"
    end

  end

  def find_or_create_feed_doc(feed)
    puts "feed: #{feed.inspect}"
    retrieve_doc('RSSFeed', feed.url) || create_feed_doc(feed.url)
  end

  def create_feed_doc(feed)
    sdoc = pmp.doc_of_type('series')
    sdoc.guid  = find_or_create_guid('RSSFeed', feed.url)
    sdoc.title = feed.title
    sdoc.description = feed.description
    

    # add_link_to_doc(sdoc, 'alternate', { href: prx_web_link("series/#{series.id}") })

    # # image
    # if series.links[:image]
    #   image_doc = find_or_create_image_doc(series.image)
    #   add_link_to_doc(sdoc, 'item', { href: image_doc.href, title: image_doc.title, rels: ['urn:collectiondoc:image'] })
    # end

    # # tags
    # set_standard_tags(sdoc, series)

    # # save it
    # sdoc.save

    # sdoc
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
