import { ref, computed } from 'vue'
import { useAuthStore } from '../stores/auth'
import api from '../services/api'
import { useToast } from './useToast'
import { useFormatters } from './useFormatters'

export function useBookings() {
  const authStore = useAuthStore()
  const { formatDate, formatTime, getStatusClass, getStatusText } = useFormatters()

  // Reactive data
  const recentBookings = ref([])
  const bookingFilter = ref('all')
  const showConfirmationModal = ref(false)
  const modalType = ref('confirm')
  const selectedBooking = ref(null)
  // Signal to notify other parts (e.g., calendar) to refresh after booking changes
  const refreshTick = ref(0)

  // Computed properties
  const filteredBookings = computed(() => {
    const safe = Array.isArray(recentBookings.value) ? recentBookings.value.filter(Boolean) : []
    const filtered =
      bookingFilter.value === 'all'
        ? safe
        : safe.filter((booking) => booking && booking.status === bookingFilter.value)

    // Sort by creation time (newest first). Fallback to start_time if created_at is missing.
    return [...filtered].sort((a, b) => {
      const timeA = new Date(a?.created_at || a?.start_time || 0).getTime()
      const timeB = new Date(b?.created_at || b?.start_time || 0).getTime()
      return timeB - timeA
    })
  })

  const pendingBookingsCount = computed(() => {
    const safe = Array.isArray(recentBookings.value) ? recentBookings.value : []
    return safe.filter((booking) => booking && booking.status === 'pending').length
  })

  const sortedSelectedDateBookings = computed(() => {
    return [...selectedDateBookings.value].sort((a, b) => {
      const timeA = new Date(a.start_time).getTime()
      const timeB = new Date(b.start_time).getTime()
      return timeA - timeB
    })
  })

  // Добавляем selectedDateBookings в state
  const selectedDateBookings = ref([])

  // API functions
  const loadBookings = async () => {
    try {
      // Получаем токен из localStorage или authStore
      const token = localStorage.getItem('token') || authStore.token
      
      if (!token) {
        console.warn('No auth token available')
        recentBookings.value = []
        return
      }

      const bookingsData = await api.getBookings(token)
      recentBookings.value = Array.isArray(bookingsData) ? bookingsData.filter(Boolean) : []
      console.log('Bookings loaded:', recentBookings.value.length)
    } catch (error) {
      console.error('Error loading bookings:', error)
      recentBookings.value = []
    }
  }

  const loadBookingsForDate = async (date) => {
    try {
      const startOfDay = new Date(date)
      startOfDay.setHours(0, 0, 0, 0)
      const endOfDay = new Date(date)
      endOfDay.setHours(23, 59, 59, 999)

      selectedDateBookings.value = recentBookings.value.filter((booking) => {
        const bookingDate = new Date(booking.start_time)
        return bookingDate >= startOfDay && bookingDate <= endOfDay
      })

      const hasPendingBookings = selectedDateBookings.value.some(
        (booking) => booking.status === 'pending',
      )

      return hasPendingBookings
    } catch (error) {
      console.error('Error loading bookings for date:', error)
      selectedDateBookings.value = []
      return false
    }
  }

  // Modal functions
  const showConfirmModal = (booking) => {
    selectedBooking.value = booking
    modalType.value = 'confirm'
    showConfirmationModal.value = true
  }

  const showCancelModal = (booking) => {
    selectedBooking.value = booking
    modalType.value = 'cancel'
    showConfirmationModal.value = true
  }

  const closeConfirmationModal = () => {
    showConfirmationModal.value = false
    selectedBooking.value = null
  }

  const handleModalConfirm = async (bookingId) => {
    try {
      if (!authStore.token) {
        throw new Error('Не авторизован')
      }

      const status = modalType.value === 'confirm' ? 'confirmed' : 'cancelled'
      // Optimistic UI update in recentBookings to reduce visual latency
      const previous = Array.isArray(recentBookings.value) ? [...recentBookings.value] : []
      const idStr = String(bookingId)
      const idx = previous.findIndex((b) => b && String(b.id) === idStr)
      if (idx !== -1) {
        const updated = { ...previous[idx], status }
        recentBookings.value = [...previous.slice(0, idx), updated, ...previous.slice(idx + 1)]
      }

      // Сразу дёргаем рефреш календаря, чтобы не ждать сеть
      refreshTick.value += 1

      await api.updateBookingStatus(bookingId, status, authStore.token)

      // Фоновое обновление списка бронирований (не блокируем UI)
      loadBookings().catch(() => {})
      closeConfirmationModal()
      const toast = useToast()
      toast.show(
        modalType.value === 'confirm' ? 'Запись подтверждена' : 'Запись отменена',
        modalType.value === 'confirm' ? 'green' : 'red',
      )
    } catch (error) {
      console.error(`Error ${modalType.value}ing booking:`, error)
      const toast = useToast()
      toast.show(
        `Ошибка при ${modalType.value === 'confirm' ? 'подтверждении' : 'отмене'} записи: ` +
          error.message,
        'red',
      )
      // Optional: could rollback optimistic change, but we reloaded on error anyway
    }
  }

  // Filter functions
  const setBookingFilter = (filter) => {
    bookingFilter.value = filter
  }

  // Utility functions: centralized in useFormatters

  // Price helper to normalize price retrieval for booking or embedded service
  const getSlotPrice = (booking) => {
    if (booking?.price) return Math.round(booking.price)
    if (booking?.service?.price) return Math.round(booking.service.price)
    // try to find full version in the current list by id
    const source = Array.isArray(recentBookings?.value) ? recentBookings.value : []
    const fullVersion = source.find((b) => b && b.id === booking?.id)
    if (fullVersion?.service?.price) return Math.round(fullVersion.service.price)
    return 0
  }

  return {
    // State
    recentBookings,
    bookingFilter,
    showConfirmationModal,
    modalType,
    selectedBooking,
    selectedDateBookings,
    refreshTick,

    // Computed
    filteredBookings,
    pendingBookingsCount,
    sortedSelectedDateBookings,

    // Functions
    loadBookings,
    loadBookingsForDate,
    showConfirmModal,
    showCancelModal,
    closeConfirmationModal,
    handleModalConfirm,
    setBookingFilter,
    formatDate,
    formatTime,
    getStatusClass,
    getStatusText,
    getSlotPrice,
  }
}
