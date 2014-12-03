class CreatePRXAccountWhitelists < ActiveRecord::Migration
  def change
    create_table :prx_account_whitelists do |t|

      t.integer :prx_account_id

      t.timestamps
    end
  end
end
