class CreateTweets < ActiveRecord::Migration[7.2]
  def change
    create_table :tweets do |t|
      t.string :text
      t.string :twitter_id
      t.references :author, null: false, foreign_key: true
      t.datetime :posted_at
      t.boolean :liked
      t.boolean :bookmarked

      t.timestamps
    end
  end
end
