class AddOwnerIdToTweets < ActiveRecord::Migration[7.2]
  def change
    add_column :tweets, :owner_id, :integer
  end
end
