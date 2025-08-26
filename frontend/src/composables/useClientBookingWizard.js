import { ref, watch } from 'vue'
import { useToast } from './useToast'
import { useAuthStore } from '../stores/auth'
import api from '../services/api'

export function useClientBookingWizard() {
  const authStore = useAuthStore()
  const { show: toast } = useToast()

  // Wizard state
  const currentStep = ref(1)
  const serviceTypes = ref(['маникюр', 'педикюр', 'массаж'])
  const selectedServiceType = ref(null)

  const mastersForType = ref([])
  const selectedMaster = ref(null)
  const selectedMasterServices = ref([])
  const selectedService = ref(null)

  const selectedDate = ref(new Date().toISOString().slice(0, 10))
  const selectedCalendarDate = ref(null)
  const daySlots = ref([])
  const selectedSlot = ref(null)

  // Loaders
  const isLoadingServices = ref(false)
  const isSubmitting = ref(false)

  const loadServiceTypes = async () => {
    try {
      const data = await api.getServiceTypes()
      serviceTypes.value = data.service_types || serviceTypes.value
    } catch (err) {
      console.debug('Failed to load service types:', err)
    }
  }

  const selectServiceType = async (type) => {
    try {
      selectedServiceType.value = type
      const services = await api.getServicesByType(type)
      const byMasterId = new Map()
      services
        .filter((s) => s && s.user && s.user.id)
        .forEach((s) => {
          if (!byMasterId.has(s.user.id)) {
            byMasterId.set(s.user.id, { id: s.user.id, user: s.user, services: [] })
          }
          byMasterId.get(s.user.id).services.push(s)
        })
      mastersForType.value = Array.from(byMasterId.values())
      selectedMaster.value = null
      selectedMasterServices.value = []
      selectedService.value = null
      currentStep.value = 2
    } catch (error) {
      console.error('Error selecting service type:', error)
      // Сброс состояния при ошибке
      selectedServiceType.value = null
      mastersForType.value = []
      currentStep.value = 1
    }
  }

  const selectMaster = (master) => {
    selectedMaster.value = master
    selectedMasterServices.value = master.services
    selectedService.value = null
    currentStep.value = 3
  }

  const resetToStep1 = () => {
    selectedServiceType.value = null
    selectedMaster.value = null
    selectedMasterServices.value = []
    selectedService.value = null
    selectedSlot.value = null
    currentStep.value = 1
  }

  const goBackToStep1 = () => {
    currentStep.value = 1
    selectedServiceType.value = null
  }

  const goBackToMasters = () => {
    currentStep.value = 2
  }

  const selectConcreteService = (srv) => {
    selectedService.value = srv
    selectedSlot.value = null
    daySlots.value = []
    fetchSlots()
    currentStep.value = 4
  }

  const fetchSlots = async () => {
    if (!selectedMaster.value) return
    const res = await api.getPublicSlots(selectedMaster.value.id, selectedDate.value)
    daySlots.value = Array.isArray(res) ? res : res.slots || []
  }

  watch(selectedDate, fetchSlots)

  const selectSlot = (slot) => {
    selectedSlot.value = slot
    currentStep.value = 5
  }

  const onDateSelected = (date) => {
    selectedCalendarDate.value = date
  }

  const onSlotSelected = (slot) => {
    selectedSlot.value = slot
    currentStep.value = 5
  }

  const submitBooking = async () => {
    try {
      if (!selectedMaster.value || !selectedService.value) {
        throw new Error('Не выбран мастер или услуга')
      }
      const payload = {
        master_id: selectedMaster.value.id,
        time_slot_id: selectedSlot.value.id,
        booking: { 
          service_id: selectedService.value.id,
          client_email: authStore.user?.email || 'test@example.com',
          client_name: `${authStore.user?.first_name || 'Тест'} ${authStore.user?.last_name || 'Пользователь'}`,
          client_phone: authStore.user?.phone || '0690000000'
        },
      }
      isSubmitting.value = true
      await api.createBooking(payload)
      // Сообщаем приложению о создании записи, чтобы обновить списки
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new CustomEvent('booking:created'))
      }
      toast('Запись создана')
      currentStep.value = 1
      selectedServiceType.value = null
      selectedMaster.value = null
      selectedMasterServices.value = []
      selectedService.value = null
      selectedSlot.value = null
    } catch (e) {
      toast(e.message || 'Не удалось создать запись', 'red')
    } finally {
      isSubmitting.value = false
    }
  }

  return {
    // state
    currentStep,
    serviceTypes,
    selectedServiceType,
    mastersForType,
    selectedMaster,
    selectedMasterServices,
    selectedService,
    selectedDate,
    selectedCalendarDate,
    daySlots,
    selectedSlot,
    isLoadingServices,
    isSubmitting,
    // actions
    loadServiceTypes,
    selectServiceType,
    selectMaster,
    resetToStep1,
    goBackToStep1,
    goBackToMasters,
    selectConcreteService,
    fetchSlots,
    selectSlot,
    onDateSelected,
    onSlotSelected,
    submitBooking,
  }
}
