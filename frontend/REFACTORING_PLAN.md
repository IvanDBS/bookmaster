Критический аудит: проблемы и риски
Бэкенд/модель бронирований
Дублирующая/избыточная проверка пересечений в Booking#no_time_conflicts: условие можно свести к одному выражению (риск ложных срабатываний).
Несогласованность статусов: в коде встречается 'deleted' при синхронизации слотов (User#reconcile_bookings_with_slots_for_date), но валидные статусы модели ограничены pending/confirmed/cancelled/completed. Это приводит к логическим расхождениям.
Жёсткая фиксация длительности 60 минут:
Booking#set_end_time всегда +60 мин.
WorkingSchedule#generate_slots_for_date игнорирует slot_duration_minutes, использует 60.
BookingsController#create цепочку слотов считает от 60 минут, а не от service.duration. Из-за этого длинные услуги бронируются неправильно.
Потеря ручных блокировок: User#reconcile_bookings_with_slots_for_date освобождает все слоты на дату без исключений для slot_type='blocked' → вручную заблокированные слоты становятся доступными.
TimeSlotsController#add_slot: не проверяет границы рабочего дня/расписания и окно обеда. Риск выхода за график и создание слота в обед.
Непоследовательная иерархия контроллеров:
BookingsController наследуется от ApplicationController, в то время как остальные API-контроллеры используют Api::V1::BaseController с единым authenticate_user!. Желательно унифицировать.
Авторизация: pundit подключен, но политики отсутствуют; фактически используются ручные проверки (ensure_master!). Либо добавить политики, либо убрать pundit.
Логирование: чрезмерно подробное в проде (много Rails.logger.info), потребуется снизить уровень.
Тайм-слоты и расписание
Неконсистентное представление времени: местами сериализуется '%H:%M', местами отдаются Time (ISO), фронту приходится гадать по includes('T').
Индексы и уникальность — ок, но необходимо уделить внимание TZ: используются Time.zone.parse('2000-01-01 HH:MM') и поля типа time в PostgreSQL; в целом валидно, но важно единообразно форматировать на API.
Фронтенд/дублирование и архитектура
Дублирование календарной логики и утилит:
useCalendar.js и useMasterCalendar.js почти идентичны (генерация сетки, цвета, вычисления статуса дня, кэш), а также дублирование в MasterTimeSlots.vue (статусы/тексты/классы).
Дублирующие экраны:
Два дашборда мастера — MasterDashboard.vue и MasterDashboardRefactored.vue с разными наборами компонентов (старый Calendar vs новый MasterCalendar). Это несёт долги и риск рассинхронизации.
useBookings.js:
Функция loadBookingsForDate(date, selectedDateBookings) конфликтна по API: передаётся внешняя ref, при этом есть внутренняя selectedDateBookings. Лучше возвращать отфильтрованный список, а состояние вести внутри composable.
Форматтеры дат/статусов дублируются по компонентам — нужен единый util.
После подтверждения/отмены записи нет явной синхронизации слотов календаря (UI может не обновиться). На бэке запускается reconcile, но фронт не делает refetch слотов.
Разный способ вызовов API:
Есть общий frontend/src/services/api.js, но в ряде мест всё ещё прямой fetch с хардкодом URL. Это усложнит смену базового URL.
Шаблоны Vue:
В MasterDashboard.vue много обращений к ref с .value в шаблонах — Vue 3 сам разворачивает ссылки в шаблонах, это шум и потенциальная путаница.
Передача pendingBookingsCount как bookings.pendingBookingsCount.value в AppHeader — проверьте проп-тип (ожидается число, не ref).
Жёстко прошитые URL http://localhost:3000 в нескольких местах — нужно вынести в VITE_API_URL.
Конфигурация/инфра
CORS: хардкод источников. Для продакшна — вынести в ENV.
Devise JWT: секрет берётся из Rails.application.credentials.secret_key_base. Нужна настройка cred в окружениях.
Seeds: агрессивные destroy_all для всех таблиц. Следует обернуть в Rails.env.development? или флаг.
Тесты: RSpec присутствует, есть TODO и комментированный тест в spec/models/booking_spec.rb. Требуется добить покрытие для критичных кейсов (бронь/слоты/исключения).
Прочее
Неприменяемые зависимости: pundit без политик; lucide-vue-next задекларирован в корневом package.json, но на фронте не используется.
I18n: тексты на русском размазаны по коду, лучше вынести в локали.
Рекомендованные правки (приоритет)
1) Бронь и слоты: корректность и консистентность
В BookingsController#create: считать цепочку слотов по service.duration, а не 60. Исправить required_slots = (service.duration.to_f / slot.duration_minutes).ceil.
В Booking#set_end_time: учитывайте service.duration (или снимите коллбек и дайте контроллеру/сервису выставлять end_time из start_time + service.duration).
В User#reconcile_bookings_with_slots_for_date: не “освобождать” blocked слоты. Исключить slot_type='blocked' из update_all.
В WorkingSchedule#generate_slots_for_date: использовать slot_duration_minutes вместо жёстких 60.
В TimeSlotsController#add_slot: проверить соответствие рабочего времени (используя расписание/исключения), не создавать вне schedule.end_time и не попадать в обед.
В Booking#no_time_conflicts: упростить условие на пересечение до (start_time < other_end) AND (end_time > other_start).
Убрать упоминание 'deleted' или добавить статус в список валидных и учесть в логике единообразно.
2) Единый API-слой и серилизация времени
Везде использовать api.js вместо прямых fetch.
Вынести API_BASE_URL в VITE_API_URL; обновить CORS origins через ENV.
Унифицировать формат времени в API:
На приватных эндпойнтах возвращать HH:MM или ISO — но одинаково везде. Рекомендую ISO + явные клиентские форматтеры.
3) Контроллеры/авторизация/база
Привести BookingsController к наследованию от Api::V1::BaseController, стандартизировать обработку ошибок/аутентификацию.
Определиться с pundit: либо добавить политики (ServicePolicy, TimeSlotPolicy, BookingPolicy), либо удалить gem и rescue.
Снизить уровень логирования в проде; оставить ключевые warn/error.
4) Фронтенд: устранить дубли и добить рефакторинг
Завершить начатый рефакторинг: удалить дубли в MasterDashboardRefactored.vue или перевести роут целиком на новый стек MasterCalendar и useMasterCalendar. Это согласуется с вашим планом миграции 1.
Объединить логику календаря:
Вынести общие функции (getDateBgClass, getDateBorderClass, getSlotStatusText/Class) в отдельный calendarUtils.js.
Свести useCalendar и useMasterCalendar к одному composable с параметром режима (master|client), либо оставить два, но базовую часть вынести в общую утилиту.
useBookings:
Упростить API: loadBookingsForDate(date) возвращает массив, внутреннее состояние — без передачи внешней ref.
После handleModalConfirm инициировать обновление слотов выбранной даты (emit событие или экспортировать сигнал), чтобы календарь мгновенно обновлялся.
Вынести форматтеры дат/статусов в общий утилитарный модуль, переиспользовать в BookingCard, MasterTimeSlots.
Пройтись по шаблонам и убрать .value в темплейтах; убедиться, что AppHeader получает числа, не ref.
5) Конфиги и безопасность
VITE_API_URL, CORS_ORIGINS → ENV.
В seeds.rb — обернуть destructive seed в Rails.env.development?.
Настроить Rails.credentials для JWT в всех окружениях.
Добавить rate limit на авторизацию (Rack Attack) и базовый audit лог.
6) Тесты и качество
Добить RSpec:
Пересечения брони, генерация слотов по расписанию/исключениям, блокировки, обновление статусов.
E2E (Playwright/Cypress) на клиентский флоу: выбор мастера → день → слот → бронь → подтверждение/отмена.
ESLint/Prettier: прогнать автофикс. Рефакторинг импорта lucide-vue-next или удалить зависимость.
Быстрые фиксы (точечные)
Исправить длительности и цепочки слотов:
BookingsController#create: required_slots от service.duration.
Booking#set_end_time: от service.duration (или убрать коллбек).
WorkingSchedule#generate_slots_for_date: использовать slot_duration_minutes.
Сохранить ручные блокировки:
В reconcile_bookings_with_slots_for_date не трогать slot_type='blocked'.
Упростить пересечения:
Booking#no_time_conflicts — одно условие пересечения.
Убрать 'deleted' из reconcile или добавить в валидации.
План запуска (итерации)
Итерация 1: корректность домена
Правки длительностей/цепочек и корректная синхронизация слотов.
Упростить валидацию пересечений.
Нормализация сериализации времени.
Smoke-тесты API + фронт подтверждение/отмена.
Итерация 2: фронт-рефакторинг
Дедупликация composables/утилит.
Удаление MasterDashboardRefactored.vue или полное переключение на новый календарь.
Централизация всех запросов через api.js.
Вынесение VITE_API_URL.
Итерация 3: авторизация и конфиги
Унифицировать базовый контроллер для всех API.
Определиться с pundit.
CORS/credentials через ENV.
Итерация 4: тестирование и полировка
RSpec для критичных путей, E2E для клиентского флоу.
Логи/локализация/чистка зависимостей.
CI: lint, тесты, билд фронта.
Рекомендации по задачам (конкретные файлы)
Бэкенд
app/controllers/api/v1/bookings_controller.rb: required_slots по service.duration; формирование end_time от сервиса.
app/models/booking.rb: переписать no_time_conflicts.
app/models/user.rb: в reconcile_bookings_with_slots_for_date исключить blocked.
app/models/working_schedule.rb: использовать slot_duration_minutes.
app/controllers/api/v1/time_slots_controller.rb: в add_slot валидировать пределы рабочего дня и обеда.
app/controllers/api/v1/bookings_controller.rb и app/controllers/api/v1/users_controller.rb: наследоваться от Api::V1::BaseController.
Фронтенд
frontend/src/services/api.js: API_BASE_URL → import.meta.env.VITE_API_URL.
Поиск и замена прямых fetch → методы из api.js.
Вынести форматтеры в src/utils/datetime.js и src/utils/status.js.
Объединить/удалить MasterDashboardRefactored.vue.
Привести useBookings.js к чистому API и оповещению календаря.
Конфиги
config/initializers/cors.rb: читать ENV['CORS_ORIGINS'].
seeds.rb: if Rails.env.development?.
Короткий статус
Провёл полный просмотр моделей/контроллеров/сериалайзеров/роутов/миграций/seed, ключевых Vue-компонентов и composables. Выявил критичные логические баги (длительность услуг/цепочки слотов, сброс блокировок), крупные дубли, конфиг-проблемы и несоответствия.
Основные правки:
Исправить расчёт длительностей и не ломать блокировки.
Упростить валидацию пересечений.
Унифицировать слои (API/время/базовый контроллер).
Убрать дубли фронта и централизовать API.
Вынести конфиги в ENV, защитить сиды, добавить тесты.
Если хотите, могу сразу сделать правки из “Быстрых фиксов” и подготовить MR.