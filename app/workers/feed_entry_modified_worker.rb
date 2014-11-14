class FeedEntryModifiedWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, backtrace: true

  def process(feed_entry_id)
    ActiveRecord::Base.connection_pool.with_connection do
      entry = FeedEntry.find(feed_entry_id)
      FeedImporter.new.import(feed_entry_id: feed_entry_id)
    end
  end

end
