const API_BASE_URL = (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.VITE_API_URL)
  ? `${import.meta.env.VITE_API_URL.replace(/\/?$/, '')}/api/v1`
  : 'http://localhost:3000/api/v1'

class ApiService {
  constructor() {
    this.baseURL = API_BASE_URL
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

    const data = await response.json()

    if (!response.ok) {
      const errorMessage = data.error || 'Login failed'
      throw new Error(errorMessage)
    }

    return data
  }

  async register(userData) {
    const response = await fetch(`${this.baseURL}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: userData }),
    })

    const data = await response.json()

    if (!response.ok) {
      const errorMessage = data.errors
        ? data.errors.join(', ')
        : data.error || 'Registration failed'
      throw new Error(errorMessage)
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
    const json = await response.json().catch(() => ({}))
    if (!response.ok) {
      throw new Error(json.error || 'Failed to update slot')
    }
    return json
  }

  async logout(token) {
    const response = await fetch(`${this.baseURL}/auth/logout`, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })

    if (!response.ok) {
      throw new Error('Failed to logout')
    }

    return await response.json()
  }

  // Users endpoints
  async getCurrentUser(token) {
    const response = await fetch(`${this.baseURL}/auth/profile`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })

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

    if (!response.ok) {
      throw new Error('Failed to delete working day exception')
    }
  }

  // Working Schedules endpoints
  async getWorkingSchedules(token) {
    const response = await fetch(`${this.baseURL}/working_schedules`, {
      headers: { Authorization: `Bearer ${token}` },
    })
    if (!response.ok) throw new Error('Failed to fetch working schedules')
    return await response.json()
  }

  async updateWorkingSchedule(id, scheduleData, token) {
    const response = await fetch(`${this.baseURL}/working_schedules/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ working_schedule: scheduleData }),
    })
    const json = await response.json().catch(() => ({}))
    if (!response.ok) throw new Error(json.errors ? json.errors.join(', ') : 'Failed to update schedule')
    return json
  }
}

export default new ApiService()
