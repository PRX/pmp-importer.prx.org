class FeedEntryModifiedWorker

  def process(feed_entry_id)
    entry = FeedEntry.find(feed_entry_id)
    FeedImporter.new.import(feed_entry_id: feed_entry_id)
  end

end
