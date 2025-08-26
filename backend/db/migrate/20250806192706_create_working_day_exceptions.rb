class CreateWorkingDayExceptions < ActiveRecord::Migration[7.1]
  def change
    create_table :working_day_exceptions do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.boolean :is_working, default: false
      t.string :reason

      t.timestamps
    end

    add_index :working_day_exceptions, [:user_id, :date], unique: true
    add_index :working_day_exceptions, :date
  end
end
