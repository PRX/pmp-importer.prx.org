class SyncFeedWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, backtrace: true

  def process(feed_id)
    ActiveRecord::Base.connection_pool.with_connection do
      Feed.find(feed_id).sync
    end
  end

end
