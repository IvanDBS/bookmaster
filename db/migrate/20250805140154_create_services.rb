class CreateServices < ActiveRecord::Migration[7.1]
  def change
    create_table :services do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :duration, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :services, :name
    add_index :services, :price
  end
end
