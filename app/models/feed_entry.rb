class FeedEntry < ActiveRecord::Base
  belongs_to :feed

  after_commit :process_feed_entry

  serialize :categories, JSON

  def process_feed_entry
    FeedEntryModifiedWorker.perform_async(self.id)
  end

  def self.create_with_entry(feed, entry)
    entry = new.set_attributes(entry)
    entry.feed = feed
    entry.save
  end

  def self.entry_digest(entry)
    entry.to_h.to_digest.to_s
  end

  def is_changed?(entry)
    digest != FeedEntry.entry_digest(entry)
  end

  def update_with_entry(entry)
    return unless is_changed?(entry)
    entry.update_feed_entry(entry).save
  end

  def update_feed_entry(entry)
    self.digest           = FeedEntry.entry_digest(entry)

    self.author           = entry[:itunes_author] || entry[:author]
    self.block            = (entry[:itunes_block] == 'yes')
    self.categories       = entry[:categories]

    self.comment_count    = entry[:comment_count]
    self.comment_rss_url  = entry[:comment_rss_url]
    self.comment_url      = entry[:comments]
    self.content          = entry[:content]
    self.description      = entry[:description]
    self.duration         = seconds_for_duration(entry[:itunes_duration] || entry[:duration])
    self.entry_id         = entry[:entry_id]
    self.explicit         = entry[:itunes_explicit]
    self.feedburner_orig_enclosure_link = entry[:feedburner_orig_enclosure_link]
    self.feedburner_orig_link = entry[:feedburner_orig_link]
    self.image_url        = entry[:itunes_image]
    self.is_closed_captioned = (entry[:itunes_is_closed_captioned] == 'yes')
    self.keywords         = (entry[:itunes_keywords] || '').split(',').map(&:strip)
    self.position         = entry[:itunes_order]
    self.published        = entry[:published]
    self.subtitle         = entry[:itunes_subtitle]
    self.summary          = entry[:itunes_summary]
    self.title            = entry[:title]
    self.updated          = entry[:updated]
    self.url              = entry[:url]

    # TODO: do something with media_groups/media_contents if no enclosure
    if entry[:enclosure]
      self.enclosure_length = entry[:enclosure].length
      self.enclosure_type   = entry[:enclosure].type
      self.enclosure_url    = entry[:enclosure].url
    end

    self
  end

  def seconds_for_duration(duration)
    duration.split(':').reverse.inject([0,0]){|info, i| sum = (i.to_i * 60**info[0]) + info[1]; [(info[0]+1), sum] }[1]
  end

end
