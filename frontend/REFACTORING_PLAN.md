Критический аудит: актуальные проблемы

Бэкенд/модель бронирований
- Дублирующая/избыточная проверка в Booking#no_time_conflicts — упростить до (start_time < other_end) AND (end_time > other_start).
- Несогласованность статусов: в логике встречается 'deleted', но модель ограничена pending/confirmed/cancelled/completed — привести к единообразию.
- Booking#set_end_time жёстко +60 мин — нужна привязка к service.duration или снятие коллбека (сейчас end_time задаётся в контроллере).
- TimeSlotsController#add_slot — нет валидации границ рабочего дня/обеда.

Тайм-слоты и представление времени
- Неконсистентный формат времени (местами HH:MM, местами ISO). Нужна единая стратегия (рекомендовано ISO + явные форматтеры на фронте).

Фронтенд/архитектура
- Дублирование логики календаря — стоит вынести общее в utils (цвета/классы/подсчёты) и/или объединить базовую часть composables.
- useBookings: упростить API (без передачи внешних ref), добавить событие/сигнал для рефреша слотов после изменения статуса. [СДЕЛАНО частично: добавлен сигнал refreshTick, календарь слушает и вызывает refreshCalendar]
- Форматтеры дат/статусов размазаны по компонентам — вынести в общий модуль.
- Проверить .value в шаблонах и типы пропсов (например, pending count в AppHeader).

Конфигурация/инфра
- Seeds: защитить destructive операции (только development).
- Настроить Rails.credentials для JWT в окружениях.
- Ввести rate limiting (Rack::Attack) и базовый audit-log.

Тесты
- RSpec: пересечения брони, генерация слотов (расписание/исключения), блокировки, обновление статусов.
- E2E (Playwright/Cypress): выбор мастера → дата → слот → бронь → подтверждение/отмена.

Сделано сегодня
- User#reconcile_bookings_with_slots_for_date — больше не освобождаем заблокированные слоты.
- BookingsController — наследуется от Api::V1::BaseController; цепочка слотов по service.duration; установка end_time по длительности услуги.
- WorkingSchedule#generate_slots_for_date — используется slot_duration_minutes.
- Pundit удалён; обработчики избыточных логов приглушены.
- CORS — чтение из ENV (CORS_ORIGINS).
- API-слой фронта централизован (api.js); базовый URL вынесен в VITE_API_URL.
- Удалён дублирующий экран MasterDashboardRefactored.vue.
- UI: глобальный шрифт Onest; улучшены календарь/кнопки/hover/focus.
 - Frontend/useBookings: добавлен сигнал `refreshTick` для рефреша слотов после подтверждения/отмены записи.
 - MasterCalendar: принимает `refreshTick` и вызывает `refreshCalendar()` при его изменении.
 - ConfirmationModal: цена берётся из `useBookings.getSlotPrice` (исправлен кейс «0 MDL»).
 - MasterTimeSlots: удалён дублирующий `getStatusText`, используется пропс из родителя.
 - MasterDashboard: передаёт `getSlotPrice` и `refreshTick` вниз в календарь/модалку.

TODO на завтра (по приоритету)

Высокий
1) Booking#set_end_time — привязать к service.duration или убрать коллбек во избежание конфликтов.
2) Booking#no_time_conflicts — переписать на единое условие пересечения, покрыть тестами.
3) TimeSlotsController#add_slot — валидация границ рабочего дня и обеда (не выходить за schedule, не попадать в lunch).
4) Формат времени в API — привести приватные эндпойнты к единому ISO-формату; обновить фронтовые форматтеры.

Средний
5) UsersController — привести к наследованию от Api::V1::BaseController.
6) Вынести общую календарную логику (классы/цвета/подсчёты) в utils; сократить дубли между useCalendar/useMasterCalendar.
7) useBookings — упростить API (без внешних ref), добавить событие/сигнал для рефреша слотов после confirm/cancel. [частично: сигнал реализован]
8) Вынести форматтеры дат/статусов во фронте в общий модуль; пройтись по .value в шаблонах; проверить типы пропсов (AppHeader pending count). [в прогрессе: часть форматтеров сведена в `useBookings`]
9) Seeds — ограничить destructive действия только development.
10) Rails.credentials — настроить ключи JWT для окружений.

Низкий
11) Rate limiting (Rack::Attack) и audit-log.
12) RSpec покрытие ключевых кейсов; зачаток E2E (Playwright/Cypress).
13) Удалить неиспользуемые зависимости (lucide-vue-next), если действительно не используются.
