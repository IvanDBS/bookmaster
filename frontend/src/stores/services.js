import { defineStore } from 'pinia'
import api from '../services/api'
import { useAuthStore } from './auth'

export const useServicesStore = defineStore('services', {
  state: () => ({
    services: [],
    loading: false,
    error: null,
  }),

  getters: {
    getServicesByMaster: (state) => (masterId) => {
      return state.services.filter((service) => service.user_id === masterId)
    },
  },

  actions: {
    async fetchServices() {
      this.loading = true
      this.error = null

      try {
        const services = await api.getServices()
        this.services = services
        return services
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },

    async createService(serviceData) {
      const authStore = useAuthStore()
      this.loading = true
      this.error = null

      try {
        const service = await api.createService(serviceData, authStore.token)
        this.services.push(service)
        return service
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },

    async updateService(id, serviceData) {
      const authStore = useAuthStore()
      this.loading = true
      this.error = null

      try {
        const updatedService = await api.updateService(id, serviceData, authStore.token)
        const index = this.services.findIndex((s) => s.id === id)
        if (index !== -1) {
          this.services[index] = updatedService
        }
        return updatedService
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },

    async deleteService(id) {
      const authStore = useAuthStore()
      this.loading = true
      this.error = null

      try {
        await api.deleteService(id, authStore.token)
        this.services = this.services.filter((s) => s.id !== id)
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },
  },
})
