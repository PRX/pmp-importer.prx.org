class FeedModifiedWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, backtrace: true

  def perform(feed_id)
    ActiveRecord::Base.connection_pool.with_connection do
      feed = Feed.find(feed_id)
      FeedImporter.new.import(feed_id: feed.id)
    end
  end

end
