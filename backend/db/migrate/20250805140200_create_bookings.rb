class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :status, default: 'pending'
      t.references :user, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.string :client_name, null: false
      t.string :client_email, null: false
      t.string :client_phone

      t.timestamps
    end
    
    add_index :bookings, :start_time
    add_index :bookings, :status
    add_index :bookings, :client_email
  end
end
