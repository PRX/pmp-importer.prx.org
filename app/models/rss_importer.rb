require 'hyperresource'
require 'pmp'

class RSSImporter < ApplicationImporter
  attr_accessor :feed, :item, :doc

  def source_name
    'rss'
  end

  def import(options={})
    super

    # get the feed url
    rss_url = options[:rss_url]

    # pull the feed
  end

end
