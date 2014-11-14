class CreateFeedEntries < ActiveRecord::Migration
  def change
    create_table :feed_entries do |t|

      t.references :feed, index: true

      t.string :digest, index: true

      t.string :entry_id, index: true
      t.string :url, index: true
      t.string :author
      t.text :title
      t.text :subtitle
      t.text :content
      t.text :summary
      t.datetime :published
      t.datetime :updated

      t.string :image_url
      t.string :enclosure_length
      t.string :enclosure_type
      t.string :enclosure_url
      t.integer :duration

      t.boolean :explicit
      t.text :keywords

      t.timestamps
    end
  end
end
