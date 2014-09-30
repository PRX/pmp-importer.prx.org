class CreatePMPGuidMappings < ActiveRecord::Migration
  def change
    create_table :pmp_guid_mappings do |t|

      t.string :source_name
      t.string :source_type
      t.string :source_id
      t.string :guid, null: false

      t.timestamps
    end

    add_index :pmp_guid_mappings, :guid, unique: true
    add_index :pmp_guid_mappings, [:source_name, :source_type, :source_id], unique: true, name: 'by_source'
  end
end
