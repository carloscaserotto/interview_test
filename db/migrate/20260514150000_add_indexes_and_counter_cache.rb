class AddIndexesAndCounterCache < ActiveRecord::Migration[8.1]
  def change
    add_index :books, :status
    add_index :books, :title
    add_index :reservations, :email
    add_index :reservations, [:book_id, :created_at]

    add_column :books, :reservations_count, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE books
          SET reservations_count = (
            SELECT COUNT(*) FROM reservations WHERE reservations.book_id = books.id
          )
        SQL
      end
    end
  end
end
