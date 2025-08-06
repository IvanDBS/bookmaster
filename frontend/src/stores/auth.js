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
    }
  }
}) 