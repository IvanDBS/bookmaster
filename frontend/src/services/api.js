const API_BASE_URL = 'http://localhost:3000/api/v1'

class ApiService {
  constructor() {
    this.baseURL = API_BASE_URL
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
      const errorMessage = data.errors ? data.errors.join(', ') : data.error || 'Registration failed'
      throw new Error(errorMessage)
    }
    
    return data
  }

  // Services endpoints
  async getServices() {
    const response = await fetch(`${this.baseURL}/services`)
    if (!response.ok) {
      throw new Error('Failed to fetch services')
    }
    return await response.json()
  }

  async createService(serviceData, token) {
    const response = await fetch(`${this.baseURL}/services`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
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
        'Authorization': `Bearer ${token}`,
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
        'Authorization': `Bearer ${token}`,
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
        'Authorization': `Bearer ${token}`,
      },
    })
    
    if (!response.ok) {
      throw new Error('Failed to fetch bookings')
    }
    
    return await response.json()
  }

  async createBooking(bookingData) {
    const response = await fetch(`${this.baseURL}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ booking: bookingData }),
    })
    
    if (!response.ok) {
      throw new Error('Failed to create booking')
    }
    
    return await response.json()
  }

  async updateBookingStatus(id, status, token) {
    const response = await fetch(`${this.baseURL}/bookings/${id}/status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({ status }),
    })
    
    if (!response.ok) {
      throw new Error('Failed to update booking status')
    }
    
    return await response.json()
  }

  async logout(token) {
    const response = await fetch(`${this.baseURL}/auth/logout`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token}`,
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
        'Authorization': `Bearer ${token}`,
      },
    })
    
    if (!response.ok) {
      throw new Error('Failed to fetch current user')
    }
    
    return await response.json()
  }
}

export default new ApiService() 