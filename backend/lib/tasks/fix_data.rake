namespace :data do
  desc "Fix data inconsistencies in the system"
  task fix_inconsistencies: :environment do
    puts "Starting data consistency check and fix..."

    # 1. Исправляем отмененные записи, которые остались занимать слоты
    cancelled_bookings = Booking.where(status: 'cancelled')
    puts "Found #{cancelled_bookings.count} cancelled bookings"

    cancelled_bookings.find_each do |booking|
      slots_to_update = TimeSlot.where(booking_id: booking.id)
      if slots_to_update.exists?
        slots_to_update.update_all(
          booking_id: nil,
          is_available: true,
          updated_at: Time.current
        )
        puts "  - Freed #{slots_to_update.count} slots for cancelled booking #{booking.id}"
      end
    end

    # 2. Синхронизируем все записи со слотами
    User.where(role: 'master').find_each do |master|
      booking_dates = master.bookings.distinct.pluck(:start_time).map(&:to_date)
      puts "Reconciling bookings for master #{master.full_name} on #{booking_dates.count} dates"

      booking_dates.each do |date|
        master.reconcile_bookings_with_slots_for_date(date)
      end
    end

    # 3. Проверяем некорректные слоты (где end_time <= start_time)
    invalid_slots = TimeSlot.where('end_time <= start_time')
    puts "Found #{invalid_slots.count} invalid slots (end_time <= start_time)"

    if invalid_slots.exists?
      invalid_slots.destroy_all
      puts "  - Removed #{invalid_slots.count} invalid slots"
    end

    # 4. Проверяем слоты без даты
    slots_without_date = TimeSlot.where(date: nil)
    puts "Found #{slots_without_date.count} slots without date"

    if slots_without_date.exists?
      slots_without_date.destroy_all
      puts "  - Removed #{slots_without_date.count} slots without date"
    end

    # 5. Проверяем записи без мастера
    bookings_without_master = Booking.where(user: nil)
    puts "Found #{bookings_without_master.count} bookings without master"

    if bookings_without_master.exists?
      bookings_without_master.destroy_all
      puts "  - Removed #{bookings_without_master.count} bookings without master"
    end

    puts "Data consistency check and fix completed!"
  end

  desc "Check system health"
  task health_check: :environment do
    puts "=== System Health Check ==="

    # Проверяем количество записей
    total_bookings = Booking.count
    pending_bookings = Booking.where(status: 'pending').count
    confirmed_bookings = Booking.where(status: 'confirmed').count
    cancelled_bookings = Booking.where(status: 'cancelled').count

    puts "Bookings:"
    puts "  Total: #{total_bookings}"
    puts "  Pending: #{pending_bookings}"
    puts "  Confirmed: #{confirmed_bookings}"
    puts "  Cancelled: #{cancelled_bookings}"

    # Проверяем слоты
    total_slots = TimeSlot.count
    available_slots = TimeSlot.where(is_available: true).count
    booked_slots = TimeSlot.where.not(booking_id: nil).count
    work_slots = TimeSlot.where(slot_type: 'work').count

    puts "Time Slots:"
    puts "  Total: #{total_slots}"
    puts "  Available: #{available_slots}"
    puts "  Booked: #{booked_slots}"
    puts "  Work slots: #{work_slots}"

    # Проверяем мастеров
    masters = User.where(role: 'master')
    puts "Masters: #{masters.count}"

    masters.each do |master|
      master_bookings = master.bookings.count
      master_slots = master.time_slots.count
      puts "  #{master.full_name}: #{master_bookings} bookings, #{master_slots} slots"
    end

    # Проверяем проблемы
    puts "\n=== Potential Issues ==="

    # Отмененные записи со слотами
    cancelled_with_slots = Booking.where(status: 'cancelled').joins(:time_slots).count
    puts "  ⚠️  #{cancelled_with_slots} cancelled bookings still have slots" if cancelled_with_slots.positive?

    # Слоты без даты
    slots_no_date = TimeSlot.where(date: nil).count
    puts "  ⚠️  #{slots_no_date} slots without date" if slots_no_date.positive?

    # Некорректные слоты
    invalid_slots = TimeSlot.where('end_time <= start_time').count
    puts "  ⚠️  #{invalid_slots} invalid slots (end_time <= start_time)" if invalid_slots.positive?

    puts "\nHealth check completed!"
  end
end
