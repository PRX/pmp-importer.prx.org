class PRXStoryModifiedWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, backtrace: true

  def process(story_id)
    ActiveRecord::Base.connection_pool.with_connection do
      prx = PRXImporter.new.import(prx_story_id: story_id)
    end
  end

end
