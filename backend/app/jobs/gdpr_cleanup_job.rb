class GdprCleanupJob < ApplicationJob
  queue_as :default

  def perform
    # Удаляем данные пользователей, которые были soft deleted более 30 дней назад
    users_to_delete = User.where(deleted_at: ...30.days.ago)

    users_to_delete.find_each do |user|
      Rails.logger.info "GDPR: Permanently deleting user #{user.id} (deleted at #{user.deleted_at})"

      # Удаляем все связанные данные
      user.bookings.destroy_all
      user.services.destroy_all
      user.time_slots.destroy_all
      user.working_schedules.destroy_all
      user.working_day_exceptions.destroy_all

      # Окончательно удаляем пользователя
      user.really_destroy_all!
    end

    # Удаляем данные пользователей, которые запросили удаление более 30 дней назад
    deletion_requests = User.where(data_deletion_requested_at: ...30.days.ago)

    deletion_requests.find_each do |user|
      Rails.logger.info "GDPR: Processing deletion request for user #{user.id}"

      # Отправляем уведомление об удалении
      GdprMailer.deletion_notification(user).deliver_now

      # Soft delete пользователя
      user.soft_delete!
    end

    # Очищаем старые JWT токены
    JwtDenylist.where(exp: ...1.day.ago).delete_all

    # Очищаем старые данные бронирований
    old_bookings = Booking.where(data_retention_until: ...Time.current)
    old_bookings_count = old_bookings.count
    old_bookings.destroy_all

    Rails.logger.info "GDPR: Cleanup completed. Deleted #{users_to_delete.count} users, processed #{deletion_requests.count} deletion requests, cleaned #{old_bookings_count} old bookings"
  end
end
