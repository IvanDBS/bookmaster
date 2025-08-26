class AddServiceTypeToServices < ActiveRecord::Migration[7.1]
  def change
    add_column :services, :service_type, :string, null: false, default: 'маникюр'
    add_index :services, :service_type
  end
end
