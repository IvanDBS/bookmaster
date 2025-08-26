const API_BASE_URL =
  typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.VITE_API_URL
    ? import.meta.env.VITE_API_URL.replace(/\/?$/, '')
    : 'http://localhost:3000/api/v1'

class ApiService {
  constructor() {
    this.baseURL = API_BASE_URL
  }

  // Global 401 handler for protected requests
  handleUnauthorized = async () => {
    if (typeof window !== 'undefined') {
      // Сообщаем приложению о 401, чтобы Pinia-store выполнил корректный logout
      window.dispatchEvent(new CustomEvent('api:unauthorized'))
    }
  }

  // Helper для включения credentials в запросы
  getRequestOptions(options = {}) {
    return {
      credentials: 'include', // Включаем cookies в запросы
      ...options,
    }
  }

  // Unified request helper: handles 401, parses JSON safely, normalizes error messages
  async requestJson(url, init = {}) {
    const response = await fetch(url, this.getRequestOptions(init))
    const rawText = await response.text().catch(() => '')
    const json = rawText ? JSON.parse(rawText) : {}

    if (response.status === 401) {
      await this.handleUnauthorized()
      const err = new Error(json?.error || json?.message || 'Unauthorized')
      err.status = 401
      throw err
    }

    if (!response.ok) {
      const message =
        (typeof json?.error === 'string'
          ? json.error
          : json && json.error && (json.error.message || json.error.code)) ||
        (Array.isArray(json?.errors) ? json.errors.join(', ') : null) ||
        json?.message ||
        `Request failed with status ${response.status}`
      const err = new Error(message)
      err.status = response.status
      throw err
    }

    return json
  }

  // Helpers
  buildUrl(path, params = null) {
    // Если baseURL уже полный URL, используем его, иначе добавляем к текущему домену
    let baseUrl = this.baseURL
    if (!baseUrl.startsWith('http')) {
      // Безопасно получаем origin
      const origin = typeof window !== 'undefined' && window.location ? window.location.origin : ''
      baseUrl = `${origin}${this.baseURL}`
    }

    // Проверяем, что у нас есть валидный URL
    if (!baseUrl || baseUrl === 'undefined') {
      baseUrl = '/api/v1' // fallback
    }

    const url = new URL(`${baseUrl}${path}`)
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined && value !== null && value !== '') {
          url.searchParams.set(key, value)
        }
      })
    }
    return url.toString()
  }

  // Auth endpoints
  async login(email, password) {
    const response = await fetch(
      `${this.baseURL}/auth/login`,
      this.getRequestOptions({
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user: { email, password } }),
      }),
    )

    const data = await response.json().catch(() => ({}))

    if (!response.ok) {
      const message =
        typeof data.error === 'string'
          ? data.error
          : (data && data.error && (data.error.message || data.error.code)) ||
            data.message ||
            (Array.isArray(data?.errors) ? data.errors.join(', ') : null) ||
            'Ошибка входа'
      throw new Error(message)
    }

    return data
  }

  async register(userData) {
    // Не отправляем служебные поля формы (например, terms)
    const sanitized = { ...(userData || {}) }
    delete sanitized.terms
    const response = await fetch(
      `${this.baseURL}/auth/register`,
      this.getRequestOptions({
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user: sanitized }),
      }),
    )

    const data = await response.json().catch(() => ({}))

    if (!response.ok) {
      const message =
        (Array.isArray(data?.errors) ? data.errors.join(', ') : null) ||
        (data && data.error && (data.error.message || data.error.code)) ||
        data.message ||
        (typeof data.error === 'string' ? data.error : null) ||
        'Registration failed'
      const err = new Error(message)
      err.status = response.status
      throw err
    }

    return data
  }

  async confirmEmail(confirmationToken) {
    const response = await fetch(
      `${this.baseURL}/auth/confirm`,
      this.getRequestOptions({
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ confirmation_token: confirmationToken }),
      }),
    )
    const data = await response.json().catch(() => ({}))
    if (!response.ok) {
      const message = data.error || data.message || 'Не удалось подтвердить email'
      const err = new Error(message)
      err.status = response.status
      throw err
    }
    return data
  }

  async resendConfirmation(email) {
    const response = await fetch(
      `${this.baseURL}/auth/resend_confirmation`,
      this.getRequestOptions({
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      }),
    )
    const data = await response.json().catch(() => ({}))
    if (!response.ok) {
      const message = data.error || data.message || 'Не удалось отправить письмо'
      const err = new Error(message)
      err.status = response.status
      throw err
    }
    return data
  }

  // Services endpoints
  async getServices(filters = null) {
    const url = this.buildUrl('/services', filters)
    return await this.requestJson(url)
  }

  async getServicesByType(serviceType) {
    const url = new URL(`${this.baseURL}/services`)
    if (serviceType) url.searchParams.set('service_type', serviceType)
    return await this.requestJson(url.toString())
  }

  async getServiceTypes() {
    return await this.requestJson(`${this.baseURL}/services/service_types`)
  }

  // Admin endpoints
  async adminListUsers({ page = 1, per_page = 20, query = '' } = {}) {
    const url = new URL(`${this.baseURL}/admin/users`)
    url.searchParams.set('page', page)
    url.searchParams.set('per_page', per_page)
    if (query) url.searchParams.set('query', query)
    const data = await this.requestJson(url.toString())
    return { users: data.data, meta: data.meta }
  }

  async adminUpdateUser(id, user) {
    const data = await this.requestJson(`${this.baseURL}/admin/users/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user }),
    })
    return data.data
  }

  async adminDeleteUser(id) {
    const data = await this.requestJson(`${this.baseURL}/admin/users/${id}`, {
      method: 'DELETE',
    })
    return data.data
  }

  async createService(serviceData) {
    return await this.requestJson(`${this.baseURL}/services`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ service: serviceData }),
    })
  }

  async updateService(id, serviceData) {
    return await this.requestJson(`${this.baseURL}/services/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ service: serviceData }),
    })
  }

  async deleteService(id) {
    await this.requestJson(`${this.baseURL}/services/${id}`, {
      method: 'DELETE',
    })
  }

  // Bookings endpoints
  async getBookings() {
    const data = await this.requestJson(`${this.baseURL}/bookings`)
    return data.data
  }

  async createBooking({ master_id, time_slot_id, booking }) {
    // Валидация входных данных
    if (!master_id || !time_slot_id || !booking) {
      throw new Error('Необходимы все параметры для создания бронирования')
    }

    // Проверка типов данных
    if (typeof master_id !== 'number' || typeof time_slot_id !== 'number') {
      throw new Error('Неверные типы данных')
    }

    // Санитизация данных
    const sanitizedBooking = {
      service_id: parseInt(booking.service_id),
      client_name: String(booking.client_name || '')
        .trim()
        .substring(0, 100),
      client_email: String(booking.client_email || '')
        .trim()
        .substring(0, 255),
      client_phone: String(booking.client_phone || '')
        .trim()
        .substring(0, 20),
    }

    return await this.requestJson(`${this.baseURL}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        master_id: parseInt(master_id),
        time_slot_id: parseInt(time_slot_id),
        booking: sanitizedBooking,
      }),
    })
  }

  async updateBookingStatus(id, status) {
    return await this.requestJson(`${this.baseURL}/bookings/${id}/update_status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ status }),
    })
  }

  async deleteBooking(id) {
    return await this.requestJson(`${this.baseURL}/bookings/${id}`, {
      method: 'DELETE',
    })
  }

  // Public time slots for a master by date (client flow)
  async getPublicSlots(masterId, date) {
    const url = new URL(`${this.baseURL}/time_slots/public`)
    url.searchParams.set('master_id', masterId)
    if (date) url.searchParams.set('date', date)
    return await this.requestJson(url.toString())
  }

  // Master/private time slots
  async getTimeSlots(date) {
    const url = this.buildUrl('/time_slots', { date })
    return await this.requestJson(url)
  }

  async addTimeSlot(date) {
    return await this.requestJson(`${this.baseURL}/time_slots/add_slot`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ date }),
    })
  }

  async updateTimeSlot(id, { is_break }) {
    return await this.requestJson(`${this.baseURL}/time_slots/${id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ is_break }),
    })
  }

  async logout() {
    const url = this.buildUrl('/auth/logout')
    return await this.requestJson(url, {
      method: 'DELETE',
    })
  }

  async loginWithGoogle(idToken) {
    const response = await fetch(
      `${this.baseURL}/auth/google`,
      this.getRequestOptions({
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id_token: idToken }),
      }),
    )
    const data = await response.json().catch(() => ({}))
    if (!response.ok) {
      const message =
        (data && data.error && (data.error.message || data.error.code)) ||
        data.message ||
        (Array.isArray(data?.errors) ? data.errors.join(', ') : null) ||
        'Ошибка входа через Google'
      const err = new Error(message)
      err.status = response.status
      throw err
    }
    return data
  }

  // Users endpoints
  async getCurrentUser() {
    return await this.requestJson(`${this.baseURL}/auth/profile`)
  }

  // Working Day Exceptions endpoints
  async getWorkingDayExceptions() {
    return await this.requestJson(`${this.baseURL}/working_day_exceptions`)
  }

  async toggleWorkingDay(date, reason = null) {
    return await this.requestJson(`${this.baseURL}/working_day_exceptions/toggle`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ date, reason }),
    })
  }

  async createWorkingDayException(exceptionData) {
    return await this.requestJson(`${this.baseURL}/working_day_exceptions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ working_day_exception: exceptionData }),
    })
  }

  async updateWorkingDayException(id, exceptionData) {
    return await this.requestJson(`${this.baseURL}/working_day_exceptions/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ working_day_exception: exceptionData }),
    })
  }

  async deleteWorkingDayException(id) {
    await this.requestJson(`${this.baseURL}/working_day_exceptions/${id}`, {
      method: 'DELETE',
    })
  }

  // Working Schedules endpoints
  async getWorkingSchedules() {
    return await this.requestJson(`${this.baseURL}/working_schedules`)
  }

  async updateWorkingSchedule(id, scheduleData) {
    return await this.requestJson(`${this.baseURL}/working_schedules/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ working_schedule: scheduleData }),
    })
  }

  // GDPR endpoints
  async getGdprConsentStatus() {
    return await this.requestJson(`${this.baseURL}/gdpr/consent_status`)
  }

  async exportGdprData() {
    return await this.requestJson(`${this.baseURL}/gdpr/export_data`, {
      method: 'POST',
    })
  }

  async requestGdprDeletion() {
    return await this.requestJson(`${this.baseURL}/gdpr/request_deletion`, {
      method: 'POST',
    })
  }

  async cancelGdprDeletion() {
    return await this.requestJson(`${this.baseURL}/gdpr/cancel_deletion`, {
      method: 'POST',
    })
  }

  async giveGdprConsent(version = '1.0') {
    return await this.requestJson(`${this.baseURL}/gdpr/give_consent`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ version }),
    })
  }

  async revokeGdprConsent() {
    return await this.requestJson(`${this.baseURL}/gdpr/revoke_consent`, {
      method: 'POST',
    })
  }

  async giveMarketingConsent() {
    return await this.requestJson(`${this.baseURL}/gdpr/give_marketing_consent`, {
      method: 'POST',
    })
  }

  async revokeMarketingConsent() {
    return await this.requestJson(`${this.baseURL}/gdpr/revoke_marketing_consent`, {
      method: 'POST',
    })
  }
}

export default new ApiService()
