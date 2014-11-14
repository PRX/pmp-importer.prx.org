class AddAttributesToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :title, :string
    add_column :feeds, :subtitle, :string
    add_column :feeds, :description, :text
    add_column :feeds, :summary, :text
    add_column :feeds, :owners, :text
    add_column :feeds, :author, :string
    add_column :feeds, :keywords, :text
    add_column :feeds, :categories, :text
    add_column :feeds, :image_url, :string
    add_column :feeds, :feed_url, :string
    add_column :feeds, :explicit, :boolean
  end
end
