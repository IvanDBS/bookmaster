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
      year: 'numeric' 
    })
  })

  const nextMonthYear = computed(() => {
    const nextMonth = new Date(currentDate.value)
    nextMonth.setMonth(nextMonth.getMonth() + 1)
    return nextMonth.toLocaleDateString('ru-RU', { 
      month: 'long', 
      year: 'numeric' 
    })
  })

  const isDayWorking = computed(() => {
    if (!selectedDate.value) return false
    
    const dateString = selectedDate.value.toISOString().split('T')[0]
    const exception = workingDayExceptions.value.find(ex => ex.date === dateString)
    
    if (exception) {
      return exception.is_working
    }
    
    const dayOfWeek = selectedDate.value.getDay()
    const schedule = workingSchedules.value.find(s => s.day_of_week === dayOfWeek)
    return schedule ? schedule.is_working : false
  })

  // Calendar date generation functions
  const generateCalendarDates = (baseDate, isNextMonth = false) => {
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
      
      const dateString = date.toISOString().split('T')[0]
      const daySlots = slotsCache.value.get(dateString) || []
      
      // Анализируем слоты для определения статуса дня
      const workSlots = daySlots.filter(slot => slot.slot_type === 'work')
      const availableSlots = workSlots.filter(slot => slot.is_available && !slot.booked)
      const bookedSlots = workSlots.filter(slot => slot.booked)
      const pendingSlots = workSlots.filter(slot => slot.booking && slot.booking.status === 'pending')
      
      // Определяем статус дня
      const dayOfWeek = date.getDay()
      const scheduleForDay = workingSchedules.value.find(s => s.day_of_week === dayOfWeek)
      const exception = workingDayExceptions.value.find(ex => ex.date === dateString)

      let loadLevel = 'non_working'
      let dayStatus = 'non_working'
      
      const isDayWorkingFinal = exception ? exception.is_working : (scheduleForDay?.is_working || false)

      if (isDayWorkingFinal) {
        if (workSlots.length === 0) {
          loadLevel = 'free'
          dayStatus = 'available'
        } else {
          const totalSlots = workSlots.length
          const occupiedSlots = bookedSlots.length
          const occupancyRate = totalSlots > 0 ? occupiedSlots / totalSlots : 0

          if (occupancyRate === 0) {
            loadLevel = 'free'
            dayStatus = 'available'
          } else if (occupancyRate < 0.3) {
            loadLevel = 'light'
            dayStatus = 'available'
          } else if (occupancyRate < 0.7) {
            loadLevel = 'moderate'
            dayStatus = 'partial'
          } else if (occupancyRate < 1) {
            loadLevel = 'busy'
            dayStatus = 'partial'
          } else {
            loadLevel = 'full'
            dayStatus = 'busy'
          }
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
        totalSlots: workSlots.length,
        availableSlots: availableSlots.length,
        bookedSlots: bookedSlots.length,
        pendingSlots: pendingSlots.length,
        loadLevel: loadLevel,
        dayStatus: dayStatus,
        slots: daySlots
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

      const response = await fetch('http://localhost:3000/api/v1/working_schedules', {
        headers: {
          'Authorization': `Bearer ${authStore.token}`,
        },
      })
      
      if (!response.ok) {
        throw new Error('Failed to fetch working schedules')
      }
      
      const schedulesData = await response.json()
      workingSchedules.value = schedulesData
      
      console.log('Loaded working schedules:', workingSchedules.value)
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
      
      console.log('Loaded working day exceptions:', workingDayExceptions.value.length)
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

      const dateString = date.toISOString().split('T')[0]
      
      if (slotsCache.value.has(dateString)) {
        console.log(`Cache HIT for ${dateString}. Slots:`, slotsCache.value.get(dateString).length)
        return slotsCache.value.get(dateString)
      }

      console.log('Loading slots for date:', dateString)

      const response = await fetch(`http://localhost:3000/api/v1/time_slots?date=${dateString}`, {
        headers: {
          'Authorization': `Bearer ${authStore.token}`,
        },
      })
      
      if (!response.ok) {
        console.error('Failed to fetch slots for', dateString, 'Status:', response.status)
        throw new Error('Failed to fetch time slots')
      }
      
      const slotsData = await response.json()
      console.log('Received slots for', dateString, ':', slotsData.slots.length, 'Slots data:', slotsData.slots)
      
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
        startCalendarDate.setDate(startCalendarDate.getDate() - (firstDayOfMonth.getDay() === 0 ? 6 : firstDayOfMonth.getDay() - 1))
        const date = new Date(startCalendarDate)
        date.setDate(startCalendarDate.getDate() + i)
        dates.push(date)
      }
      
      // Дни следующего месяца
      for (let i = 0; i < 42; i++) {
        const firstDayOfNextMonth = new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 1)
        const startCalendarDateNextMonth = new Date(firstDayOfNextMonth)
        startCalendarDateNextMonth.setDate(startCalendarDateNextMonth.getDate() - (firstDayOfNextMonth.getDay() === 0 ? 6 : firstDayOfNextMonth.getDay() - 1))
        const date = new Date(startCalendarDateNextMonth)
        date.setDate(startCalendarDateNextMonth.getDate() + i)
        dates.push(date)
      }
      
      const uniqueDates = Array.from(new Set(dates.map(d => d.toISOString().split('T')[0])))
                               .map(dateStr => new Date(dateStr))
      
      await Promise.all(uniqueDates.map(date => loadSlotsForDate(date)))
      
      console.log('Loaded slots for dates:', uniqueDates.length)
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

  const refreshCalendar = async () => {
    console.log('Refreshing calendar...')
    slotsCache.value.clear()
    await loadWorkingSchedules()
    await loadWorkingDayExceptions()
    await loadSlotsForVisibleDates()
    console.log('Calendar refreshed')
  }

  // Calendar navigation functions
  const previousMonth = () => {
    currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() - 1, 1)
    loadSlotsForVisibleDates()
  }

  const nextMonth = () => {
    currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() + 1, 1)
    loadSlotsForVisibleDates()
  }

  const selectDate = async (date) => {
    console.log(`Selecting date: ${date.date.toDateString()}`)
    selectedDate.value = date.date
    await loadSlotsForSelectedDate(date.date)
  }

  const toggleDayStatus = async () => {
    try {
      if (!selectedDate.value || !authStore.token) {
        console.warn('No selected date or auth token')
        return
      }

      const dateString = selectedDate.value.toISOString().split('T')[0]
      console.log('Toggling day status for:', dateString)
      
      const updatedException = await api.toggleWorkingDay(dateString, authStore.token)
      
      const existingIndex = workingDayExceptions.value.findIndex(ex => ex.date === dateString)
      if (existingIndex !== -1) {
        workingDayExceptions.value[existingIndex] = updatedException
      } else {
        workingDayExceptions.value.push(updatedException)
      }
      
      const dateKey = dateString
      slotsCache.value.delete(dateKey)
      await loadSlotsForSelectedDate(selectedDate.value)
      
      console.log('Day status toggled successfully:', updatedException)
    } catch (error) {
      console.error('Error toggling day status:', error)
      alert('Ошибка при изменении статуса дня: ' + error.message)
    }
  }

  // Styling functions
  const getDateBgClass = (date) => {
    if (date.isPast) return 'bg-gray-50 border-gray-200'
    
    if (date.loadLevel === 'non_working') {
      return 'bg-gray-100 border-gray-300 cursor-not-allowed'
    }
    
    if (date.loadLevel === 'free') {
      return 'bg-green-50 border-green-200 hover:bg-green-100'
    }
    
    if (date.totalSlots === 0) {
      return 'bg-red-50 border-red-200 hover:bg-red-100'
    }

    return 'bg-green-50 border-green-200 hover:bg-green-100'
  }

  const getDateBorderClass = (date) => {
    if (date.isPast) return 'border-gray-200'
    
    if (date.loadLevel === 'non_working') {
      return 'border-gray-300'
    }
    
    if (date.loadLevel === 'free') {
      return 'border-green-200'
    }
    
    if (date.totalSlots === 0) {
      return 'border-red-200'
    }

    return 'border-green-200'
  }

  const getBookingDotClass = (date) => {
    if (date.loadLevel === 'non_working') {
      return 'bg-gray-400'
    }
    
    if (date.loadLevel === 'free') {
      return 'bg-green-400'
    }
    
    if (date.totalSlots === 0) {
      return 'bg-red-400'
    }

    return 'bg-green-400'
  }

  const formatSelectedDate = () => {
    if (!selectedDate.value) return ''
    return selectedDate.value.toLocaleDateString('ru-RU', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
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
    refreshCalendar,
    previousMonth,
    nextMonth,
    selectDate,
    toggleDayStatus,
    getDateBgClass,
    getDateBorderClass,
    getBookingDotClass,
    formatSelectedDate
  }
} 