#!/bin/bash

# Скрипт для обновления PostgreSQL до версии 17 с JIT
# Использование: ./scripts/upgrade_postgresql_17.sh [dev|prod]

set -e

ENVIRONMENT=${1:-dev}
COMPOSE_FILE="docker-compose.${ENVIRONMENT}.yml"

echo "🚀 Обновление PostgreSQL до версии 17 с JIT для окружения: $ENVIRONMENT"

# Проверка существования файла docker-compose
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ Файл $COMPOSE_FILE не найден"
    exit 1
fi

# Создание резервной копии
echo "📦 Создание резервной копии данных..."
BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"

if [ "$ENVIRONMENT" = "dev" ]; then
    docker-compose -f $COMPOSE_FILE exec -T db pg_dump -U postgres bookmaster_development > $BACKUP_FILE
elif [ "$ENVIRONMENT" = "prod" ]; then
    docker-compose -f $COMPOSE_FILE exec -T db pg_dump -U postgres bookmaster_production > $BACKUP_FILE
fi

echo "✅ Резервная копия создана: $BACKUP_FILE"

# Остановка контейнеров
echo "🛑 Остановка контейнеров..."
docker-compose -f $COMPOSE_FILE down

# Удаление старых volumes (опционально)
read -p "Удалить старые volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️ Удаление старых volumes..."
    docker-compose -f $COMPOSE_FILE down -v
fi

# Обновление гемов
echo "💎 Обновление гемов..."
cd backend
bundle update pg
cd ..

# Запуск с новыми настройками
echo "🚀 Запуск с PostgreSQL 17..."
docker-compose -f $COMPOSE_FILE up -d

# Ожидание готовности базы данных
echo "⏳ Ожидание готовности базы данных..."
sleep 10

# Проверка версии PostgreSQL
echo "🔍 Проверка версии PostgreSQL..."
VERSION=$(docker-compose -f $COMPOSE_FILE exec -T db psql -U postgres -t -c "SELECT version();" | head -1)
echo "📊 Версия PostgreSQL: $VERSION"

# Проверка JIT статуса
echo "🔍 Проверка JIT статуса..."
docker-compose -f $COMPOSE_FILE exec web bundle exec rake postgresql:check_jit

# Восстановление данных (если нужно)
if [ -f "$BACKUP_FILE" ]; then
    read -p "Восстановить данные из резервной копии? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📥 Восстановление данных..."
        if [ "$ENVIRONMENT" = "dev" ]; then
            docker-compose -f $COMPOSE_FILE exec -T db psql -U postgres bookmaster_development < $BACKUP_FILE
        elif [ "$ENVIRONMENT" = "prod" ]; then
            docker-compose -f $COMPOSE_FILE exec -T db psql -U postgres bookmaster_production < $BACKUP_FILE
        fi
        echo "✅ Данные восстановлены"
    fi
fi

# Запуск миграций
echo "🔄 Запуск миграций..."
docker-compose -f $COMPOSE_FILE exec web bundle exec rails db:migrate

# Финальная проверка
echo "✅ Финальная проверка..."
docker-compose -f $COMPOSE_FILE exec web bundle exec rake postgresql:test_jit

echo "🎉 Обновление PostgreSQL до версии 17 с JIT завершено!"
echo "📋 Для проверки статуса используйте: docker-compose -f $COMPOSE_FILE exec web bundle exec rake postgresql:check_jit"
