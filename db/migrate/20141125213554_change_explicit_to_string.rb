class ChangeExplicitToString < ActiveRecord::Migration
  def up
    change_column :feeds, :explicit, 'varchar(255) USING CAST(explicit AS varchar)'
    change_column :feed_entries, :explicit, 'varchar(255) USING CAST(explicit AS varchar)'

    add_column :feeds, :last_modified, :datetime
    add_column :feeds, :pub_date, :datetime
  end

  def down
    change_column :feeds, :explicit, 'boolean USING CAST(explicit AS boolean)'
    change_column :feed_entries, :explicit, 'boolean USING CAST(explicit AS boolean)'

    remove_column :feeds, :last_modified
    remove_column :feeds, :pub_date
  end

end
