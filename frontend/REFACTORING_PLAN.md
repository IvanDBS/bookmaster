## Аудит проекта и дорожная карта к продакшену

### Критические проблемы (срочно)
- [РЕШЕНО] Seeds: guard по окружению исправлен, destructive операции выполняются только в `development`.
- [РЕШЕНО] JWT при регистрации: вызывается `sign_in user`, добавлен `POST /api/v1/auth/register` в `jwt.dispatch_requests`.
- [РЕШЕНО] Публичная выдача PII мастеров: публичные ответы урезаны до минимального набора полей (PII удалены). Пагинация отложена.
- [РЕШЕНО] Время слотов: в `TimeSlotsController` ответы унифицированы (ISO для `start_at/end_at`, `HH:MM` для `start_time/end_time`).
- [РЕШЕНО] `add_slot`: длительность берётся из расписания/последнего рабочего слота; проверки границ рабочего дня, lunch и пересечений добавлены.
- **Хранение токена в localStorage**: риск при XSS. [СДЕЛАНО частично] Добавлен глобальный обработчик 401 (очистка токена, редирект на `/login`). Для прод: перейти на httpOnly secure cookie + строгий CSP/HSTS.

  Ближайшие шаги (NEXT):
  - Frontend: добавить глобальный обработчик 401 в `frontend/src/services/api.js` (или общий fetch‑враппер) — при `response.status === 401`:
    1) вызывать `authStore.logout()` (очистка токена/состояния),
    2) редиректить на `/login`.
  - Backend (prod): подготовить схему cookie‑аутентификации: установка httpOnly secure cookie (SameSite=Lax/Strict) на `login/register/logout`, чтение токена из cookie.
  - Infra (prod): включить строгую Content‑Security‑Policy (CSP) и HSTS; запретить inline‑скрипты, разрешить только нужные источники.

### Высокий приоритет
- **Правила доступа при создании брони**: убедиться, что `BookingsController#create` соответствует бизнес‑правилу (кто может создавать: клиент/мастер/оба). При необходимости ограничить по роли.
- **Цепочка слотов для длительных услуг**: математика учитывает `service.duration` и `slot.duration_minutes`. Унифицировать вычисление следующего старта и проверки непрерывности/доступности строго внутри транзакции.
- [РЕШЕНО] Валидация пересечений слотов: упростили до `(start_a < end_b) AND (end_a > start_b)`.
- **Сократить утечки PII в логах**: для production включить Lograge, маскировку полей (email/phone), Sentry; понизить уровень подробности.
- **Пагинация и лимиты**: [отложено].
- **Тесты на критичные кейсы**: пересечения броней, генерация слотов (расписание/исключения), `add_slot` валидации, `update_status`, освобождение цепочки слотов при `destroy`/`cancelled`.
- [РЕШЕНО] Frontend мелкие правки: удалены лишние логи в `useServices`; в `useClientCalendar` вернули текущую дату.
 - [РЕШЕНО] Правила доступа: `BookingsController#create` ограничен для клиентов (`ensure_client!`).

### Средний приоритет
- **Единые сериализаторы**: использовать `ActiveModelSerializers` или Poro‑сериалайзеры для `Booking`, `TimeSlot`, `User`, `Service`, чтобы стандартизировать формат дат/полей.
- **CORS/HTTPS/CSP**: в проде отключить `credentials: true` при Bearer‑схеме или перейти на cookies; включить `force_ssl`, настроить CSP и HSTS.
- **Rate limiting**: `rack-attack` на `/auth/login`, `/auth/register`, публичные каталоги.
- **Индексы БД**: проверить индексы на `time_slots (user_id, date, start_time)`, `bookings (user_id, start_time)`; уникальность `working_schedules (user_id, day_of_week)` обеспечена валидатором — добавить unique‑index.
- **ACL/админка**: роль `admin`, базовая админка (RailsAdmin/ActiveAdmin) чтение/простые операции; аудит действий.
- **Уведомления**: email/SMS о создании/подтверждении/отмене. ActiveJob; в dev — async, в прод — Sidekiq.
- **I18n/временные зоны**: единые форматтеры на фронте (`useFormatters`); на бэке — все внешние времена в ISO/UTC.

### Низкий приоритет
- **Очистка зависимостей**: удалить неиспользуемые пакеты (например, `lucide-vue-next`, если не используется).
- **UX‑улучшения**: пустые состояния, скелетоны, фильтры, поиск по услугам/мастерам.
- **E2E**: сквозные сценарии: выбор мастера → дата → слот → бронь → подтверждение/отмена (Playwright/Cypress).

### Под будущие фичи (подготовка)
- **Редактирование слотов по длительности**: схема уже поддерживает `slot_duration_minutes` в `WorkingSchedule`. При обновлении — пересоздавать будущие слоты нужного дня недели (как сейчас делает `WorkingSchedulesController#update`), не трогая прошлые/забронированные; если конфликты — помечать и требовать ручной разбор.
- **Перенос записей**: эндпойнт «перенести» — в одной транзакции освободить старую цепочку и забронировать новую (с `with_lock` на новых слотах). UI: drag‑and‑drop/модалка выбора времени.
- **Админка**: роль `admin`, просмотр/управление пользователями, мастерами, слотами, логами; метрики.
- **Подтверждение почты**: включить Devise `:confirmable` + письмо при регистрации; опционально — ограничить логин до подтверждения.
- **Google аутентификация**: `omniauth-google-oauth2` для Devise; привязка к существующему email, redirect_uri через ENV; единая схема токенов с CORS.

### Конкретные места правок в коде
- **`db/seeds.rb`** — исправить guard и оставить destructive операции только в `development`.
- **`app/controllers/api/v1/auth_controller.rb`** — в `register` вызвать `sign_in user`; проверить `config/initializers/devise.rb` (`dispatch_requests`) на включение регистрации при необходимости.
- **`app/controllers/api/v1/users_controller.rb`** — сузить публичные поля, добавить пагинацию (`page/limit`) и базовые лимиты (совместно с rack-attack).
- **`app/controllers/api/v1/time_slots_controller.rb`** — унифицировать формат времени в ответах; усилить `add_slot` проверками границ рабочего дня и lunch.
- **`app/models/time_slot.rb`** — упростить валидацию пересечений до стандартного правила интервалов.
- **`frontend/src/composables/useClientCalendar.js`** — вернуть текущую дату.
- **`frontend/src/composables/useServices.js`** — убрать логи токена/пользователя.

Примеры точечных правок:

```ruby
# db/seeds.rb — начало файла
unless Rails.env.development?
  puts "[SEEDS] Skipping: destructive seeds are disabled outside development (env=#{Rails.env})"
  Rails.logger.debug { "[SEEDS] Destructive operations are disabled outside development (current: #{Rails.env}). Skipping." }
  return
end
```

```javascript
// frontend/src/composables/useClientCalendar.js
const currentDate = ref(new Date())
```

### Пошаговый план внедрения (1–2 недели)
- **День 0–1**: [ГОТОВО] seeds‑guard, JWT при регистрации, урезать PII в публичных users (пагинация отложена), унифицировать время в `time_slots` API, убрать dev‑логи, починить дату в `useClientCalendar`.
- **День 2–3**: [ГОТОВО] усилить `add_slot` валидации, переписать пересечения слотов. Далее: базовый rate limiting, привести логи к dev‑уровню (и план для prod: Lograge, маскирование).
- **День 4–5**: сериализаторы, CORS/SSL/CSP, индексы БД.
- **День 6–7**: тесты (RSpec) по ключевым кейсам, черновой E2E.
- **Далее**: редактирование длительности слотов, перенос записей, confirmable, Google OAuth, админка, уведомления.

### Выполнено дополнительно (инфра/безопасность)
- [РЕАЛИЗОВАНО] Rate limiting (dev‑подготовка): добавлен `rack-attack` с троттлингом `auth/login`, `auth/register`, `/api/v1/users`.
- [РЕАЛИЗОВАНО] Prod‑логи/безопасность: включён `force_ssl`, добавлен Lograge (JSON), базовые security‑заголовки; добавлены зависимости Sentry (`sentry-ruby`, `sentry-rails`).

### В рамках текущего спринта (готово)
- [ГОТОВО] Сериализация: добавлены `TimeSlotSerializer`, `UserPublicSerializer`; `UsersController`/`TimeSlotsController` переведены на сериализаторы.
- [ГОТОВО] Сериализация бронирований: `BookingPublicSerializer`; `BookingsController#index/show` отдают сериализованные данные.
- [ГОТОВО] Расширена фильтрация параметров логов: маскирование `authorization`, `password`, `password_confirmation`, `client_*`.
- [ГОТОВО] Инициализация Sentry (`config/initializers/sentry.rb`).
- [ГОТОВО] Единый формат ошибок API в `ApplicationController`.

### Следующие 5 задач
1) Сериализация private‑профиля `User` (полный набор полей для владельца) и рефактор контроллеров на выбор public/private.
2) Единый формат ошибок: пройтись по всем контроллерам (в т.ч. services, users, working_*), заменить локальные JSON‑ответы на унифицированный формат.
3) Набор RSpec‑тестов для критичных сценариев (роль в create, add_slot на границы/обед/конфликты, update_status confirmed/cancelled, destroy освобождение).
4) Интеграция Lograge параметров: маскировать и сужать payload параметров; убрать лишние PII/params из custom_options.
5) Подготовка CSP/HSTS (через `secure_headers` или на уровне reverse‑proxy) и чек‑лист переменных окружения для прод (SENTRY_DSN, CORS_ORIGINS, JWT secret, hostnames).
### Следующие 5 задач (без пагинации и «времени слотов»)
1) BookingsController#create: зафиксировать бизнес‑правило по ролям (кто создаёт бронь) и внедрить проверку роли + негативные кейсы.
2) Rate limiting (dev‑подготовка): подключить rack‑attack, лимиты на `/auth/login` и `/auth/register`, а также публичные каталоги.
3) Логи/наблюдаемость: включить Lograge в production, маскировать PII, подключить Sentry (DSN через ENV), базовые алерты на 5xx.
4) Сериализация: ввести сериализаторы (AMS/PORO) для `Booking`, `TimeSlot`, `User` (public/private профили), `Service` и перейти на них в контроллерах.
5) Безопасные заголовки и prod‑конфиг: подготовить `config/environments/production.rb` — `force_ssl`, базовый CSP (или `secure_headers`), HSTS; переменные окружения для ключей/доменов.

### Сделано (текущее состояние)
- `User#reconcile_bookings_with_slots_for_date` — не освобождаем заблокированные слоты.
- `BookingsController` — наследуется от `Api::V1::BaseController`; цепочка слотов по `service.duration`; `end_time` по длительности услуги.
- `WorkingSchedule#generate_slots_for_date` — использует `slot_duration_minutes`.
- Убран Pundit; приглушены избыточные логи.
- CORS читает `CORS_ORIGINS` из ENV.
- Централизация API фронта (`api.js`); базовый URL в `VITE_API_URL`.
- Удалён дублирующий экран `MasterDashboardRefactored.vue`.
- UI: глобальный шрифт Onest; улучшены календарь/кнопки/hover/focus.
- Frontend/useBookings: добавлен сигнал `refreshTick` для рефреша слотов после подтверждения/отмены записи; `MasterCalendar` слушает `refreshTick`; `ConfirmationModal` берёт цену из `useBookings.getSlotPrice`; `MasterTimeSlots` использует пропс `getStatusText`.
