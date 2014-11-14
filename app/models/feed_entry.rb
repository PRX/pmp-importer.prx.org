class FeedEntry < ActiveRecord::Base
  belongs_to :feed

  after_commit :process_feed_entry

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
    entry.set_attributes(entry).save
  end

  def set_attributes(entry)
    self.digest           = FeedEntry.entry_digest(entry)

    self.author           = entry[:itunes_author] || entry[:author]
    self.content          = entry[:content]
    self.duration         = seconds_for_duration(entry[:itunes_duration] || entry[:duration])
    self.enclosure_length = entry[:enclosure_length]
    self.enclosure_type   = entry[:enclosure_type]
    self.enclosure_url    = entry[:enclosure_url]
    self.entry_id         = entry[:entry_id]
    self.explicit         = (entry[:itunes_explicit] && entry[:itunes_explicit] != 'no')
    self.image_url        = entry[:itunes_image]
    self.keywords         = entry[:itunes_keywords]
    self.published        = entry[:published]
    self.subtitle         = entry[:itunes_subtitle]
    self.summary          = entry[:itunes_summary] || entry[:summary]
    self.title            = entry[:title]
    self.updated          = entry[:updated]
    self.url              = entry[:url]

    self
  end

  def seconds_for_duration(duration)
    duration.split(':').reverse.inject([0,0]){|info, i| sum = (i.to_i * 60**info[0]) + info[1]; [(info[0]+1), sum] }[1]
  end

end
