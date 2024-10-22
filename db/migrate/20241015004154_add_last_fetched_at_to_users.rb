class AddLastFetchedAtToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :last_fetched_at, :datetime
  end
end
