import { defineStore } from 'pinia'
import api from '../services/api'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    token: localStorage.getItem('token') || null,
    loading: false,
    error: null
  }),

  getters: {
    isAuthenticated: (state) => !!state.token,
    isMaster: (state) => state.user?.role === 'master',
    isClient: (state) => state.user?.role === 'client'
  },

  actions: {
    async login(email, password) {
      this.loading = true
      this.error = null
      
      try {
        const response = await api.login(email, password)
        this.user = response.user
        // Пока не используем токен, просто сохраняем пользователя
        this.token = 'dummy-token' // Временное решение
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
        // Пока не используем токен, просто сохраняем пользователя
        this.token = 'dummy-token' // Временное решение
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
        const user = await api.getCurrentUser(this.token)
        this.user = user
      } catch (error) {
        this.logout()
      }
    },

    logout() {
      this.user = null
      this.token = null
      this.error = null
      localStorage.removeItem('token')
    }
  }
}) 