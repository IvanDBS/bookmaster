import { computed } from 'vue'

export function useSanitization() {
  // Функция для экранирования HTML
  const escapeHtml = (text) => {
    if (!text || typeof text !== 'string') return text

    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  // Функция для санитизации текста (удаление HTML тегов)
  const sanitizeText = (text) => {
    if (!text || typeof text !== 'string') return text

    // Удаляем все HTML теги
    return text.replace(/<[^>]*>/g, '')
  }

  // Функция для валидации и санитизации имени
  const sanitizeName = (name) => {
    if (!name || typeof name !== 'string') return ''

    // Удаляем HTML теги и ограничиваем длину
    const sanitized = sanitizeText(name).trim()
    return sanitized.substring(0, 100) // Максимум 100 символов
  }

  // Функция для валидации и санитизации email
  const sanitizeEmail = (email) => {
    if (!email || typeof email !== 'string') return ''

    // Простая валидация email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    const sanitized = sanitizeText(email).trim().toLowerCase()

    return emailRegex.test(sanitized) ? sanitized : ''
  }

  // Функция для валидации и санитизации телефона
  const sanitizePhone = (phone) => {
    if (!phone || typeof phone !== 'string') return ''

    // Оставляем только цифры, пробелы, скобки, дефисы и плюс
    const sanitized = phone.replace(/[^\d\s()\-+]/g, '').trim()
    return sanitized.substring(0, 20) // Максимум 20 символов
  }

  // Функция для санитизации описания
  const sanitizeDescription = (description) => {
    if (!description || typeof description !== 'string') return ''

    // Удаляем HTML теги и ограничиваем длину
    const sanitized = sanitizeText(description).trim()
    return sanitized.substring(0, 500) // Максимум 500 символов
  }

  // Функция для санитизации цены
  const sanitizePrice = (price) => {
    if (price === null || price === undefined) return 0

    const num = Number(price)
    if (Number.isNaN(num) || num < 0) return 0

    return Math.round(num)
  }

  // Функция для валидации ID
  const validateId = (id) => {
    if (!id) return false
    const num = Number(id)
    return !Number.isNaN(num) && num > 0 && Number.isInteger(num)
  }

  // Функция для валидации даты
  const validateDate = (date) => {
    if (!date) return false
    const dateObj = new Date(date)
    return !Number.isNaN(dateObj.getTime())
  }

  // Функция для валидации времени
  const validateTime = (time) => {
    if (!time) return false
    const timeRegex = /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/
    return timeRegex.test(time)
  }

  // Функция для санитизации объекта пользователя
  const sanitizeUser = (user) => {
    if (!user || typeof user !== 'object') return null

    return {
      id: validateId(user.id) ? user.id : null,
      email: sanitizeEmail(user.email),
      first_name: sanitizeName(user.first_name),
      last_name: sanitizeName(user.last_name),
      phone: sanitizePhone(user.phone),
      role: user.role,
      bio: sanitizeDescription(user.bio),
      address: sanitizeDescription(user.address),
    }
  }

  // Функция для санитизации объекта услуги
  const sanitizeService = (service) => {
    if (!service || typeof user !== 'object') return null

    return {
      id: validateId(service.id) ? service.id : null,
      name: sanitizeName(service.name),
      description: sanitizeDescription(service.description),
      price: sanitizePrice(service.price),
      duration: sanitizePrice(service.duration),
      service_type: sanitizeText(service.service_type),
    }
  }

  // Функция для санитизации объекта бронирования
  const sanitizeBooking = (booking) => {
    if (!booking || typeof booking !== 'object') return null

    return {
      id: validateId(booking.id) ? booking.id : null,
      client_name: sanitizeName(booking.client_name),
      client_email: sanitizeEmail(booking.client_email),
      client_phone: sanitizePhone(booking.client_phone),
      status: booking.status,
      start_time: validateDate(booking.start_time) ? booking.start_time : null,
      end_time: validateDate(booking.end_time) ? booking.end_time : null,
      service: booking.service ? sanitizeService(booking.service) : null,
      user: booking.user ? sanitizeUser(booking.user) : null,
    }
  }

  // Computed свойства для безопасного отображения
  const safeText = (text) => computed(() => escapeHtml(sanitizeText(text)))
  const safeName = (name) => computed(() => escapeHtml(sanitizeName(name)))
  const safeEmail = (email) => computed(() => escapeHtml(sanitizeEmail(email)))
  const safePhone = (phone) => computed(() => escapeHtml(sanitizePhone(phone)))
  const safeDescription = (description) =>
    computed(() => escapeHtml(sanitizeDescription(description)))

  return {
    // Функции санитизации
    escapeHtml,
    sanitizeText,
    sanitizeName,
    sanitizeEmail,
    sanitizePhone,
    sanitizeDescription,
    sanitizePrice,
    sanitizeUser,
    sanitizeService,
    sanitizeBooking,

    // Функции валидации
    validateId,
    validateDate,
    validateTime,

    // Computed свойства для безопасного отображения
    safeText,
    safeName,
    safeEmail,
    safePhone,
    safeDescription,
  }
}
