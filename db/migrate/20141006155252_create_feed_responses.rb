class CreateFeedResponses < ActiveRecord::Migration

  def change
    create_table :feed_responses do |t|

      t.integer  :feed_id

      # don't assume this is the same as the one in the feed - feeds can change
      t.string   :url 

      # these are derived, ans useful to have in the db cols, not just in headers
      t.string   :etag
      t.datetime :last_modified

      # about the request
      t.text     :request
      t.text     :request_headers

      # about the response
      t.string   :status
      t.string   :method
      t.text     :response_headers
      t.text     :body


      t.timestamps
    end
  end

end
