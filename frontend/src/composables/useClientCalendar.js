import { ref, computed } from 'vue'
import api from '../services/api'

export function useClientCalendar() {
  // Reactive data
  const currentDate = ref(new Date())
  const selectedDate = ref(null)
  const slotsCache = ref(new Map())
  const masterId = ref(null)

  // Computed properties
  const currentMonthName = computed(() => {
    return currentDate.value.toLocaleDateString('ru-RU', { month: 'long' })
  })

  const currentYear = computed(() => {
    return currentDate.value.getFullYear()
  })

  // Calendar date generation functions
  const generateCalendarDates = (baseDate) => {
    const year = baseDate.getFullYear()
    const month = baseDate.getMonth()

    const firstDay = new Date(year, month, 1)
    const startDate = new Date(firstDay)
    startDate.setDate(startDate.getDate() - (firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1))

    const dates = []
    const today = new Date()

    for (let i = 0; i < 42; i++) {
      const date = new Date(startDate)
      date.setDate(startDate.getDate() + i)

      const dateString = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
      const daySlots = slotsCache.value.get(dateString) || []

      // Анализируем слоты для определения статуса дня
      const workSlots = daySlots.filter((slot) => slot.slot_type === 'work')
      const availableSlots = workSlots.filter((slot) => slot.is_available && !slot.booked)
      const bookedSlots = workSlots.filter((slot) => slot.booked)

      // Только рабочие слоты считаются доступными для бронирования
      const totalBookableSlots = workSlots.length
      const totalAvailableSlots = availableSlots.length

      dates.push({
        date: date,
        day: date.getDate(),
        key: dateString,
        isCurrentMonth: date.getMonth() === month,
        isToday: date.toDateString() === today.toDateString(),
        isPast: date < new Date(today.getFullYear(), today.getMonth(), today.getDate()),
        isSelected: selectedDate.value && selectedDate.value.date === dateString,
        totalSlots: totalBookableSlots,
        availableSlots: totalAvailableSlots,
        bookedSlots: bookedSlots.length,
        loadLevel:
          totalBookableSlots === 0
            ? 'non_working'
            : totalAvailableSlots === 0
              ? 'full'
              : totalAvailableSlots < totalBookableSlots
                ? 'moderate'
                : 'available',
      })
    }

    return dates
  }

  const calendarDates = computed(() => {
    return generateCalendarDates(currentDate.value)
  })

  // Navigation functions
  const previousMonth = () => {
    currentDate.value = new Date(
      currentDate.value.getFullYear(),
      currentDate.value.getMonth() - 1,
      1,
    )
    loadSlotsForVisibleDates()
  }

  const nextMonth = () => {
    currentDate.value = new Date(
      currentDate.value.getFullYear(),
      currentDate.value.getMonth() + 1,
      1,
    )
    loadSlotsForVisibleDates()
  }

  const selectDate = (date) => {
    selectedDate.value = date
  }

  // Loading functions
  const loadSlotsForDate = async (date) => {
    if (!masterId.value) return

    const dateString = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`

    try {
      const data = await api.getPublicSlots(masterId.value, dateString)
      slotsCache.value.set(dateString, Array.isArray(data) ? data : data.slots || [])
    } catch (error) {
      console.error('Error loading slots for date:', error)
      slotsCache.value.set(dateString, [])
    }
  }

  const loadSlotsForVisibleDates = async () => {
    if (!masterId.value) return

    const year = currentDate.value.getFullYear()
    const month = currentDate.value.getMonth()

    // Load slots for all visible dates in the calendar
    for (let day = 1; day <= 31; day++) {
      const date = new Date(year, month, day)
      if (date.getMonth() === month) {
        await loadSlotsForDate(date)
      }
    }

    // Force calendar to update
  }

  const setMasterId = (id) => {
    masterId.value = id
    if (id) {
      loadSlotsForVisibleDates()
    }
  }

  // Color functions
  const getDateBgClass = (date) => {
    if (date.isPast) return 'bg-gray-50 border-gray-200'
    if (date.loadLevel === 'non_working') {
      return 'bg-gray-100 border-gray-300' // Серый - выходной
    }
    if (date.loadLevel === 'full') {
      return 'bg-red-100 border-red-300' // Красный - нет свободных слотов
    }
    if (date.bookedSlots > 0) {
      return 'bg-orange-100 border-orange-300' // Оранжевый - есть записи
    }
    if (date.availableSlots > 0) {
      return 'bg-green-50 border-green-300' // Зеленый - есть свободные слоты
    }
    return 'bg-gray-100 border-gray-300' // Серый - выходной
  }

  const getDateBorderClass = (date) => {
    if (date.isPast) return 'border-gray-200'
    if (date.loadLevel === 'full') {
      return 'border-red-300'
    }
    if (date.bookedSlots > 0) {
      return 'border-orange-300'
    }
    if (date.availableSlots > 0) {
      return 'border-green-300'
    }
    return 'border-gray-300'
  }

  return {
    currentDate,
    selectedDate,
    currentMonthName,
    currentYear,
    calendarDates,
    previousMonth,
    nextMonth,
    selectDate,
    setMasterId,
    getDateBgClass,
    getDateBorderClass,
    loadSlotsForVisibleDates,
  }
}
