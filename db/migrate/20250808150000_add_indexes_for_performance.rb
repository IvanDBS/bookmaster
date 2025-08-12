class AddIndexesForPerformance < ActiveRecord::Migration[7.1]
  def change
    add_index :time_slots, [:user_id, :date, :start_time], unique: true, if_not_exists: true
    add_index :bookings, [:user_id, :start_time], if_not_exists: true
    add_index :working_day_exceptions, [:user_id, :date], unique: true, if_not_exists: true
  end
end


