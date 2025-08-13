class AddConfirmableToUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index :users, :confirmation_token, unique: true

    # Backfill existing users as confirmed to avoid locking anyone out
    execute <<~SQL
      UPDATE users SET confirmed_at = NOW() WHERE confirmed_at IS NULL;
    SQL
  end

  def down
    remove_index :users, :confirmation_token if index_exists?(:users, :confirmation_token)
    remove_column :users, :unconfirmed_email if column_exists?(:users, :unconfirmed_email)
    remove_column :users, :confirmation_sent_at if column_exists?(:users, :confirmation_sent_at)
    remove_column :users, :confirmed_at if column_exists?(:users, :confirmed_at)
    remove_column :users, :confirmation_token if column_exists?(:users, :confirmation_token)
  end
end


