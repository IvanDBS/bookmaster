# BookMaster - Запись к мастерам

Веб-приложение для мастеров и клиентов: бесплатное бронирование и учёт записей в одном месте!

## 🚀 Старт

```bash
git clone https://github.com/IvanDBS/Book-master.git
cd Book-master

# Запуск в Docker
./start-dev.sh

# Настройка БД
docker compose exec web rails db:create db:migrate db:seed
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
└── docker-compose.yml
```

## 🔒 Безопасность

- ✅ Rate Limiting (защита от DDoS)
- ✅ CSRF Protection
- ✅ XSS Protection  
- ✅ GDPR Compliance
- ✅ Data Isolation
- ✅ Race Condition Protection


## 🔐 Переменные окружения

Скопируйте `env.example` в `.env` и настройте:

```bash
cp env.example .env
# Отредактируйте .env с вашими данными
```


## 📄 Лицензия

MIT License - см. файл [LICENSE](LICENSE)
