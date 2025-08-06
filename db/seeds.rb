# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Clearing existing data..."
TimeSlot.destroy_all
WorkingSchedule.destroy_all
Booking.destroy_all
Service.destroy_all
User.destroy_all

puts "Creating masters..."

# Create masters with services
masters = [
  {
    email: 'anna@example.com',
    password: 'password123',
    first_name: 'Анна',
    last_name: 'Петрова',
    phone: '+7 (999) 111-11-11',
    role: 'master',
    bio: 'Профессиональный мастер маникюра с 5-летним опытом',
    address: 'ул. Тверская, 15, Москва'
  },
  {
    email: 'maria@example.com',
    password: 'password123',
    first_name: 'Мария',
    last_name: 'Сидорова',
    phone: '+7 (999) 222-22-22',
    role: 'master',
    bio: 'Специалист по педикюру и уходу за ногами',
    address: 'ул. Арбат, 25, Москва'
  },
  {
    email: 'elena@example.com',
    password: 'password123',
    first_name: 'Елена',
    last_name: 'Козлова',
    phone: '+7 (999) 333-33-33',
    role: 'master',
    bio: 'Массажист с медицинским образованием',
    address: 'ул. Новый Арбат, 10, Москва'
  },
  {
    email: 'irina@example.com',
    password: 'password123',
    first_name: 'Ирина',
    last_name: 'Волкова',
    phone: '+7 (999) 444-44-44',
    role: 'master',
    bio: 'Мастер по наращиванию ресниц и бровей',
    address: 'ул. Покровка, 8, Москва'
  },
  {
    email: 'svetlana@example.com',
    password: 'password123',
    first_name: 'Светлана',
    last_name: 'Морозова',
    phone: '+7 (999) 555-55-55',
    role: 'master',
    bio: 'Косметолог и специалист по уходу за лицом',
    address: 'ул. Мясницкая, 20, Москва'
  }
]

masters.each do |master_data|
  user = User.create!(master_data)
  puts "Created master: #{user.full_name}"
  
  # Создаем базовое рабочее расписание для мастера
  user.create_default_schedule!
  puts "Created default schedule for #{user.full_name}"
end

puts "Creating services for masters..."

# Services for Anna (manicure specialist)
anna = User.find_by(email: 'anna@example.com')
if anna
  services = [
    { name: 'Классический маникюр', description: 'Базовый маникюр с покрытием гель-лаком', price: 1500, duration: 60, service_type: 'маникюр' },
    { name: 'Дизайн-маникюр', description: 'Маникюр с художественным дизайном', price: 2500, duration: 90, service_type: 'маникюр' },
    { name: 'SPA-маникюр', description: 'Маникюр с уходом за кожей рук', price: 2000, duration: 75, service_type: 'маникюр' }
  ]
  
  services.each do |service_data|
    service = anna.services.create!(service_data)
    puts "Created service for Anna: #{service.name} (#{service.service_type})"
  end
end

# Services for Maria (pedicure specialist)
maria = User.find_by(email: 'maria@example.com')
if maria
  services = [
    { name: 'Классический педикюр', description: 'Базовый педикюр с покрытием', price: 2000, duration: 60, service_type: 'педикюр' },
    { name: 'Аппаратный педикюр', description: 'Педикюр с использованием аппарата', price: 3000, duration: 90, service_type: 'педикюр' },
    { name: 'SPA-педикюр', description: 'Педикюр с уходом за кожей ног', price: 3500, duration: 120, service_type: 'педикюр' }
  ]
  
  services.each do |service_data|
    service = maria.services.create!(service_data)
    puts "Created service for Maria: #{service.name} (#{service.service_type})"
  end
end

# Services for Elena (massage specialist)
elena = User.find_by(email: 'elena@example.com')
if elena
  services = [
    { name: 'Классический массаж', description: 'Расслабляющий массаж всего тела', price: 3000, duration: 60, service_type: 'массаж' },
    { name: 'Массаж спины', description: 'Специализированный массаж спины', price: 2000, duration: 45, service_type: 'массаж' },
    { name: 'SPA-массаж', description: 'Массаж с ароматическими маслами', price: 4000, duration: 90, service_type: 'массаж' }
  ]
  
  services.each do |service_data|
    service = elena.services.create!(service_data)
    puts "Created service for Elena: #{service.name} (#{service.service_type})"
  end
end

# Update other masters to work with available service types
# Irina - now provides manicure services
irina = User.find_by(email: 'irina@example.com')
if irina
  services = [
    { name: 'Французский маникюр', description: 'Элегантный французский маникюр', price: 1800, duration: 75, service_type: 'маникюр' },
    { name: 'Гелевое наращивание', description: 'Наращивание ногтей гелем', price: 3000, duration: 120, service_type: 'маникюр' }
  ]
  
  services.each do |service_data|
    service = irina.services.create!(service_data)
    puts "Created service for Irina: #{service.name} (#{service.service_type})"
  end
end

# Svetlana - now provides massage services
svetlana = User.find_by(email: 'svetlana@example.com')
if svetlana
  services = [
    { name: 'Лимфодренажный массаж', description: 'Массаж для улучшения лимфотока', price: 3500, duration: 75, service_type: 'массаж' },
    { name: 'Расслабляющий массаж', description: 'Антистресс массаж для релаксации', price: 2800, duration: 60, service_type: 'массаж' }
  ]
  
  services.each do |service_data|
    service = svetlana.services.create!(service_data)
    puts "Created service for Svetlana: #{service.name} (#{service.service_type})"
  end
end

puts "Creating clients..."

# Create clients
clients = [
  {
    email: 'olga@example.com',
    password: 'password123',
    first_name: 'Ольга',
    last_name: 'Иванова',
    phone: '+7 (999) 666-66-66',
    role: 'client',
    bio: 'Люблю качественный маникюр и массаж',
    address: 'ул. Покровка, 10, Москва'
  },
  {
    email: 'natalia@example.com',
    password: 'password123',
    first_name: 'Наталья',
    last_name: 'Смирнова',
    phone: '+7 (999) 777-77-77',
    role: 'client',
    bio: 'Регулярно делаю педикюр и массаж',
    address: 'ул. Мясницкая, 20, Москва'
  },
  {
    email: 'test@example.com',
    password: 'password123',
    first_name: 'Тест',
    last_name: 'Пользователь',
    phone: '+7 (999) 123-45-67',
    role: 'client',
    bio: 'Тестовый пользователь',
    address: 'ул. Тестовая, 1, Москва'
  },
  {
    email: 'elena_client@example.com',
    password: 'password123',
    first_name: 'Елена',
    last_name: 'Кузнецова',
    phone: '+7 (999) 888-88-88',
    role: 'client',
    bio: 'Постоянный клиент массажиста',
    address: 'ул. Тверская, 5, Москва'
  },
  {
    email: 'anna_client@example.com',
    password: 'password123',
    first_name: 'Анна',
    last_name: 'Соколова',
    phone: '+7 (999) 999-99-99',
    role: 'client',
    bio: 'Любительница косметологических процедур',
    address: 'ул. Арбат, 15, Москва'
  }
]

clients.each do |client_data|
  user = User.create!(client_data)
  puts "Created client: #{user.full_name}"
end

puts "Generating time slots for masters..."

# Generate time slots for the next 14 days for all masters
masters = User.where(role: 'master')
(0..13).each do |day_offset|
  date = day_offset.days.from_now.to_date
  masters.each do |master|
    master.ensure_slots_for_date(date)
  end
end
puts "Generated time slots for #{masters.count} masters for 14 days"

puts "Creating bookings..."

# Create bookings
if User.exists?(role: 'master') && User.exists?(role: 'client')
  masters = User.where(role: 'master')
  clients = User.where(role: 'client')
  
  # Get some services
  services = Service.all
  
  # Create bookings for the next few days
  (1..14).each do |day_offset|
    masters.each_with_index do |master, master_index|
      master.services.each_with_index do |service, service_index|
        client = clients[master_index % clients.length]
        
        # Добавляем больше интервала между записями
        start_time = day_offset.days.from_now + (10 + service_index * 3).hours
        end_time = start_time + service.duration.minutes
        
        # Проверяем, нет ли конфликта
        conflicting_booking = Booking.where(
          user: master,
          start_time: start_time..end_time
        ).or(
          Booking.where(
            user: master,
            end_time: start_time..end_time
          )
        ).first
        
        unless conflicting_booking
          booking = Booking.create!(
            user: master,
            service: service,
            start_time: start_time,
            end_time: end_time,
            client_name: client.full_name,
            client_email: client.email,
            client_phone: client.phone,
            status: ['pending', 'confirmed', 'cancelled'].sample
          )
          
          puts "Created booking: #{client.full_name} -> #{master.full_name} (#{service.name}) on #{start_time.strftime('%d.%m.%Y %H:%M')}"
        else
          puts "Skipped booking due to time conflict: #{client.full_name} -> #{master.full_name} (#{service.name})"
        end
      end
    end
  end
  
  # Добавляем дополнительные записи для Анны Петровой
  anna = User.find_by(email: 'anna@example.com')
  if anna
    anna_services = anna.services
    clients.each do |client|
      # Создаем записи на сегодня и завтра для Анны
      [0, 1].each do |day_offset|
        anna_services.each_with_index do |service, index|
          # Увеличиваем интервал между записями
          start_time = day_offset.days.from_now + (9 + index * 4).hours
          end_time = start_time + service.duration.minutes
          
          # Проверяем конфликт
          conflicting_booking = Booking.where(
            user: anna,
            start_time: start_time..end_time
          ).or(
            Booking.where(
              user: anna,
              end_time: start_time..end_time
            )
          ).first
          
          unless conflicting_booking
            booking = Booking.create!(
              user: anna,
              service: service,
              start_time: start_time,
              end_time: end_time,
              client_name: client.full_name,
              client_email: client.email,
              client_phone: client.phone,
              status: ['pending', 'confirmed'].sample
            )
            
            puts "Created additional booking for Anna: #{client.full_name} -> #{service.name} on #{start_time.strftime('%d.%m.%Y %H:%M')}"
          else
            puts "Skipped additional booking for Anna due to conflict: #{client.full_name} -> #{service.name}"
          end
        end
      end
    end
  end
end

puts "Seeds completed successfully!"
puts "Created #{User.where(role: 'master').count} masters"
puts "Created #{User.where(role: 'client').count} clients"
puts "Created #{Service.count} services"
puts "Created #{Booking.count} bookings"
