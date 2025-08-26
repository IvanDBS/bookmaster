class AddGdprFields < ActiveRecord::Migration[7.1]
  def change
    # Добавляем поле для soft delete
    add_column :users, :deleted_at, :datetime
    add_index :users, :deleted_at
    
    # Добавляем поля для GDPR согласий
    add_column :users, :gdpr_consent_at, :datetime
    add_column :users, :gdpr_consent_version, :string, default: '1.0'
    add_column :users, :marketing_consent, :boolean, default: false
    add_column :users, :marketing_consent_at, :datetime
    
    # Добавляем поля для отслеживания изменений
    add_column :users, :data_export_requested_at, :datetime
    add_column :users, :data_deletion_requested_at, :datetime
    
    # Добавляем поля для bookings для GDPR
    add_column :bookings, :gdpr_consent_at, :datetime
    add_column :bookings, :data_retention_until, :datetime
    
    # Устанавливаем retention period (30 дней для soft delete)
    execute <<-SQL
      UPDATE bookings 
      SET data_retention_until = created_at + INTERVAL '30 days'
      WHERE data_retention_until IS NULL
    SQL
  end
end
