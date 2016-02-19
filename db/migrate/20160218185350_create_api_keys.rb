class CreateApiKeys < ActiveRecord::Migration
  def change
    create_table :api_keys do |t|
      t.integer :user_id

      t.string :access_token

      t.timestamps null: false
    end

    add_index :api_keys, :user_id

    ApiKey.create!
  end
end
