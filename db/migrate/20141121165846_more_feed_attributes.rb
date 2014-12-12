class MoreFeedAttributes < ActiveRecord::Migration
  def change
    add_column :feeds, :language, :string
    add_column :feeds, :copyright, :string
    add_column :feeds, :managing_editor, :string
    add_column :feeds, :web_master, :string
    add_column :feeds, :generator, :string
    add_column :feeds, :ttl, :integer
    add_column :feeds, :published, :datetime
    add_column :feeds, :last_built, :datetime
    add_column :feeds, :block, :boolean
    add_column :feeds, :complete, :boolean
    add_column :feeds, :new_feed_url, :string
    add_column :feeds, :update_period, :string
    add_column :feeds, :update_frequency, :integer
    add_column :feeds, :feedburner_name, :string
    add_column :feeds, :hub_url, :string
  end
end
