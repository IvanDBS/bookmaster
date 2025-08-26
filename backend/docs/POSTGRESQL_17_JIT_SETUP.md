# PostgreSQL 17 с JIT настройка

## Обзор изменений

Проект обновлен для использования PostgreSQL 17 с включенным JIT (Just-In-Time) компилятором для улучшения производительности запросов.

## Что изменилось

### 1. Обновление версии PostgreSQL
- **Development**: `postgres:16-alpine` → `postgres:17-alpine`
- **Production**: `postgres:15-alpine` → `postgres:17-alpine`

### 2. Настройки JIT
Включены следующие параметры JIT:
- `jit = on` - включение JIT компиляции
- `jit_provider = llvmjit` - использование LLVM как JIT провайдера
- `jit_above_cost = 100000` - порог стоимости для включения JIT
- `jit_inline_above_cost = 500000` - порог для инлайнинга функций
- `jit_optimize_above_cost = 500000` - порог для оптимизации

### 3. Мониторинг производительности
- `shared_preload_libraries = pg_stat_statements` - загрузка расширения для статистики
- `pg_stat_statements.track = all` - отслеживание всех запросов

### 4. Оптимизация производительности (Production)
Дополнительные настройки для production:
- `max_connections = 200`
- `shared_buffers = 256MB`
- `effective_cache_size = 1GB`
- `maintenance_work_mem = 64MB`
- `checkpoint_completion_target = 0.9`
- `wal_buffers = 16MB`
- `default_statistics_target = 100`
- `random_page_cost = 1.1`
- `effective_io_concurrency = 200`

## Запуск с новыми настройками

### Development
```bash
# Остановить существующие контейнеры
docker-compose -f docker-compose.dev.yml down

# Удалить старые volumes (если нужно)
docker-compose -f docker-compose.dev.yml down -v

# Запустить с новыми настройками
docker-compose -f docker-compose.dev.yml up -d

# Проверить статус JIT
docker-compose -f docker-compose.dev.yml exec web bundle exec rake postgresql:check_jit
```

### Production
```bash
# Остановить существующие контейнеры
docker-compose -f docker-compose.prod.yml down

# Запустить с новыми настройками
docker-compose -f docker-compose.prod.yml up -d

# Проверить статус JIT
docker-compose -f docker-compose.prod.yml exec web bundle exec rake postgresql:check_jit
```

## Проверка JIT статуса

### Rake задачи
```bash
# Проверить версию PostgreSQL и статус JIT
bundle exec rake postgresql:check_jit

# Показать статистику использования JIT
bundle exec rake postgresql:jit_stats

# Тест производительности JIT
bundle exec rake postgresql:test_jit
```

### SQL запросы
```sql
-- Проверить настройки JIT
SELECT name, setting, unit, context 
FROM pg_settings 
WHERE name LIKE 'jit%'
ORDER BY name;

-- Проверить провайдера JIT
SELECT name, setting 
FROM pg_settings 
WHERE name = 'jit_provider';

-- Проверить доступные провайдеры
SELECT name, setting 
FROM pg_settings 
WHERE name = 'jit_available_providers';
```

## Преимущества JIT

1. **Ускорение сложных запросов**: JIT компилирует части запросов в машинный код
2. **Оптимизация агрегаций**: Улучшает производительность GROUP BY, HAVING, ORDER BY
3. **Ускорение вычислений**: Оптимизирует математические операции и функции
4. **Лучшая производительность**: Особенно заметно на запросах с большими объемами данных

## Мониторинг

### pg_stat_statements
Расширение `pg_stat_statements` позволяет отслеживать:
- Время выполнения запросов
- Количество вызовов
- Статистику использования ресурсов

### Просмотр статистики
```sql
-- Топ запросов по времени выполнения
SELECT 
    query,
    calls,
    total_time,
    mean_time
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;
```

## Troubleshooting

### JIT не работает
1. Проверьте, что LLVM установлен в контейнере
2. Убедитесь, что `jit = on` в настройках
3. Проверьте доступные провайдеры: `SHOW jit_available_providers;`

### Низкая производительность
1. Проверьте настройки памяти (`shared_buffers`, `effective_cache_size`)
2. Убедитесь, что статистика актуальна: `ANALYZE;`
3. Проверьте план выполнения запроса: `EXPLAIN (ANALYZE) ...`

### Ошибки при запуске
1. Проверьте логи PostgreSQL: `docker-compose logs db`
2. Убедитесь, что все параметры корректны
3. Проверьте совместимость версии гема `pg` с PostgreSQL 17

## Миграция данных

При обновлении с PostgreSQL 15/16 до 17:
1. Создайте резервную копию данных
2. Обновите конфигурацию
3. Восстановите данные в новую версию
4. Проверьте целостность данных

```bash
# Создание резервной копии
docker-compose exec db pg_dump -U postgres bookmaster_development > backup.sql

# Восстановление
docker-compose exec -T db psql -U postgres bookmaster_development < backup.sql
```
