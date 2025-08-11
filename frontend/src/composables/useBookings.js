import { ref, computed } from 'vue'
import { useAuthStore } from '../stores/auth'
import api from '../services/api'

export function useBookings() {
  const authStore = useAuthStore()

  // Reactive data
  const recentBookings = ref([])
  const bookingFilter = ref('all')
  const showConfirmationModal = ref(false)
  const modalType = ref('confirm')
  const selectedBooking = ref(null)

  // Computed properties
  const filteredBookings = computed(() => {
    const safe = Array.isArray(recentBookings.value) ? recentBookings.value.filter(Boolean) : []
    const filtered = bookingFilter.value === 'all'
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
    return recentBookings.value.filter((booking) => booking.status === 'pending').length
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
      if (!authStore.token) {
        console.warn('No auth token available')
        recentBookings.value = []
        return
      }

      const bookingsData = await api.getBookings(authStore.token)
      recentBookings.value = Array.isArray(bookingsData) ? bookingsData.filter(Boolean) : []
    } catch (error) {
      console.error('Error loading bookings:', error)
      recentBookings.value = []
    }
  }

  const loadBookingsForDate = async (date, selectedDateBookings) => {
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
      await api.updateBookingStatus(bookingId, status, authStore.token)

      await loadBookings()
      closeConfirmationModal()
    } catch (error) {
      console.error(`Error ${modalType.value}ing booking:`, error)
      alert(
        `Ошибка при ${modalType.value === 'confirm' ? 'подтверждении' : 'отмене'} записи: ` +
          error.message,
      )
    }
  }

  // Filter functions
  const setBookingFilter = (filter) => {
    bookingFilter.value = filter
  }

  // Utility functions
  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('ru-RU')
  }

  const formatTime = (dateString) => {
    return new Date(dateString).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })
  }

  const getStatusClass = (status) => {
    const classes = {
      pending: 'bg-yellow-100 text-yellow-800',
      confirmed: 'bg-green-100 text-green-800',
      cancelled: 'bg-red-100 text-red-800',
    }
    return classes[status] || 'bg-gray-100 text-gray-800'
  }

  const getStatusText = (status) => {
    const texts = {
      pending: 'Ожидает подтверждения',
      confirmed: 'Подтверждено',
      cancelled: 'Отменено',
    }
    return texts[status] || status
  }

  return {
    // State
    recentBookings,
    bookingFilter,
    showConfirmationModal,
    modalType,
    selectedBooking,
    selectedDateBookings,

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
  }
}
