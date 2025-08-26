import { ref, computed, onMounted, onActivated, nextTick } from 'vue'
import { createCalendarStyleUtils } from './useCalendarUtils'
import { useAuthStore } from '../stores/auth'
import api from '../services/api'
import { useFormatters } from './useFormatters'

export function useMasterCalendar() {
  const authStore = useAuthStore()

  // Calendar data
  const currentDate = ref(new Date())
  const selectedDate = ref(null)
  const selectedDateSlots = ref([])
  const workingSchedules = ref([])
  const slotsCache = ref(new Map()) // Кэш слотов по датам
  const workingDayExceptions = ref([]) // Исключения по дням
  const isLoadingVisibleDates = ref(false)

  // Computed properties
  const isDayWorking = computed(() => {
    if (!selectedDate.value) return false

    const dateString = `${selectedDate.value.getFullYear()}-${String(selectedDate.value.getMonth() + 1).padStart(2, '0')}-${String(selectedDate.value.getDate()).padStart(2, '0')}`
    const exception = workingDayExceptions.value.find((ex) => ex.date === dateString)

    if (exception) {
      // Исключение имеет приоритет
      return !!exception.is_working
    }

    // Используем расписание
    const dayOfWeek = selectedDate.value.getDay()
    const schedule = workingSchedules.value.find((s) => s.day_of_week === dayOfWeek)
    return !!(schedule && schedule.is_working)
  })

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

  const calendarDates = computed(() => {
    const year = currentDate.value.getFullYear()
    const month = currentDate.value.getMonth()

    const firstDay = new Date(year, month, 1)
    const startDate = new Date(firstDay)
    startDate.setDate(startDate.getDate() - (firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1))

    const dates = []
    const today = new Date()

    for (let i = 0; i < 42; i++) {
      const date = new Date(startDate)
      date.setDate(startDate.getDate() + i)

      // ВАЖНО: используем локальную дату как ключ, чтобы не было смещения дня при TZ
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

      // Количество доступных слотов (только рабочие, которые доступны и не забронированы)
      const totalAvailableSlots = availableSlots.length

      // Определяем статус дня на основе расписания, исключений и слотов (CURRENT MONTH)
      const dayOfWeek = date.getDay() // 0 for Sunday, 1 for Monday, etc.
      const scheduleForDay = workingSchedules.value.find((s) => s.day_of_week === dayOfWeek)
      const exception = workingDayExceptions.value.find((ex) => ex.date === dateString)

      let loadLevel = 'non_working' // не рабочий день по умолчанию
      let dayStatus = 'non_working'

      // Определяем, является ли день рабочим (исключение имеет приоритет над расписанием)
      const isDayWorkingFinal = exception
        ? exception.is_working
        : scheduleForDay?.is_working || false

      if (isDayWorkingFinal) {
        // Если день явно помечен как рабочий в настройках
        if (workSlots.length === 0) {
          // Раньше мы помечали такой день как "свободный", что давало зелёные дни без слотов.
          // Теперь явно считаем такой день "non_working" визуально, пока слоты не появятся.
          loadLevel = 'non_working'
          dayStatus = 'non_working'
        } else {
          // Если есть рабочие слоты, определяем уровень загруженности
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
        // Если день не помечен как рабочий в настройках
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
        totalSlots: workSlots.length + blockedSlots.length,
        availableSlots: totalAvailableSlots,
        bookedSlots: bookedSlots.length,
        pendingSlots: pendingSlots.length,
        loadLevel: loadLevel,
        dayStatus: dayStatus,
        slots: daySlots,
      })
    }

    return dates
  })

  const nextMonthDates = computed(() => {
    const year = currentDate.value.getFullYear()
    const month = currentDate.value.getMonth() + 1

    const firstDay = new Date(year, month, 1)
    const startDate = new Date(firstDay)
    startDate.setDate(startDate.getDate() - (firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1))

    const dates = []
    const today = new Date()

    for (let i = 0; i < 42; i++) {
      const date = new Date(startDate)
      date.setDate(startDate.getDate() + i)

      // ВАЖНО: используем локальную дату как ключ, чтобы не было смещения дня при TZ
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

      // Количество доступных слотов (только рабочие, которые доступны и не забронированы)
      const totalAvailableSlots = availableSlots.length

      // Определяем статус дня на основе расписания, исключений и слотов (NEXT MONTH)
      const dayOfWeek = date.getDay() // 0 for Sunday, 1 for Monday, etc.
      const scheduleForDay = workingSchedules.value.find((s) => s.day_of_week === dayOfWeek)
      const exception = workingDayExceptions.value.find((ex) => ex.date === dateString)

      let loadLevel = 'non_working' // не рабочий день по умолчанию
      let dayStatus = 'non_working'

      // Определяем, является ли день рабочим (исключение имеет приоритет над расписанием)
      const isDayWorkingFinal = exception
        ? exception.is_working
        : scheduleForDay?.is_working || false

      if (isDayWorkingFinal) {
        // Если день явно помечен как рабочий в настройках
        if (workSlots.length === 0) {
          // Не подсвечиваем зелёным дни без реальных слотов
          loadLevel = 'non_working'
          dayStatus = 'non_working'
        } else {
          // Если есть рабочие слоты, определяем уровень загруженности
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
        // Если день не помечен как рабочий в настройках
        loadLevel = 'non_working'
        dayStatus = 'non_working'
      }

      dates.push({
        key: date.toISOString(),
        day: date.getDate(),
        date: date,
        isCurrentMonth: date.getMonth() === month - 1,
        isToday: date.toDateString() === today.toDateString(),
        isSelected: selectedDate.value && date.toDateString() === selectedDate.value.toDateString(),
        isPast: date < today,
        hasPendingBookings: pendingSlots.length > 0,
        totalSlots: workSlots.length + blockedSlots.length,
        availableSlots: totalAvailableSlots,
        bookedSlots: bookedSlots.length,
        pendingSlots: pendingSlots.length,
        loadLevel: loadLevel,
        dayStatus: dayStatus,
        slots: daySlots,
      })
    }

    return dates
  })

  // Calendar functions
  const loadWorkingSchedules = async () => {
    try {
      if (!authStore.token) {
        workingSchedules.value = []
        return
      }

      const schedulesData = await api.getWorkingSchedules(authStore.token)
      workingSchedules.value = schedulesData
    } catch (error) {
      console.error('Error loading working schedules:', error)
      workingSchedules.value = []
    }
  }

  const loadWorkingDayExceptions = async () => {
    try {
      if (!authStore.token) {
        // Попробуем восстановить пользователя/токен из профиля, если есть
        try {
          await authStore.getCurrentUser()
        } catch (err) {
          console.debug('getCurrentUser failed in loadWorkingDayExceptions:', err)
        }
      }
      if (!authStore.token) {
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

  const toggleDayStatus = async () => {
    try {
      if (!selectedDate.value) return
      if (!authStore.token) {
        try {
          await authStore.getCurrentUser()
        } catch (err) {
          console.debug('getCurrentUser failed in toggleDayStatus (pre-check):', err)
        }
      }
      if (!authStore.token) return

      const dateString = `${selectedDate.value.getFullYear()}-${String(selectedDate.value.getMonth() + 1).padStart(2, '0')}-${String(selectedDate.value.getDate()).padStart(2, '0')}`

      // Оптимистичное обновление — мгновенная анимация переключателя
      const currentIsWorking = isDayWorking.value
      const idx = workingDayExceptions.value.findIndex((ex) => ex.date === dateString)
      const prevException = idx !== -1 ? { ...workingDayExceptions.value[idx] } : null
      const optimistic = {
        id: prevException?.id,
        date: dateString,
        is_working: !currentIsWorking,
        reason: prevException?.reason || null,
      }
      if (idx !== -1) {
        workingDayExceptions.value[idx] = optimistic
      } else {
        workingDayExceptions.value.push(optimistic)
      }
      slotsCache.value.delete(dateString)

      // Серверный вызов
      let updatedException
      try {
        updatedException = await api.toggleWorkingDay(dateString, authStore.token)
      } catch (err) {
        // Если 401 — пробуем обновить профиль и повторить один раз
        if (err && err.status === 401) {
          await authStore.getCurrentUser()
          updatedException = await api.toggleWorkingDay(dateString, authStore.token)
        } else {
          throw err
        }
      }

      // Приводим локальное состояние к серверному
      const existingIndex = workingDayExceptions.value.findIndex((ex) => ex.date === dateString)
      if (existingIndex !== -1) {
        workingDayExceptions.value[existingIndex] = updatedException
      } else {
        workingDayExceptions.value.push(updatedException)
      }

      await loadSlotsForSelectedDate(selectedDate.value)
    } catch (error) {
      // Откат, если сервер вернул ошибку
      try {
        if (selectedDate.value) {
          const dateString = `${selectedDate.value.getFullYear()}-${String(selectedDate.value.getMonth() + 1).padStart(2, '0')}-${String(selectedDate.value.getDate()).padStart(2, '0')}`
          const idx = workingDayExceptions.value.findIndex((ex) => ex.date === dateString)
          if (idx !== -1) workingDayExceptions.value.splice(idx, 1)
          await loadSlotsForSelectedDate(selectedDate.value)
        }
      } catch (rollbackErr) {
        console.debug('Rollback after toggleDayStatus failed:', rollbackErr)
      }
      console.error('Error toggling day status:', error)
      if (typeof window !== 'undefined') {
        const { useToast } = await import('../composables/useToast')
        useToast().show('Ошибка при изменении статуса дня: ' + error.message, 'red')
      }
    }
  }

  const loadSlotsForDate = async (date) => {
    try {
      if (!authStore.token) {
        try {
          await authStore.getCurrentUser()
        } catch (err) {
          console.debug('getCurrentUser failed in loadSlotsForDate:', err)
        }
      }
      if (!authStore.token) {
        console.warn('No auth token available')
        return []
      }

      const dateString = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`

      // Проверяем кэш
      if (slotsCache.value.has(dateString)) {
        return slotsCache.value.get(dateString)
      }

      const slotsData = await api.getTimeSlots(dateString, authStore.token)

      // Строгая сортировка по времени начала на клиенте, чтобы исключить визуальные скачки
      const sorted = (slotsData.slots || []).slice().sort((a, b) => {
        const toMinutes = (s) => {
          const [h, m] = String(s.start_time || '00:00')
            .split(':')
            .map((v) => parseInt(v, 10))
          return h * 60 + m
        }
        return toMinutes(a) - toMinutes(b)
      })

      // Сохраняем в кэш
      slotsCache.value.set(dateString, sorted)

      return sorted
    } catch (error) {
      console.error('Error loading time slots for', date.toISOString().split('T')[0], ':', error)
      return []
    }
  }

  const loadSlotsForVisibleDates = async () => {
    if (isLoadingVisibleDates?.value) return
    isLoadingVisibleDates.value = true
    try {
      const currentMonth = currentDate.value
      const nextMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1)

      // Загружаем слоты для текущего и следующего месяца
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

      // Убираем дубликаты
      const uniqueDates = Array.from(
        new Set(
          dates.map(
            (d) =>
              `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`,
          ),
        ),
      ).map((dateStr) => new Date(dateStr))

      // Загружаем слоты для всех дат параллельно
      await Promise.all(uniqueDates.map((date) => loadSlotsForDate(date)))
    } catch (error) {
      console.error('Error loading slots for visible dates:', error)
    } finally {
      isLoadingVisibleDates.value = false
    }
  }

  const refreshCalendar = async () => {
    // Очищаем весь кэш слотов
    slotsCache.value.clear()

    // Перезагружаем слоты для видимых дат
    await loadSlotsForVisibleDates()

    // Если есть выбранная дата, перезагружаем её данные
    if (selectedDate.value) {
      await loadSlotsForSelectedDate(selectedDate.value)
    }
  }

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
    await nextTick()
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

  const onToggleSlotBreak = async (slot, isBreakNext) => {
    // Оптимистичное обновление для мгновенной реакции UI
    const dateKey = selectedDate.value
      ? `${selectedDate.value.getFullYear()}-${String(selectedDate.value.getMonth() + 1).padStart(2, '0')}-${String(selectedDate.value.getDate()).padStart(2, '0')}`
      : null

    const prevSlots = [...selectedDateSlots.value]
    const nextSlots = selectedDateSlots.value.map((s) => {
      if (s.id !== slot.id) return s
      if (isBreakNext) {
        return { ...s, slot_type: 'blocked', is_available: false }
      }
      return { ...s, slot_type: 'work', is_available: true }
    })
    selectedDateSlots.value = nextSlots
    if (dateKey) slotsCache.value.set(dateKey, nextSlots)

    try {
      if (!authStore.token) throw new Error('Не авторизован')
      await api.updateTimeSlot(slot.id, { is_break: isBreakNext }, authStore.token)
      if (selectedDate.value) {
        slotsCache.value.delete(dateKey)
        await loadSlotsForSelectedDate(selectedDate.value)
      }
    } catch (e) {
      // Откат при ошибке
      selectedDateSlots.value = prevSlots
      if (dateKey) slotsCache.value.set(dateKey, prevSlots)
      console.error('Failed to toggle break for slot', slot.id, e)
      if (typeof window !== 'undefined') {
        const { useToast } = await import('../composables/useToast')
        useToast().show('Не удалось изменить статус слота: ' + e.message, 'red')
      }
    }
  }

  const addNewSlot = async () => {
    if (!selectedDate.value || !authStore.token) {
      console.warn('No selected date or auth token')
      return
    }

    // isAddingSlot.value = true // will be handled in MasterDashboard

    try {
      const dateString = `${selectedDate.value.getFullYear()}-${String(selectedDate.value.getMonth() + 1).padStart(2, '0')}-${String(selectedDate.value.getDate()).padStart(2, '0')}`

      await api.addTimeSlot(dateString, authStore.token)

      // Очищаем кэш и перезагружаем слоты
      slotsCache.value.delete(dateString)
      await loadSlotsForSelectedDate(selectedDate.value)
    } catch (error) {
      console.error('Error adding new slot:', error)
      if (typeof window !== 'undefined') {
        const { useToast } = await import('../composables/useToast')
        useToast().show(
          'Ошибка при добавлении нового слота: ' +
            (error && error.message ? error.message : 'Неизвестная ошибка'),
          'red',
        )
      }
    } finally {
      // isAddingSlot.value = false // will be handled in MasterDashboard
    }
  }

  // Calendar styling methods
  const { getDateBgClass, getDateHoverBgClass, getDateBorderClass, getBookingDotClass } =
    createCalendarStyleUtils()

  // Slot helper functions from shared formatters
  const { getSlotTypeText, getSlotStatusClass, getSlotStatusText, isBreak } = useFormatters()

  onMounted(async () => {
    await loadWorkingSchedules()
    await loadWorkingDayExceptions()
    await loadSlotsForVisibleDates()
  })

  onActivated(() => {
    slotsCache.value.clear()
    loadSlotsForVisibleDates()
  })

  return {
    currentDate,
    selectedDate,
    selectedDateSlots,
    workingSchedules,
    slotsCache,
    workingDayExceptions,
    isDayWorking,
    currentMonthYear,
    nextMonthYear,
    calendarDates,
    nextMonthDates,
    previousMonth,
    nextMonth,
    selectDate,
    loadSlotsForSelectedDate,
    toggleDayStatus,
    addNewSlot,
    refreshCalendar,
    getDateBgClass,
    getDateHoverBgClass,
    getDateBorderClass,
    getBookingDotClass,
    getSlotTypeText,
    getSlotStatusClass,
    getSlotStatusText,
    isBreak,
    onToggleSlotBreak,
  }
}
