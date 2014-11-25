class AddFeedItemAttributes < ActiveRecord::Migration
  def change
    add_column :feed_entries, :description, :text
    add_column :feed_entries, :categories, :text
    add_column :feed_entries, :comment_url, :string
    add_column :feed_entries, :block, :boolean
    add_column :feed_entries, :is_closed_captioned, :boolean
    add_column :feed_entries, :position, :integer
    add_column :feed_entries, :comment_rss_url, :string
    add_column :feed_entries, :comment_count, :string
    add_column :feed_entries, :feedburner_orig_link, :string
    add_column :feed_entries, :feedburner_orig_enclosure_link, :string
  end
end
