<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <AppHeader :show-navigation="true" user-type="master" :pending-bookings-count="0" />

    <!-- Main Content -->
    <div class="max-w-4xl mx-auto px-6 py-8 mt-20">
      <!-- Welcome Section -->
      <div class="mb-8">
        <div class="flex items-center justify-between">
          <div>
            <h2 class="text-3xl font-bold text-gray-900 mb-2">Настройки расписания</h2>
            <p class="text-gray-600">Управляйте своим рабочим временем и выходными днями</p>
          </div>
          <button
            @click="goBackToDashboard"
            class="bg-gray-600 hover:bg-gray-700 text-white font-medium px-4 py-2 rounded-lg transition-colors text-sm"
          >
            ← Назад к календарю
          </button>
        </div>
      </div>

      <!-- Working Schedule Form -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Рабочее расписание</h3>
        </div>
        <div class="p-6">
          <form @submit.prevent="saveSchedule">
            <!-- Days of Week -->
            <div class="space-y-4">
              <h4 class="font-medium text-gray-900 mb-4">Дни недели</h4>

              <div
                v-for="schedule in workingSchedules"
                :key="schedule.id"
                class="border border-gray-200 rounded-lg p-4"
              >
                <div class="flex items-center justify-between mb-4">
                  <div class="flex items-center space-x-3">
                    <input
                      type="checkbox"
                      :id="`day-${schedule.day_of_week}`"
                      v-model="schedule.is_working"
                      @change="handleWorkingDayChange(schedule)"
                      class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                    />
                    <label :for="`day-${schedule.day_of_week}`" class="font-medium text-gray-900">
                      {{ schedule.day_name }}
                    </label>
                  </div>
                  <span v-if="schedule.is_working" class="text-green-600 text-sm font-medium">
                    Рабочий день
                  </span>
                  <span v-else class="text-gray-500 text-sm"> Выходной </span>
                </div>

                <!-- Working Hours (only if is_working) -->
                <div v-if="schedule.is_working" class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Время начала работы
                    </label>
                    <TimeSelect v-model="schedule.start_time" :step="30" />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Время окончания работы
                    </label>
                    <TimeSelect v-model="schedule.end_time" :step="30" />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Начало обеда
                    </label>
                    <TimeSelect v-model="schedule.lunch_start" :step="30" />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Конец обеда
                    </label>
                    <div class="flex space-x-2">
                      <TimeSelect v-model="schedule.lunch_end" :step="30" />
                      <button
                        type="button"
                        @click="clearLunch(schedule)"
                        class="px-3 py-2 text-sm text-gray-600 border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        title="Убрать обед"
                      >
                        Без обеда
                      </button>
                    </div>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Длительность слота (минуты)
                    </label>
                    <input
                      type="number"
                      v-model="schedule.slot_duration_minutes"
                      min="15"
                      max="120"
                      step="15"
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
              </div>
            </div>

            <!-- Save Button -->
            <div class="mt-8 flex justify-end">
              <button
                type="submit"
                :disabled="saving"
                class="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-semibold px-6 py-3 rounded-lg transition-colors"
              >
                {{ saving ? 'Сохранение...' : 'Сохранить расписание' }}
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Быстрые действия</h3>
        </div>
        <div class="p-6">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <button
              @click="setDefaultSchedule"
              class="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors text-left"
            >
              <h4 class="font-medium text-gray-900 mb-2">Стандартное расписание</h4>
              <p class="text-sm text-gray-600">Пн-Пт 9:00-18:00, обед 13:00-14:00</p>
            </button>
            <button
              @click="setWeekendSchedule"
              class="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors text-left"
            >
              <h4 class="font-medium text-gray-900 mb-2">Только будни</h4>
              <p class="text-sm text-gray-600">Пн-Пт рабочие, Сб-Вс выходные</p>
            </button>
            <button
              @click="setFullWeekSchedule"
              class="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors text-left"
            >
              <h4 class="font-medium text-gray-900 mb-2">Вся неделя</h4>
              <p class="text-sm text-gray-600">Все дни рабочие</p>
            </button>
          </div>
        </div>
      </div>

      <!-- Information -->
      <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <h4 class="font-medium text-blue-900 mb-2">ℹ️ Как это работает</h4>
        <ul class="text-sm text-blue-800 space-y-1">
          <li>• Рабочие дни определяют, когда доступны слоты для записи</li>
          <li>• Обеденное время автоматически исключается из доступных слотов</li>
          <li>
            • Длительность слота определяет интервалы записи (например, 60 мин = слоты по часу)
          </li>
          <li>• Изменения применяются к будущим датам, существующие записи не затрагиваются</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import api from '../services/api'
import AppHeader from '../components/AppHeader.vue'
import TimeSelect from '../components/common/TimeSelect.vue'

const authStore = useAuthStore()
const router = useRouter()

// Reactive data
const workingSchedules = ref([])
const saving = ref(false)

// Day names mapping
const dayNames = {
  0: 'Воскресенье',
  1: 'Понедельник',
  2: 'Вторник',
  3: 'Среда',
  4: 'Четверг',
  5: 'Пятница',
  6: 'Суббота',
}

onMounted(async () => {
  await loadWorkingSchedules()
})

const loadWorkingSchedules = async () => {
  try {
    if (!authStore.token) {
      console.warn('No auth token available')
      return
    }

    const schedulesData = await api.getWorkingSchedules(authStore.token)

    // Backend теперь отдаёт и "*_hhmm" (строки HH:MM). Используем их в приоритете.
    workingSchedules.value = schedulesData.map((schedule) => {
      const formattedSchedule = {
        ...schedule,
        day_name: dayNames[schedule.day_of_week],
      }

      const pickHHmm = (s, baseKey) => {
        // 1) prefer *_hhmm directly from SQL to avoid TZ
        const sqlKey = `${baseKey}_hhmm`
        if (s && typeof s[sqlKey] === 'string' && /^\d{2}:\d{2}$/.test(s[sqlKey])) return s[sqlKey]
        // 2) fallback: try to extract HH:MM from ISO string
        const raw = s ? s[baseKey] : null
        if (typeof raw === 'string') {
          const t = raw.includes('T') ? raw.split('T')[1] : raw
          const hhmm = t.slice(0, 5)
          return /^\d{2}:\d{2}$/.test(hhmm) ? hhmm : null
        }
        return null
      }

      formattedSchedule.start_time = formattedSchedule.is_working
        ? pickHHmm(schedule, 'start_time')
        : null
      formattedSchedule.end_time = formattedSchedule.is_working
        ? pickHHmm(schedule, 'end_time')
        : null
      formattedSchedule.lunch_start = formattedSchedule.is_working
        ? pickHHmm(schedule, 'lunch_start')
        : null
      formattedSchedule.lunch_end = formattedSchedule.is_working
        ? pickHHmm(schedule, 'lunch_end')
        : null

      formattedSchedule.slot_duration_minutes = formattedSchedule.is_working
        ? Number(schedule.slot_duration_minutes || 30)
        : null

      return formattedSchedule
    })

    // Sort by day of week (Monday first, Sunday last)
    workingSchedules.value.sort((a, b) => {
      const dayA = a.day_of_week === 0 ? 7 : a.day_of_week
      const dayB = b.day_of_week === 0 ? 7 : b.day_of_week
      return dayA - dayB
    })

    // Больше не автозаполняем время и обед — оставляем как в БД, чтобы не навязывать значения.
    workingSchedules.value.forEach((schedule) => {
      if (!schedule.is_working) {
        schedule.start_time = null
        schedule.end_time = null
        schedule.lunch_start = null
        schedule.lunch_end = null
        schedule.slot_duration_minutes = null
      } else {
        if (!schedule.slot_duration_minutes) schedule.slot_duration_minutes = 60
      }
    })
  } catch (error) {
    console.error('Error loading working schedules:', error)
    workingSchedules.value = []
  }
}

const saveSchedule = async () => {
  saving.value = true

  try {
    if (!authStore.token) {
      throw new Error('Не авторизован')
    }

    // Локальная валидация: интервалы не могут пересекать полночь;
    // обед, выходящий за пределы интервала, очищаем.
    const toMinutes = (hhmm) => {
      if (!hhmm || typeof hhmm !== 'string') return null
      const [h, m] = hhmm.split(':').map((v) => parseInt(v, 10))
      return h * 60 + m
    }

    for (const schedule of workingSchedules.value) {
      // Проверяем валидность данных перед отправкой
      if (schedule.is_working && schedule.start_time && schedule.end_time) {
        const s = toMinutes(schedule.start_time)
        const e = toMinutes(schedule.end_time)
        if (e === null || s === null) throw new Error('Неверный формат времени')
        if (e <= s) {
          throw new Error(
            `День «${schedule.day_name}»: интервал не может пересекать полночь. Время окончания должно быть позже начала.`,
          )
        }
        if (schedule.lunch_start && schedule.lunch_end) {
          const ls = toMinutes(schedule.lunch_start)
          const le = toMinutes(schedule.lunch_end)
          if (!(ls >= s && le <= e && le > ls)) {
            // очищаем обед, чтобы не блокировать сохранение
            schedule.lunch_start = null
            schedule.lunch_end = null
          }
        }
      }

      const scheduleData = {
        working_schedule: {
          is_working: schedule.is_working,
          start_time: schedule.is_working ? schedule.start_time : null,
          end_time: schedule.is_working ? schedule.end_time : null,
          lunch_start: schedule.is_working ? schedule.lunch_start : null,
          lunch_end: schedule.is_working ? schedule.lunch_end : null,
          slot_duration_minutes: schedule.is_working ? schedule.slot_duration_minutes || 60 : null,
        },
      }

      await api.updateWorkingSchedule(schedule.id, scheduleData.working_schedule, authStore.token)

      // Небольшая задержка между запросами
      await new Promise((resolve) => setTimeout(resolve, 100))
    }

    // Перезагружаем данные после сохранения
    await loadWorkingSchedules()

    // Очищаем кэш слотов в sessionStorage для принудительного обновления календаря
    sessionStorage.setItem('clearSlotsCache', 'true')

    if (typeof window !== 'undefined') {
      const { useToast } = await import('../composables/useToast')
      useToast().show('Расписание успешно сохранено!')
    }
  } catch (error) {
    console.error('Error saving schedule:', error)
    if (typeof window !== 'undefined') {
      const { useToast } = await import('../composables/useToast')
      useToast().show('Ошибка при сохранении расписания: ' + error.message, 'red')
    }
  } finally {
    saving.value = false
  }
}

const setDefaultSchedule = () => {
  workingSchedules.value.forEach((schedule) => {
    if (schedule.day_of_week >= 1 && schedule.day_of_week <= 5) {
      // Weekdays
      schedule.is_working = true
      schedule.start_time = '09:00'
      schedule.end_time = '19:00'
      schedule.lunch_start = '13:00'
      schedule.lunch_end = '14:00'
      schedule.slot_duration_minutes = 30
    } else {
      // Weekends
      schedule.is_working = false
    }
  })
}

const setWeekendSchedule = () => {
  workingSchedules.value.forEach((schedule) => {
    if (schedule.day_of_week >= 1 && schedule.day_of_week <= 5) {
      // Weekdays
      schedule.is_working = true
      schedule.start_time = '09:00'
      schedule.end_time = '19:00'
      schedule.lunch_start = '13:00'
      schedule.lunch_end = '14:00'
      schedule.slot_duration_minutes = 30
    } else {
      // Weekends
      schedule.is_working = false
    }
  })
}

const setFullWeekSchedule = () => {
  workingSchedules.value.forEach((schedule) => {
    schedule.is_working = true
    schedule.start_time = '09:00'
    schedule.end_time = '19:00'
    schedule.lunch_start = '13:00'
    schedule.lunch_end = '14:00'
    schedule.slot_duration_minutes = 30
  })
}

// Navigation function
const goBackToDashboard = async () => {
  // Очищаем кэш слотов перед возвратом в dashboard

  // Устанавливаем флаг для обновления календаря в dashboard
  sessionStorage.setItem('fromScheduleSettings', 'true')

  // Переходим в dashboard
  router.push('/master/dashboard')
}

// Auto-fill default values when enabling working day
const handleWorkingDayChange = (schedule) => {
  if (schedule.is_working) {
    // не автозаполняем значения, пусть пользователь задаёт сам
    schedule.start_time = null
    schedule.end_time = null
    schedule.lunch_start = null
    schedule.lunch_end = null
    schedule.slot_duration_minutes = schedule.slot_duration_minutes || 60
  } else {
    schedule.start_time = null
    schedule.end_time = null
    schedule.lunch_start = null
    schedule.lunch_end = null
    schedule.slot_duration_minutes = null
  }
}

// Clear lunch time fields
const clearLunch = (schedule) => {
  schedule.lunch_start = null
  schedule.lunch_end = null
}
</script>
