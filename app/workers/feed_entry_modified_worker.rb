class FeedEntryModifiedWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, backtrace: true

  def process(feed_entry_id)
    entry = FeedEntry.find(feed_entry_id)
    FeedImporter.new.import(feed_entry_id: feed_entry_id)
  end

end
