import { defineStore } from 'pinia'
import api from '../services/api'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    token: localStorage.getItem('token') || null,
    loading: false,
    error: null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.token,
    isMaster: (state) => state.user?.role === 'master',
    isClient: (state) => state.user?.role === 'client',
  },

  actions: {
    init() {
      // Централизованная обработка 401 из api.js
      if (typeof window !== 'undefined') {
        window.addEventListener('api:unauthorized', () => {
          this.logout()
          // Мягкий редирект на /login если мы не там
          try {
            if (window.location.pathname !== '/login') {
              window.location.href = '/login'
            }
          } catch (_) {}
        })
      }
    },
    async login(email, password) {
      this.loading = true
      this.error = null

      try {
        const response = await api.login(email, password)
        this.user = response.user
        this.token = response.token
        localStorage.setItem('token', this.token)
        return response
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },

    async register(userData) {
      this.loading = true
      this.error = null

      try {
        const response = await api.register(userData)
        this.user = response.user
        this.token = response.token
        localStorage.setItem('token', this.token)
        return response
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },

    async getCurrentUser() {
      if (!this.token) return

      try {
        const response = await api.getCurrentUser(this.token)
        this.user = response.user
      } catch (error) {
        this.logout()
      }
    },

    async logout() {
      try {
        if (this.token) {
          await api.logout(this.token)
        }
      } catch (error) {
        console.error('Logout error:', error)
      } finally {
        this.user = null
        this.token = null
        this.error = null
        localStorage.removeItem('token')
      }
    },
  },
})
