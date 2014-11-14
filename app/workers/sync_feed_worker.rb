class SyncFeedWorker

  def process(feed_id)
    Feed.find(feed_id).sync
  end

end
