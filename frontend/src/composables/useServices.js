import { ref, onMounted } from 'vue'
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
    console.log('useServices mounted, auth token:', authStore.token)
    console.log('Current user:', authStore.user)
    await loadServices()
    await loadServiceTypes()
  })

  // API functions
  const loadServices = async () => {
    try {
      if (!authStore.token) {
        console.log('No auth token, skipping services load')
        return
      }

      const response = await fetch('http://localhost:3000/api/v1/services', {
        headers: {
          Authorization: `Bearer ${authStore.token}`,
        },
      })
      if (!response.ok) {
        throw new Error('Failed to fetch services')
      }
      const servicesData = await response.json()
      services.value = servicesData
      console.log('Loaded services:', servicesData)
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

  const addService = async () => {
    try {
      if (!authStore.token) {
        throw new Error('Не авторизован')
      }

      const serviceData = {
        name: newService.value.name,
        description: newService.value.description,
        price: parseInt(newService.value.price),
        duration: parseInt(newService.value.duration),
        service_type: newService.value.service_type,
      }

      let url = 'http://localhost:3000/api/v1/services'
      let method = 'POST'

      if (editingServiceId.value) {
        url = `http://localhost:3000/api/v1/services/${editingServiceId.value}`
        method = 'PUT'
      }

      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authStore.token}`,
        },
        body: JSON.stringify({ service: serviceData }),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(
          errorData.errors
            ? errorData.errors.join(', ')
            : errorData.error || 'Failed to create service',
        )
      }

      await loadServices()

      const wasEditing = editingServiceId.value
      alert(wasEditing ? 'Услуга успешно обновлена!' : 'Услуга успешно добавлена!')

      closeModal()
    } catch (error) {
      console.error('Error adding service:', error)
      alert('Ошибка при добавлении услуги: ' + error.message)
    }
  }

  const deleteService = async (serviceId) => {
    if (confirm('Вы уверены, что хотите удалить эту услугу?')) {
      try {
        if (!authStore.token) {
          throw new Error('Не авторизован')
        }

        const response = await fetch(`http://localhost:3000/api/v1/services/${serviceId}`, {
          method: 'DELETE',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${authStore.token}`,
          },
        })

        if (!response.ok) {
          const errorData = await response.json()
          throw new Error(errorData.error || 'Failed to delete service')
        }

        await loadServices()
        alert('Услуга успешно удалена!')
      } catch (error) {
        console.error('Error deleting service:', error)
        alert('Ошибка при удалении услуги: ' + error.message)
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
