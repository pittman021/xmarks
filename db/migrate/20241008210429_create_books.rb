class CreateBooks < ActiveRecord::Migration[7.2]
  def change
    create_table :books do |t|
      t.string :title
      t.string :author
      t.text :summary
      t.text :reason
      t.integer :user_id

      t.timestamps
    end
  end
end
