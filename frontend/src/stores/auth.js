import { defineStore } from 'pinia'
import api from '../services/api'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    token: null, // Токен теперь в httpOnly cookie
    loading: false,
    error: null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.user,
    isMaster: (state) => state.user?.role === 'master',
    isClient: (state) => state.user?.role === 'client',
    isAdmin: (state) => state.user?.role === 'admin',
  },

  actions: {
    init() {
      // Централизованная обработка 401 из api.js
      if (typeof window !== 'undefined') {
        window.addEventListener('api:unauthorized', () => {
          this.logout()
          try {
            if (window.location.pathname !== '/login') {
              window.location.href = '/login'
            }
          } catch {
            // ignore navigation errors
          }
        })
      }
    },
    async login(email, password) {
      this.loading = true
      this.error = null

      try {
        const response = await api.login(email, password)
        this.user = response.user
        // Токен теперь хранится в httpOnly cookie, не нужно сохранять в localStorage
        this.token = 'httpOnly_cookie' // Маркер для фронтенда
        return response
      } catch (err) {
        this.error = err.message
        throw err
      } finally {
        this.loading = false
      }
    },

    async register(userData) {
      this.loading = true
      this.error = null

      try {
        const response = await api.register(userData)
        // Не логиним автоматически: требуется подтверждение email
        // Просто возвращаем ответ с сообщением
        return response
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },

    async getCurrentUser() {
      try {
        // Токен автоматически отправляется в httpOnly cookie
        const response = await api.getCurrentUser()
        this.user = response.user
        this.token = 'httpOnly_cookie' // Устанавливаем маркер
      } catch {
        this.logout()
      }
    },

    async logout() {
      try {
        // Отправляем запрос на logout для очистки httpOnly cookie
        await api.logout()
      } catch (e) {
        console.error('Logout error:', e)
      } finally {
        this.user = null
        this.token = null
        this.error = null
        // Очищаем localStorage от старых токенов
        if (typeof window !== 'undefined') {
          localStorage.removeItem('token')
        }
      }
    },
  },
})
