class FixCancelledBookingsSlots < ActiveRecord::Migration[7.1]
  def up
    # Находим все отмененные записи
    cancelled_bookings = Booking.where(status: 'cancelled')

    Rails.logger.debug { "Found #{cancelled_bookings.count} cancelled bookings to fix" }

    cancelled_bookings.find_each do |booking|
      # Освобождаем слоты связанные с отмененными записями
      slots_to_update = TimeSlot.where(booking_id: booking.id)

      if slots_to_update.exists?
        slots_to_update.update_all(
          booking_id: nil,
          is_available: true,
          updated_at: Time.current
        )
        Rails.logger.debug { "Freed #{slots_to_update.count} slots for cancelled booking #{booking.id}" }
      end
    end

    # Запускаем синхронизацию для всех мастеров на все даты с записями
    User.where(role: 'master').find_each do |master|
      # Получаем все уникальные даты с записями для этого мастера
      booking_dates = master.bookings.distinct.pluck(:start_time).map(&:to_date)

      booking_dates.each do |date|
        master.reconcile_bookings_with_slots_for_date(date)
      end

      Rails.logger.debug { "Reconciled bookings for master #{master.id} on #{booking_dates.count} dates" }
    end
  end

  def down
    # Откат не требуется, так как мы только исправляем данные
  end
end
