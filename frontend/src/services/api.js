const API_BASE_URL = (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.VITE_API_URL)
  ? `${import.meta.env.VITE_API_URL.replace(/\/?$/, '')}/api/v1`
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

  // Helpers
  buildUrl(path, params = null) {
    const url = new URL(`${this.baseURL}${path}`)
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
    const response = await fetch(`${this.baseURL}/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: { email, password } }),
    })

    const data = await response.json().catch(() => ({}))

    if (!response.ok) {
      const message = typeof data.error === 'string'
        ? data.error
        : (data && data.error && (data.error.message || data.error.code))
          || data.message
          || (Array.isArray(data?.errors) ? data.errors.join(', ') : null)
          || 'Ошибка входа'
      throw new Error(message)
    }

    return data
  }

  async register(userData) {
    // Не отправляем служебные поля формы (например, terms)
    const { terms, ...sanitized } = userData || {}
    const response = await fetch(`${this.baseURL}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: sanitized }),
    })

    const data = await response.json().catch(() => ({}))

    if (!response.ok) {
      const message = (Array.isArray(data?.errors) ? data.errors.join(', ') : null)
        || (data && data.error && (data.error.message || data.error.code))
        || data.message
        || (typeof data.error === 'string' ? data.error : null)
        || 'Registration failed'
      const err = new Error(message)
      err.status = response.status
      throw err
    }

    return data
  }

  async confirmEmail(confirmationToken) {
    const response = await fetch(`${this.baseURL}/auth/confirm`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ confirmation_token: confirmationToken }),
    })
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
    const response = await fetch(`${this.baseURL}/auth/resend_confirmation`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    })
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
  async getServices(filters = null, token = null) {
    const url = this.buildUrl('/services', filters)
    const response = await fetch(url, {
      headers: {
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }
    if (!response.ok) {
      throw new Error('Failed to fetch services')
    }
    return await response.json()
  }

  async getServicesByType(serviceType) {
    const url = new URL(`${this.baseURL}/services`)
    if (serviceType) url.searchParams.set('service_type', serviceType)
    const response = await fetch(url.toString())
    if (!response.ok) {
      throw new Error('Failed to fetch services by type')
    }
    return await response.json()
  }

  async getServiceTypes() {
    const response = await fetch(`${this.baseURL}/services/service_types`)
    if (!response.ok) {
      throw new Error('Failed to fetch service types')
    }
    return await response.json()
  }

  async createService(serviceData, token) {
    const response = await fetch(`${this.baseURL}/services`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ service: serviceData }),
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    if (!response.ok) {
      throw new Error('Failed to create service')
    }

    return await response.json()
  }

  async updateService(id, serviceData, token) {
    const response = await fetch(`${this.baseURL}/services/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ service: serviceData }),
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    if (!response.ok) {
      throw new Error('Failed to update service')
    }

    return await response.json()
  }

  async deleteService(id, token) {
    const response = await fetch(`${this.baseURL}/services/${id}`, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    if (!response.ok) {
      throw new Error('Failed to delete service')
    }
  }

  // Bookings endpoints
  async getBookings(token) {
    const response = await fetch(`${this.baseURL}/bookings`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    if (!response.ok) {
      throw new Error('Failed to fetch bookings')
    }

    return await response.json()
  }

  async createBooking({ master_id, time_slot_id, booking }, token = null) {
    const response = await fetch(`${this.baseURL}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: JSON.stringify({ master_id, time_slot_id, booking }),
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    const text = await response.text()
    const json = text ? JSON.parse(text) : {}
    if (!response.ok) {
      throw new Error(
        json.error || (json.errors && json.errors.join(', ')) || 'Failed to create booking',
      )
    }
    return json
  }

  async updateBookingStatus(id, status, token) {
    const response = await fetch(`${this.baseURL}/bookings/${id}/update_status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ status }),
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    if (!response.ok) {
      throw new Error('Failed to update booking status')
    }

    return await response.json()
  }

  async deleteBooking(id, token) {
    const response = await fetch(`${this.baseURL}/bookings/${id}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` },
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }
    if (!response.ok) {
      throw new Error('Failed to delete booking')
    }
    return await response.json().catch(() => ({}))
  }

  // Public time slots for a master by date (client flow)
  async getPublicSlots(masterId, date) {
    const url = new URL(`${this.baseURL}/time_slots/public`)
    url.searchParams.set('master_id', masterId)
    if (date) url.searchParams.set('date', date)
    const response = await fetch(url.toString())
    if (!response.ok) {
      throw new Error('Failed to fetch public time slots')
    }
    return await response.json()
  }

  // Master/private time slots
  async getTimeSlots(date, token) {
    const url = this.buildUrl('/time_slots', { date })
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      const err = new Error('Unauthorized')
      err.status = 401
      throw err
    }
    if (!response.ok) {
      const err = new Error('Failed to fetch time slots')
      err.status = response.status
      throw err
    }
    return await response.json()
  }

  async addTimeSlot(date, token) {
    const response = await fetch(`${this.baseURL}/time_slots/add_slot`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ date }),
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }
    const json = await response.json().catch(() => ({}))
    if (!response.ok) throw new Error(json.error || 'Failed to add slot')
    return json
  }

  async updateTimeSlot(id, { is_break }, token = null) {
    const response = await fetch(`${this.baseURL}/time_slots/${id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: JSON.stringify({ is_break }),
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }
    const json = await response.json().catch(() => ({}))
    if (!response.ok) {
      throw new Error(json.error || 'Failed to update slot')
    }
    return json
  }

  async logout(token) {
    const url = this.buildUrl('/auth/logout')
    const response = await fetch(url, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
    if (response.status === 401) {
      // already unauthorized; still cleanup
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    if (!response.ok) {
      throw new Error('Failed to logout')
    }

    return await response.json()
  }

  async loginWithGoogle(idToken) {
    const response = await fetch(`${this.baseURL}/auth/google`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id_token: idToken }),
    })
    const data = await response.json().catch(() => ({}))
    if (!response.ok) {
      const message = (data && data.error && (data.error.message || data.error.code))
        || data.message
        || (Array.isArray(data?.errors) ? data.errors.join(', ') : null)
        || 'Ошибка входа через Google'
      const err = new Error(message)
      err.status = response.status
      throw err
    }
    return data
  }

  // Users endpoints
  async getCurrentUser(token) {
    const response = await fetch(`${this.baseURL}/auth/profile`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    if (!response.ok) {
      throw new Error('Failed to fetch current user')
    }

    return await response.json()
  }

  // Working Day Exceptions endpoints
  async getWorkingDayExceptions(token) {
    const response = await fetch(`${this.baseURL}/working_day_exceptions`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    if (!response.ok) {
      throw new Error('Failed to fetch working day exceptions')
    }

    return await response.json()
  }

  async toggleWorkingDay(date, token, reason = null) {
    const response = await fetch(`${this.baseURL}/working_day_exceptions/toggle`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ date, reason }),
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      const err = new Error('Unauthorized')
      err.status = 401
      throw err
    }

    if (!response.ok) {
      const err = new Error('Failed to toggle working day')
      err.status = response.status
      throw err
    }

    return await response.json()
  }

  async createWorkingDayException(exceptionData, token) {
    const response = await fetch(`${this.baseURL}/working_day_exceptions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ working_day_exception: exceptionData }),
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    if (!response.ok) {
      throw new Error('Failed to create working day exception')
    }

    return await response.json()
  }

  async updateWorkingDayException(id, exceptionData, token) {
    const response = await fetch(`${this.baseURL}/working_day_exceptions/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ working_day_exception: exceptionData }),
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    if (!response.ok) {
      throw new Error('Failed to update working day exception')
    }

    return await response.json()
  }

  async deleteWorkingDayException(id, token) {
    const response = await fetch(`${this.baseURL}/working_day_exceptions/${id}`, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }

    if (!response.ok) {
      throw new Error('Failed to delete working day exception')
    }
  }

  // Working Schedules endpoints
  async getWorkingSchedules(token) {
    const response = await fetch(`${this.baseURL}/working_schedules`, {
      headers: { Authorization: `Bearer ${token}` },
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }
    if (!response.ok) throw new Error('Failed to fetch working schedules')
    return await response.json()
  }

  async updateWorkingSchedule(id, scheduleData, token) {
    const response = await fetch(`${this.baseURL}/working_schedules/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ working_schedule: scheduleData }),
    })
    if (response.status === 401) {
      await this.handleUnauthorized()
      throw new Error('Unauthorized')
    }
    const json = await response.json().catch(() => ({}))
    if (!response.ok) throw new Error(json.errors ? json.errors.join(', ') : 'Failed to update schedule')
    return json
  }
}

export default new ApiService()
