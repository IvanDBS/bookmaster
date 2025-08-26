class GdprDataExportJob < ApplicationJob
  queue_as :default

  def perform(user_id, data)
    user = User.find(user_id)

    # Создаем JSON файл с данными
    json_data = JSON.pretty_generate(data)

    # Создаем временный файл
    filename = "gdpr_export_#{user.id}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json"
    file_path = Rails.root.join('tmp', filename)

    File.write(file_path, json_data)

    # Отправляем email с файлом
    GdprMailer.data_export(user, file_path).deliver_now

    # Удаляем временный файл
    FileUtils.rm_f(file_path)

    Rails.logger.info "GDPR: Data export completed for user #{user.id}"
  rescue StandardError => e
    Rails.logger.error "GDPR: Data export failed for user #{user_id}: #{e.message}"
    # Можно добавить уведомление администратора об ошибке
  end
end
