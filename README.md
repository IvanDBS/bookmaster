# BookMaster - Запись к мастерам

Веб-приложение для мастеров и клиентов: бесплатное бронирование и учёт записей в одном месте!

## 🚀 Старт

```bash
git clone https://github.com/IvanDBS/bookmaster.git
cd bookmaster

# Запуск в Docker
./start-dev.sh

# Настройка БД
docker compose -f docker-compose.dev.yml exec web rails db:create db:migrate db:seed
```

## 🔧 Стек

- **Backend:** Ruby 3.3.0, Rails 8.0.2.1, PostgreSQL
- **Frontend:** Vue 3, TailwindCSS, Pinia
- **DevOps:** Docker, Docker Compose

## 📁 Структура

```
bookmaster/
├── backend/          # Rails API
├── frontend/         # Vue.js SPA
├── shared/           # Общие типы и утилиты
├── scripts/          # Скрипты развертывания
└── docker-compose.yml
```

## 🔒 Безопасность

- ✅ Rate Limiting (защита от DDoS)
- ✅ CSRF Protection
- ✅ XSS Protection  
- ✅ GDPR Compliance
- ✅ Data Isolation
- ✅ Race Condition Protection
- ✅ JWT с httpOnly cookies
- ✅ Input Validation
- ✅ Security Monitoring

## 🔐 Переменные окружения

Скопируйте `env.example` в `env.development` для разработки:

```bash
cp env.example env.development
# Отредактируйте env.development с вашими данными
```

## 🚀 Развертывание

### Development
```bash
./start-dev.sh
```

### Production
```bash
./start-prod.sh
```

## 📊 Мониторинг

```bash
# Security audit
cd backend && bundle exec rake security:audit

# Check logs
cd backend && bundle exec rake security:check_logs

# Generate report
cd backend && bundle exec rake security:report
```

## 📄 Лицензия

MIT License - см. файл [LICENSE](LICENSE)
