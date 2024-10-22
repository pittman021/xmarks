class CreateAuthors < ActiveRecord::Migration[7.2]
  def change
    create_table :authors do |t|
      t.string :name
      t.string :username
      t.integer :followers_count
      t.string :profile_image_url
      t.string :twitter_id

      t.timestamps
    end
  end
end
