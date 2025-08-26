# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "[SEEDS] Starting (env=#{Rails.env})"

# Temporarily allow seeds in production for initial setup
# unless Rails.env.development?
#   puts "[SEEDS] Skipping: destructive seeds are disabled outside development (env=#{Rails.env})"
#   Rails.logger.debug do
#     "[SEEDS] Destructive operations are disabled outside development (current: #{Rails.env}). Skipping."
#   end
#   return
# end

Rails.logger.debug "Clearing existing data..."
TimeSlot.destroy_all
WorkingSchedule.destroy_all
Booking.destroy_all
Service.destroy_all
User.destroy_all

Rails.logger.debug "Creating masters..."

# Create masters with services
masters = [
  {
    email: 'maria@example.com',
    password: 'password123',
    first_name: 'Мария',
    last_name: 'Сидорова',
    phone: '0712345678',
    role: 'master',
    bio: 'Специалист по педикюру и уходу за ногами',
    address: 'ул. Арбат, 25, Москва'
  },
  {
    email: 'elena@example.com',
    password: 'password123',
    first_name: 'Елена',
    last_name: 'Козлова',
    phone: '0712345678',
    role: 'master',
    bio: 'Массажист с медицинским образованием',
    address: 'ул. Новый Арбат, 10, Москва'
  },
  {
    email: 'irina@example.com',
    password: 'password123',
    first_name: 'Ирина',
    last_name: 'Волкова',
    phone: '0712345678',
    role: 'master',
    bio: 'Мастер по наращиванию ресниц и бровей',
    address: 'ул. Покровка, 8, Москва'
  }
]

masters.each do |master_data|
  user = User.create!(master_data.merge(confirmed_at: Time.current))
  Rails.logger.debug { "Created master: #{user.full_name}" }
  
  # Создаем базовое рабочее расписание для мастера
  user.create_default_schedule!
  Rails.logger.debug { "Created default schedule for #{user.full_name}" }
end

Rails.logger.debug "Creating services for masters..."

# Services for Anna (manicure specialist)
anna = User.find_by(email: 'anna@example.com')
if anna
  # Реальные позиции из прайса мастера 1 (маникюр)
  services = [
    { name: 'Manichiura igienica', description: 'Гигиенический маникюр', price: 50, duration: 60, 
      service_type: 'маникюр' },
    { name: 'Acoperire', description: 'Покрытие', price: 180, duration: 60, service_type: 'маникюр' },
    { name: 'Corectie marimea 1-2', description: 'Коррекция длины 1–2', price: 200, duration: 60, 
      service_type: 'маникюр' },
    { name: 'Corectie marimea 3-4', description: 'Коррекция длины 3–4', price: 250, duration: 60, 
      service_type: 'маникюр' },
    { name: 'Alungire marimea 1-2', description: 'Наращивание длины 1–2', price: 250, duration: 60, 
      service_type: 'маникюр' },
    { name: 'Alungire marimea 3-4', description: 'Наращивание длины 3–4', price: 300, duration: 60, 
      service_type: 'маникюр' }
  ]
  
  services.each do |service_data|
    service = anna.services.create!(service_data)
    Rails.logger.debug { "Created service for Anna: #{service.name} (#{service.service_type})" }
  end
end

# Services for Maria (pedicure specialist)
maria = User.find_by(email: 'maria@example.com')
if maria
  # Реальные позиции из прайса мастера 2 (педикюр)
  services = [
    { name: 'Pedichiură igienica', description: 'Гигиенический педикюр', price: 300, duration: 60, 
      service_type: 'педикюр' },
    { name: 'Pedichiură cu gel', description: 'Педикюр с гелевым покрытием', price: 450, duration: 60, 
      service_type: 'педикюр' },
    # Из первого прайса присутствует базовая услуга педикюра
    { name: 'Pedichiura', description: 'Базовый педикюр', price: 200, duration: 60, service_type: 'педикюр' }
  ]
  
  services.each do |service_data|
    service = maria.services.create!(service_data)
    Rails.logger.debug { "Created service for Maria: #{service.name} (#{service.service_type})" }
  end
end

# Дополнительно: второй мастер маникюра (Ирина) с прайсом по размерам
irina = User.find_by(email: 'irina@example.com')
if irina
  services = [
    { name: 'Mărimea 1/2', description: 'Маникюр/наращивание длина 1/2', price: 350, duration: 60, 
      service_type: 'маникюр' },
    { name: 'Mărimea 3/4', description: 'Маникюр/наращивание длина 3/4', price: 400, duration: 60, 
      service_type: 'маникюр' },
    { name: 'Mărimea 5/6', description: 'Маникюр/наращивание длина 5/6', price: 450, duration: 60, 
      service_type: 'маникюр' }
  ]

  services.each do |service_data|
    service = irina.services.create!(service_data)
    Rails.logger.debug { "Created service for Irina: #{service.name} (#{service.service_type})" }
  end
end

# Services for Elena (massage specialist)
elena = User.find_by(email: 'elena@example.com')
if elena
  services = [
    { name: 'Классический массаж', description: 'Расслабляющий массаж всего тела', price: 3000, duration: 60, 
      service_type: 'массаж' },
    { name: 'Массаж спины', description: 'Специализированный массаж спины', price: 2000, duration: 60, 
      service_type: 'массаж' },
    { name: 'SPA-массаж', description: 'Массаж с ароматическими маслами', price: 4000, duration: 60, 
      service_type: 'массаж' }
  ]
  
  services.each do |service_data|
    service = elena.services.create!(service_data)
    Rails.logger.debug { "Created service for Elena: #{service.name} (#{service.service_type})" }
  end
end

# Svetlana - massage services
svetlana = User.find_by(email: 'svetlana@example.com')
if svetlana
  services = [
    { name: 'Лимфодренажный массаж', description: 'Массаж для улучшения лимфотока', price: 3500, duration: 60, 
      service_type: 'массаж' },
    { name: 'Расслабляющий массаж', description: 'Антистресс массаж для релаксации', price: 2800, duration: 60, 
      service_type: 'массаж' }
  ]
  
  services.each do |service_data|
    service = svetlana.services.create!(service_data)
    Rails.logger.debug { "Created service for Svetlana: #{service.name} (#{service.service_type})" }
  end
end

Rails.logger.debug "Creating clients..."

# Create clients
clients = [
  {
    email: 'test2@example.com',
    password: 'password',
    first_name: 'Ольга',
    last_name: 'Иванова',
    phone: '0600000000',
    role: 'client',
    bio: 'Люблю качественный маникюр и массаж',
    address: 'ул. Покровка, 10, Москва'
  },
  {
    email: 'test3@example.com',
    password: 'password',
    first_name: 'Наталья',
    last_name: 'Смирнова',
    phone: '0600000000',
    role: 'client',
    bio: 'Регулярно делаю педикюр и массаж',
    address: 'ул. Мясницкая, 20, Москва'
  },
  {
    email: 'test@example.com',
    password: 'password',
    first_name: 'Тест',
    last_name: 'Пользователь',
    phone: '0600000000',
    role: 'client',
    bio: 'Тестовый пользователь',
    address: 'ул. Тестовая, 1, Москва'
  }
]

clients.each do |client_data|
  user = User.create!(client_data.merge(confirmed_at: Time.current))
  Rails.logger.debug { "Created client: #{user.full_name}" }
end

# Admin user
Rails.logger.debug "Creating admin user..."
admin_email = 'ivan.teaca@gmail.com'
User.create!(
  email: admin_email,
  password: 'password',
  first_name: 'Ivan',
  last_name: 'Admin',
  phone: '+0000000000',
  role: 'admin',
  confirmed_at: Time.current
)
Rails.logger.debug { "Created admin: #{admin_email}" }

Rails.logger.debug "Generating time slots for masters..."

# Generate time slots for the next 14 days for all masters
masters = User.where(role: 'master')
(0..13).each do |day_offset|
  date = Date.current + day_offset.days
  masters.each do |master|
    master.ensure_slots_for_date(date)
  end
end
Rails.logger.debug { "Generated time slots for #{masters.count} masters for 14 days" }

Rails.logger.debug "Creating bookings aligned to slots..."

if User.exists?(role: 'master') && User.exists?(role: 'client')
  masters = User.where(role: 'master').to_a
  clients = User.where(role: 'client').to_a

  # Фиксированные времена для записей (увеличиваем в 2 раза)
  booking_times = ['09:00', '11:00', '14:00', '16:00']

  (1..14).each do |day_offset|
    date = Date.current + day_offset.days
    
    # Создаем 4 записи в день (по одному бронированию на время)
    booking_times.each_with_index do |time_str, index|
      # Выбираем случайного мастера для этой записи
      master = masters.sample
      
      # Генерируем/гарантируем слоты для мастера
      master.ensure_slots_for_date(date)
      
      # Находим слот для этого времени используя Ruby фильтрацию
      hour, minute = time_str.split(':').map(&:to_i)
      slot = master.time_slots.for_date(date)
                   .work_slots
                   .available
                   .find { |s| s.start_time.hour == hour && s.start_time.min == minute }
      
      next unless slot # Пропускаем если слот не найден
      
      service = master.services.sample
      client = clients.sample

      # Создаем время записи точно по слоту
      start_dt = Time.zone.parse("#{date} #{time_str}")
      end_dt = start_dt + service.duration.minutes

      status = %w[pending confirmed cancelled].sample
      booking = Booking.create!(
        user: master,
        service: service,
        start_time: start_dt,
        end_time: end_dt,
        client_name: client.full_name,
        client_email: client.email,
        client_phone: client.phone,
        status: status
      )

      # Правильно связываем слот с записью
      slot.update!(booking_id: booking.id, is_available: false)
      Rails.logger.debug do
        "Created booking #{index + 1}/#{booking_times.size}: #{client.full_name} -> #{master.full_name} (#{service.name}, status: #{status}) on #{start_dt.strftime('%d.%m.%Y %H:%M')} in slot #{slot.id}"
      end
    end
    
    # Запускаем синхронизацию для всех мастеров
    masters.each do |master|
      master.reconcile_bookings_with_slots_for_date(date)
    end
  end
end

Rails.logger.debug "Seeds completed successfully!"
puts "[SEEDS] Done"
Rails.logger.debug { "Created #{User.where(role: 'master').count} masters" }
Rails.logger.debug { "Created #{User.where(role: 'client').count} clients" }
Rails.logger.debug { "Created #{Service.count} services" }
Rails.logger.debug { "Created #{Booking.count} bookings" }
