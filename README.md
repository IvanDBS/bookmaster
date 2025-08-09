# BookMaster - Сервис онлайн-записи к мастерам

Современный веб-сервис для онлайн-записи к мастерам маникюра, педикюра и массажа. Построен на Ruby on Rails API и Vue.js.

## 🚀 Технологии

### Backend
- **Ruby on Rails 7.1** (API-only)
- **PostgreSQL** - база данных
- **Devise + JWT** - аутентификация
- **Pundit** - авторизация
- **Rack-CORS** - CORS поддержка

### Frontend (планируется)
- **Vue.js 3** (Composition API)
- **TailwindCSS** - стилизация
- **Vue Router** - маршрутизация
- **Pinia** - управление состоянием

## 📋 Функционал

### Для клиентов
- 📱 Просмотр каталога мастеров и услуг
- 📅 Онлайн-запись к мастерам
- 👤 Личный кабинет с историей записей
- 🔔 Уведомления о статусе записи

### Для мастеров
- 🛠️ Управление услугами (создание, редактирование, удаление)
- 📊 Просмотр и управление записями
- ✅ Подтверждение/отмена записей
- 📈 Статистика и аналитика

## 🏗️ Архитектура

```
bookmaster/
├── app/
│   ├── controllers/
│   │   └── api/v1/
│   │       ├── auth_controller.rb      # Аутентификация
│   │       ├── services_controller.rb  # Управление услугами
│   │       ├── bookings_controller.rb  # Бронирования
│   │       └── users_controller.rb     # Пользователи
│   ├── models/
│   │   ├── user.rb                     # Пользователи (мастера/клиенты)
│   │   ├── service.rb                  # Услуги
│   │   ├── booking.rb                  # Бронирования
│   │   └── jwt_denylist.rb            # JWT токены
│   └── views/
├── config/
│   ├── routes.rb                       # API маршруты
│   └── initializers/
│       ├── cors.rb                     # CORS настройки
│       └── devise.rb                   # Devise конфигурация
└── db/
    ├── migrate/                        # Миграции БД
    └── seeds.rb                        # Тестовые данные
```

## 🚀 Установка и запуск

### Требования
- Ruby 3.1.6+
- PostgreSQL
- Node.js (для фронтенда)

### Backend

1. **Клонирование и установка зависимостей**
```bash
git clone https://github.com/IvanDBS/bookmaster.git
cd bookmaster
bundle install
```

2. **Настройка базы данных**
```bash
rails db:create
rails db:migrate
rails db:seed
```

3. **Запуск сервера**
```bash
rails server
```

Сервер будет доступен по адресу: `http://localhost:3000`

## 📚 API Документация

### Базовый URL
```
http://localhost:3000/api/v1
```

### Аутентификация

#### Регистрация
```http
POST /auth/register
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "first_name": "Иван",
    "last_name": "Иванов",
    "phone": "+7 (999) 123-45-67",
    "role": "client"
  }
}
```

#### Вход
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### Профиль
```http
GET /auth/profile
Authorization: Bearer <JWT_TOKEN>
```

### Услуги

#### Получение списка услуг
```http
GET /services
```

#### Получение услуги
```http
GET /services/:id
```

#### Создание услуги (только для мастеров)
```http
POST /services
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "service": {
    "name": "Классический маникюр",
    "description": "Базовый маникюр с покрытием",
    "price": 1500,
    "duration": 60
  }
}
```

#### Обновление услуги
```http
PUT /services/:id
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "service": {
    "name": "Обновленное название",
    "price": 2000
  }
}
```

#### Удаление услуги
```http
DELETE /services/:id
Authorization: Bearer <JWT_TOKEN>
```

### Бронирования

#### Создание бронирования
```http
POST /bookings
Content-Type: application/json

{
  "booking": {
    "service_id": 1,
    "start_time": "2025-08-10T14:00:00Z",
    "client_name": "Анна Петрова",
    "client_email": "anna@example.com",
    "client_phone": "+7 (999) 123-45-67"
  },
  "master_id": 1
}
```

#### Получение списка бронирований
```http
GET /bookings
Authorization: Bearer <JWT_TOKEN>
```

#### Обновление статуса бронирования
```http
PATCH /bookings/:id/update_status
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "status": "confirmed"
}
```

### Пользователи

#### Получение списка мастеров
```http
GET /users
```

#### Получение профиля мастера
```http
GET /users/:id
```

#### Обновление профиля
```http
PUT /users/:id
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "user": {
    "first_name": "Новое имя",
    "last_name": "Новая фамилия",
    "phone": "+7 (999) 999-99-99",
    "bio": "Обновленная биография"
  }
}
```

## 🧪 Тестовые данные

После выполнения `rails db:seed` создаются тестовые мастера:

### Мастера
1. **Анна Петрова** (anna.manicure@example.com)
   - Классический маникюр - 1500 MDL (60 мин)
- Дизайн-маникюр - 2500 MDL (90 мин)
- SPA-маникюр - 2000 MDL (75 мин)

2. **Мария Сидорова** (maria.pedicure@example.com)
   - Классический педикюр - 2000 MDL (60 мин)
- Аппаратный педикюр - 3000 MDL (90 мин)
- SPA-педикюр - 3500 MDL (120 мин)

3. **Елена Козлова** (elena.massage@example.com)
   - Классический массаж - 3000 MDL (60 мин)
- Массаж спины - 2000 MDL (45 мин)
- SPA-массаж - 4000 MDL (90 мин)

**Пароль для всех тестовых аккаунтов:** `password123`

## 🔐 Роли пользователей

- **master** - мастера, могут создавать услуги и управлять записями
- **client** - клиенты, могут просматривать услуги и создавать записи

## 📝 Статусы бронирований

- **pending** - ожидает подтверждения
- **confirmed** - подтверждено
- **cancelled** - отменено
- **completed** - завершено

## 🛠️ Разработка

### Запуск тестов
```bash
rspec
```

### Линтинг
```bash
rubocop
```

### Миграции
```bash
rails db:migrate
```

### Консоль
```bash
rails console
```

## 📦 Следующие шаги

1. **Frontend разработка**
   - Создание Vue.js приложения
   - Интеграция с API
   - Реализация UI/UX

2. **Дополнительный функционал**
   - Календарь и расписание
   - Уведомления (email/SMS)
   - Оплата онлайн
   - Отзывы и рейтинги

3. **Деплой**
   - Настройка production окружения
   - CI/CD pipeline
   - Мониторинг и логирование

## 📄 Лицензия

MIT License

## 👥 Автор

Иван ДБС - [GitHub](https://github.com/IvanDBS)
