# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating test masters and services..."

# Create masters
masters = [
  {
    email: 'anna.manicure@example.com',
    password: 'password123',
    first_name: 'Анна',
    last_name: 'Петрова',
    phone: '+7 (999) 123-45-67',
    role: 'master',
    bio: 'Профессиональный мастер маникюра с 5-летним опытом. Специализируюсь на классическом и дизайн-маникюре.',
    address: 'ул. Тверская, 15, Москва'
  },
  {
    email: 'maria.pedicure@example.com',
    password: 'password123',
    first_name: 'Мария',
    last_name: 'Сидорова',
    phone: '+7 (999) 234-56-78',
    role: 'master',
    bio: 'Мастер педикюра с медицинским образованием. Выполняю аппаратный и классический педикюр.',
    address: 'ул. Арбат, 25, Москва'
  },
  {
    email: 'elena.massage@example.com',
    password: 'password123',
    first_name: 'Елена',
    last_name: 'Козлова',
    phone: '+7 (999) 345-67-89',
    role: 'master',
    bio: 'Дипломированный массажист с 8-летним стажем. Специализируюсь на классическом, расслабляющем и лечебном массаже.',
    address: 'Ленинский проспект, 45, Москва'
  }
]

masters.each do |master_data|
  user = User.find_or_create_by(email: master_data[:email]) do |u|
    u.assign_attributes(master_data)
  end
  
  puts "Created master: #{user.full_name}"
  
  # Create services for each master
  case user.email
  when 'anna.manicure@example.com'
    services = [
      { name: 'Классический маникюр', description: 'Базовый маникюр с покрытием', price: 1500, duration: 60 },
      { name: 'Дизайн-маникюр', description: 'Маникюр с художественным дизайном', price: 2500, duration: 90 },
      { name: 'SPA-маникюр', description: 'Маникюр с уходом за кожей рук', price: 2000, duration: 75 }
    ]
  when 'maria.pedicure@example.com'
    services = [
      { name: 'Классический педикюр', description: 'Базовый педикюр с покрытием', price: 2000, duration: 60 },
      { name: 'Аппаратный педикюр', description: 'Педикюр с использованием аппарата', price: 3000, duration: 90 },
      { name: 'SPA-педикюр', description: 'Педикюр с уходом за кожей ног', price: 3500, duration: 120 }
    ]
  when 'elena.massage@example.com'
    services = [
      { name: 'Классический массаж', description: 'Расслабляющий массаж всего тела', price: 3000, duration: 60 },
      { name: 'Массаж спины', description: 'Специализированный массаж спины', price: 2000, duration: 45 },
      { name: 'SPA-массаж', description: 'Массаж с ароматическими маслами', price: 4000, duration: 90 }
    ]
  end
  
  services.each do |service_data|
    service = user.services.find_or_create_by(name: service_data[:name]) do |s|
      s.assign_attributes(service_data)
    end
    puts "  - Created service: #{service.name} (#{service.formatted_price})"
  end
end

puts "Seeds completed successfully!"
