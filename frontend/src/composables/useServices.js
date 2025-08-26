import { ref, onMounted } from 'vue'
import { useToast } from './useToast'
import { useAuthStore } from '../stores/auth'
import api from '../services/api'

export function useServices() {
  const authStore = useAuthStore()

  // Reactive data
  const services = ref([])
  const showModal = ref(false)
  const editingServiceId = ref(null)
  const newService = ref({
    name: '',
    description: '',
    price: '',
    duration: '',
    service_type: '',
  })
  const availableServiceTypes = ref([])

  // Инициализация при монтировании компонента
  onMounted(async () => {
    // remove verbose logs in production; keep silent in dev as well
    await loadServices()
    await loadServiceTypes()
  })

  // API functions
  const loadServices = async () => {
    try {
      if (!authStore.token) return

      const servicesData = await api.getServices()
      // Если мастер — API все равно отдаст только собственные (см. контроллер)
      services.value = servicesData
      // no-op
    } catch (error) {
      console.error('Error loading services:', error)
      services.value = []
    }
  }

  const loadServiceTypes = async () => {
    try {
      const serviceTypesData = await api.getServiceTypes()
      availableServiceTypes.value = serviceTypesData.service_types || []
    } catch (error) {
      console.error('Error loading service types:', error)
      availableServiceTypes.value = ['маникюр', 'педикюр', 'массаж']
    }
  }

  const addService = async (payload = null) => {
    try {
      if (!authStore.token) {
        throw new Error('Не авторизован')
      }

      const normalizeInt = (v) => {
        if (typeof v === 'number') return v
        if (typeof v === 'string') return parseInt(v.replace(/[^\d]/g, ''), 10)
        return NaN
      }

      const source = payload || newService.value || {}
      const serviceData = {
        name: String(source.name || '').trim(),
        description: String(source.description || '').trim(),
        price: normalizeInt(source.price),
        duration: normalizeInt(source.duration),
        service_type: String(source.service_type || '').trim(),
      }

      if (!serviceData.name || serviceData.name.length < 2)
        throw new Error('Введите название (мин. 2 символа)')
      if (!serviceData.price || Number.isNaN(serviceData.price))
        throw new Error('Укажите корректную цену')
      if (!serviceData.duration || Number.isNaN(serviceData.duration))
        throw new Error('Укажите корректную длительность')
      if (!serviceData.service_type) throw new Error('Выберите тип услуги')

      if (editingServiceId.value) {
        await api.updateService(editingServiceId.value, serviceData, authStore.token)
      } else {
        await api.createService(serviceData, authStore.token)
      }
      await loadServices()

      const wasEditing = editingServiceId.value
      useToast().show(wasEditing ? 'Услуга успешно обновлена!' : 'Услуга успешно добавлена!')

      closeModal()
    } catch (error) {
      console.error('Error adding service:', error)
      useToast().show(
        'Ошибка при добавлении услуги: ' + (error?.message || 'Проверьте поля'),
        'red',
      )
    }
  }

  const deleteService = async (serviceId) => {
    if (confirm('Вы уверены, что хотите удалить эту услугу?')) {
      try {
        if (!authStore.token) {
          throw new Error('Не авторизован')
        }

        await api.deleteService(serviceId, authStore.token)
        await loadServices()
        useToast().show('Услуга успешно удалена!')
      } catch (error) {
        console.error('Error deleting service:', error)
        useToast().show('Ошибка при удалении услуги: ' + error.message, 'red')
      }
    }
  }

  // Modal functions
  const editService = (service) => {
    newService.value = {
      name: service.name,
      description: service.description,
      price: service.price.toString(),
      duration: service.duration.toString(),
      service_type: service.service_type || '',
    }
    showModal.value = true
    editingServiceId.value = service.id
  }

  const closeModal = () => {
    showModal.value = false
    newService.value = { name: '', description: '', price: '', duration: '', service_type: '' }
    editingServiceId.value = null
  }

  return {
    // State
    services,
    showModal,
    editingServiceId,
    newService,
    availableServiceTypes,

    // Functions
    loadServices,
    loadServiceTypes,
    addService,
    deleteService,
    editService,
    closeModal,
  }
}
