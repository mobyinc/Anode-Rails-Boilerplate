class CreateInstallations < ActiveRecord::Migration
  def change
    create_table :installations do |t|
      t.integer :user_id

      t.string :device_token

      t.timestamps null: false
    end

    add_index :installations, :user_id
  end
end
