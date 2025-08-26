#!/bin/bash

# Скрипт для запуска всех линтеров в проекте BookMaster

echo "🔍 Запуск линтеров для проекта BookMaster..."
echo ""

# Переходим в корневую директорию проекта
cd "$(dirname "$0")/.."

# Проверяем, что мы в правильной директории
if [ ! -f "docker-compose.dev.yml" ]; then
    echo "❌ Ошибка: Не найден файл docker-compose.dev.yml. Убедитесь, что вы находитесь в корневой директории проекта."
    exit 1
fi

echo "📁 Директория проекта: $(pwd)"
echo ""

# Запуск RuboCop для бэкенда
echo "🔧 Запуск RuboCop для бэкенда..."
cd backend
if bundle exec rubocop app lib spec --autocorrect-all; then
    echo "✅ RuboCop успешно завершен"
else
    echo "⚠️  RuboCop завершился с предупреждениями"
fi
echo ""

# Запуск ESLint для фронтенда
echo "🎨 Запуск ESLint для фронтенда..."
cd ../frontend
if npm run lint -- --fix; then
    echo "✅ ESLint успешно завершен"
else
    echo "⚠️  ESLint завершился с предупреждениями"
fi
echo ""

# Запуск Prettier для фронтенда
echo "💅 Запуск Prettier для фронтенда..."
if npm run format; then
    echo "✅ Prettier успешно завершен"
else
    echo "⚠️  Prettier завершился с предупреждениями"
fi
echo ""

echo "🎉 Все линтеры завершены!"
echo ""
echo "📊 Статистика:"
echo "   • RuboCop: Проверен бэкенд (Ruby/Rails)"
echo "   • ESLint: Проверен фронтенд (Vue.js/JavaScript)"
echo "   • Prettier: Отформатирован фронтенд"
echo ""
echo "💡 Совет: Запускайте этот скрипт перед коммитом для поддержания качества кода."
