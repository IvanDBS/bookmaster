class CreateWorkingSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :working_schedules do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :day_of_week, null: false # 0=воскресенье, 1=понедельник, ..., 6=суббота
      t.time :start_time # рабочий день начинается
      t.time :end_time   # рабочий день заканчивается
      t.time :lunch_start # обед начинается
      t.time :lunch_end   # обед заканчивается
      t.boolean :is_working, default: true
      t.integer :slot_duration_minutes, default: 60 # длительность одного слота

      t.timestamps
    end

    add_index :working_schedules, [:user_id, :day_of_week], unique: true
  end
end
