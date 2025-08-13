import { ref, computed } from 'vue'
import { useAuthStore } from '../stores/auth'
import api from '../services/api'

export function useCalendar() {
  const authStore = useAuthStore()

  // Reactive data
  const currentDate = ref(new Date())
  const selectedDate = ref(null)
  const selectedDateBookings = ref([])
  const selectedDateSlots = ref([])
  const workingSchedules = ref([])
  const slotsCache = ref(new Map())
  const workingDayExceptions = ref([])

  // Computed properties
  const currentMonthYear = computed(() => {
    return currentDate.value.toLocaleDateString('ru-RU', {
      month: 'long',
      year: 'numeric',
    })
  })

  const nextMonthYear = computed(() => {
    const nextMonth = new Date(currentDate.value)
    nextMonth.setMonth(nextMonth.getMonth() + 1)
    return nextMonth.toLocaleDateString('ru-RU', {
      month: 'long',
      year: 'numeric',
    })
  })

  const isDayWorking = computed(() => {
    if (!selectedDate.value) return false

    // Исправляем проблему с датами - используем локальное время
    const dateString =
      selectedDate.value.getFullYear() +
      '-' +
      String(selectedDate.value.getMonth() + 1).padStart(2, '0') +
      '-' +
      String(selectedDate.value.getDate()).padStart(2, '0')
    const exception = workingDayExceptions.value.find((ex) => ex.date === dateString)

    if (exception) {
      return exception.is_working
    }

    const dayOfWeek = selectedDate.value.getDay()
    const schedule = workingSchedules.value.find((s) => s.day_of_week === dayOfWeek)
    return schedule ? schedule.is_working : false
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

      // Исправляем проблему с датами - используем локальное время
      // Локальный ключ даты (без ISO и UTC) — исправляет смещения 12→11 числа
      const dateString = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
      const daySlots = slotsCache.value.get(dateString) || []

      // Анализируем слоты для определения статуса дня
      const workSlots = daySlots.filter((slot) => slot.slot_type === 'work')
      const blockedSlots = daySlots.filter((slot) => slot.slot_type === 'blocked')
      const availableSlots = workSlots.filter((slot) => slot.is_available && !slot.booked)
      const bookedSlots = workSlots.filter((slot) => slot.booked)
      const pendingSlots = workSlots.filter(
        (slot) => slot.booking && slot.booking.status === 'pending',
      )

      // Общее количество слотов, которые могут быть забронированы (рабочие + заблокированные)
      const totalBookableSlots = workSlots.length + blockedSlots.length
      // Количество доступных слотов (только рабочие, которые доступны и не забронированы)
      const totalAvailableSlots = availableSlots.length

      // Определяем статус дня
      const dayOfWeek = date.getDay()
      const scheduleForDay = workingSchedules.value.find((s) => s.day_of_week === dayOfWeek)
      const exception = workingDayExceptions.value.find((ex) => ex.date === dateString)

      let loadLevel = 'non_working'
      let dayStatus = 'non_working'

      const isDayWorkingFinal = exception
        ? exception.is_working
        : scheduleForDay?.is_working || false

      if (isDayWorkingFinal) {
        if (totalAvailableSlots === 0) {
          loadLevel = 'full'
          dayStatus = 'busy'
        } else if (totalAvailableSlots < totalBookableSlots) {
          loadLevel = 'moderate'
          dayStatus = 'partial'
        } else {
          loadLevel = 'free'
          dayStatus = 'available'
        }
      } else {
        loadLevel = 'non_working'
        dayStatus = 'non_working'
      }

      dates.push({
        key: date.toISOString(),
        day: date.getDate(),
        date: date,
        isCurrentMonth: date.getMonth() === month,
        isToday: date.toDateString() === today.toDateString(),
        isSelected: selectedDate.value && date.toDateString() === selectedDate.value.toDateString(),
        isPast: date < today,
        hasPendingBookings: pendingSlots.length > 0,
        totalSlots: totalBookableSlots,
        availableSlots: totalAvailableSlots,
        bookedSlots: bookedSlots.length,
        pendingSlots: pendingSlots.length,
        loadLevel: loadLevel,
        dayStatus: dayStatus,
        slots: daySlots,
      })
    }

    return dates
  }

  const calendarDates = computed(() => {
    return generateCalendarDates(currentDate.value)
  })

  const nextMonthDates = computed(() => {
    const nextMonth = new Date(currentDate.value)
    nextMonth.setMonth(nextMonth.getMonth() + 1)
    return generateCalendarDates(nextMonth, true)
  })

  // API functions
  const loadWorkingSchedules = async () => {
    try {
      if (!authStore.token) {
        console.warn('No auth token available')
        workingSchedules.value = []
        return
      }

      const response = await fetch(`${api.baseURL}/working_schedules`, {
        headers: { Authorization: `Bearer ${authStore.token}` },
      })

      if (!response.ok) {
        throw new Error('Failed to fetch working schedules')
      }

      const schedulesData = await response.json()
      workingSchedules.value = schedulesData

      // loaded
    } catch (error) {
      console.error('Error loading working schedules:', error)
      workingSchedules.value = []
    }
  }

  const loadWorkingDayExceptions = async () => {
    try {
      if (!authStore.token) {
        console.warn('No auth token available')
        workingDayExceptions.value = []
        return
      }

      const exceptionsData = await api.getWorkingDayExceptions(authStore.token)
      workingDayExceptions.value = exceptionsData
    } catch (error) {
      console.error('Error loading working day exceptions:', error)
      workingDayExceptions.value = []
    }
  }

  const loadSlotsForDate = async (date) => {
    try {
      if (!authStore.token) {
        console.warn('No auth token available')
        return []
      }

      // Исправляем проблему с датами - используем локальное время вместо UTC
      const dateString =
        date.getFullYear() +
        '-' +
        String(date.getMonth() + 1).padStart(2, '0') +
        '-' +
        String(date.getDate()).padStart(2, '0')

      if (slotsCache.value.has(dateString)) {
        return slotsCache.value.get(dateString)
      }

      const response = await fetch(`${api.baseURL}/time_slots?date=${dateString}`, {
        headers: { Authorization: `Bearer ${authStore.token}` },
      })

      if (!response.ok) {
        console.error('Failed to fetch slots for', dateString, 'Status:', response.status)
        throw new Error('Failed to fetch time slots')
      }

      const slotsData = await response.json()

      slotsCache.value.set(dateString, slotsData.slots)

      return slotsData.slots
    } catch (error) {
      console.error('Error loading time slots for', date.toISOString().split('T')[0], ':', error)
      return []
    }
  }

  const loadSlotsForVisibleDates = async () => {
    try {
      const currentMonth = currentDate.value
      const nextMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1)

      const dates = []

      // Дни текущего месяца
      for (let i = 0; i < 42; i++) {
        const firstDayOfMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1)
        const startCalendarDate = new Date(firstDayOfMonth)
        startCalendarDate.setDate(
          startCalendarDate.getDate() -
            (firstDayOfMonth.getDay() === 0 ? 6 : firstDayOfMonth.getDay() - 1),
        )
        const date = new Date(startCalendarDate)
        date.setDate(startCalendarDate.getDate() + i)
        dates.push(date)
      }

      // Дни следующего месяца
      for (let i = 0; i < 42; i++) {
        const firstDayOfNextMonth = new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 1)
        const startCalendarDateNextMonth = new Date(firstDayOfNextMonth)
        startCalendarDateNextMonth.setDate(
          startCalendarDateNextMonth.getDate() -
            (firstDayOfNextMonth.getDay() === 0 ? 6 : firstDayOfNextMonth.getDay() - 1),
        )
        const date = new Date(startCalendarDateNextMonth)
        date.setDate(startCalendarDateNextMonth.getDate() + i)
        dates.push(date)
      }

      const uniqueDates = Array.from(new Set(dates.map((d) => d.toISOString().split('T')[0]))).map(
        (dateStr) => new Date(dateStr),
      )

      await Promise.all(uniqueDates.map((date) => loadSlotsForDate(date)))
    } catch (error) {
      console.error('Error loading slots for visible dates:', error)
    }
  }

  const loadSlotsForSelectedDate = async (date) => {
    try {
      const slots = await loadSlotsForDate(date)
      selectedDateSlots.value = slots
    } catch (error) {
      console.error('Error loading slots for selected date:', error)
      selectedDateSlots.value = []
    }
  }

  // Инвалидация кэша слотов для конкретной даты
  const invalidateCacheForDate = (date) => {
    if (!date) return
    // Исправляем проблему с датами - используем локальное время
    const key =
      date.getFullYear() +
      '-' +
      String(date.getMonth() + 1).padStart(2, '0') +
      '-' +
      String(date.getDate()).padStart(2, '0')
    slotsCache.value.delete(key)
  }

  const refreshCalendar = async () => {
    slotsCache.value.clear()
    await loadWorkingSchedules()
    await loadWorkingDayExceptions()
    await loadSlotsForVisibleDates()
  }

  // Calendar navigation functions
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

  const selectDate = async (date) => {
    selectedDate.value = date.date
    await loadSlotsForSelectedDate(date.date)
  }

  const toggleDayStatus = async () => {
    try {
      if (!selectedDate.value || !authStore.token) {
        console.warn('No selected date or auth token')
        return
      }

      // Исправляем проблему с датами - используем локальное время
      const dateString =
        selectedDate.value.getFullYear() +
        '-' +
        String(selectedDate.value.getMonth() + 1).padStart(2, '0') +
        '-' +
        String(selectedDate.value.getDate()).padStart(2, '0')
      

      const updatedException = await api.toggleWorkingDay(dateString, authStore.token)

      const existingIndex = workingDayExceptions.value.findIndex((ex) => ex.date === dateString)
      if (existingIndex !== -1) {
        workingDayExceptions.value[existingIndex] = updatedException
      } else {
        workingDayExceptions.value.push(updatedException)
      }

      const dateKey = dateString
      slotsCache.value.delete(dateKey)
      await loadSlotsForSelectedDate(selectedDate.value)

      
    } catch (error) {
      console.error('Error toggling day status:', error)
      if (typeof window !== 'undefined') {
        const { useToast } = await import('./useToast')
        useToast().show('Ошибка при изменении статуса дня: ' + error.message, 'red')
      }
    }
  }

  // Styling functions
  const getDateBgClass = (date) => {
    if (date.isPast) return 'bg-gray-50 border-gray-200'

    if (date.loadLevel === 'non_working') {
      return 'bg-gray-100 border-gray-300 cursor-not-allowed' // Серый - выходной
    }

    // Если есть слоты, но нет свободных (все слоты забронированы или заблокированы)
    if (date.totalSlots > 0 && date.availableSlots === 0) {
      return 'bg-red-100 border-red-300' // Красный - нет свободных слотов (приоритет над оранжевым)
    }

    // Если есть записи (bookedSlots > 0)
    if (date.bookedSlots > 0) {
      return 'bg-orange-100 border-orange-300' // Оранжевый - есть записи
    }

    // Если есть свободные слоты (рабочий день с доступными слотами)
    return 'bg-green-50 border-green-300' // Зеленый - рабочий день со свободными слотами
  }

  const getDateBorderClass = (date) => {
    if (date.isPast) return 'border-gray-200'

    if (date.loadLevel === 'non_working') {
      return 'border-gray-300' // Серый - выходной
    }

    // Если есть слоты, но нет свободных (все слоты забронированы или заблокированы)
    if (date.totalSlots > 0 && date.availableSlots === 0) {
      return 'border-red-300' // Красный - нет свободных слотов (приоритет над оранжевым)
    }

    // Если есть записи (bookedSlots > 0)
    if (date.bookedSlots > 0) {
      return 'border-orange-300' // Оранжевый - есть записи
    }

    // Если есть свободные слоты (рабочий день с доступными слотами)
    return 'border-green-300' // Зеленый - рабочий день со свободными слотами
  }

  const getBookingDotClass = (date) => {
    if (date.loadLevel === 'non_working') {
      return 'bg-gray-400' // Серые точки для выходного
    }

    // Если есть слоты, но нет свободных (все слоты забронированы или заблокированы)
    if (date.totalSlots > 0 && date.availableSlots === 0) {
      return 'bg-red-400' // Красные точки для дня без свободных слотов (приоритет над оранжевым)
    }

    // Если есть записи (bookedSlots > 0)
    if (date.bookedSlots > 0) {
      return 'bg-orange-400' // Оранжевые точки для дней с записями
    }

    // Если есть свободные слоты (рабочий день с доступными слотами)
    return 'bg-green-400' // Зеленые точки для свободных рабочих дней
  }

  const formatSelectedDate = () => {
    if (!selectedDate.value) return ''
    return selectedDate.value.toLocaleDateString('ru-RU', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    })
  }

  return {
    // State
    currentDate,
    selectedDate,
    selectedDateBookings,
    selectedDateSlots,
    workingSchedules,
    slotsCache,
    workingDayExceptions,

    // Computed
    currentMonthYear,
    nextMonthYear,
    isDayWorking,
    calendarDates,
    nextMonthDates,

    // Functions
    loadWorkingSchedules,
    loadWorkingDayExceptions,
    loadSlotsForDate,
    loadSlotsForVisibleDates,
    loadSlotsForSelectedDate,
    invalidateCacheForDate,
    refreshCalendar,
    previousMonth,
    nextMonth,
    selectDate,
    toggleDayStatus,
    getDateBgClass,
    getDateBorderClass,
    getBookingDotClass,
    formatSelectedDate,
  }
}
