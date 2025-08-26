class CreateTimeSlots < ActiveRecord::Migration[7.1]
  def change
    create_table :time_slots do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.integer :duration_minutes, default: 60
      t.boolean :is_available, default: true
      t.references :booking, null: true, foreign_key: true
      t.string :slot_type, default: 'work' # 'work', 'lunch', 'blocked'

      t.timestamps
    end

    add_index :time_slots, [:user_id, :date, :start_time], unique: true
    add_index :time_slots, [:user_id, :date]
    add_index :time_slots, [:date, :is_available]
  end
end
