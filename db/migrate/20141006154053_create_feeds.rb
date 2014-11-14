class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|

      t.string :url
      t.text   :options

      t.timestamps
    end
  end
end
