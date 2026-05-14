class AddStatusIndexToBooks < ActiveRecord::Migration[8.1]
  def change
    add_index :books, :status
  end
end
