class AddImageUrlToBooks < ActiveRecord::Migration[7.2]
  def change
    add_column :books, :image_url, :string
  end
end
