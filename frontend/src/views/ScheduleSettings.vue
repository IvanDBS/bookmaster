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
            <h2 class="text-3xl font-bold text-gray-900 mb-2">
              Настройки расписания
            </h2>
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
              
              <div v-for="schedule in workingSchedules" :key="schedule.id" 
                   class="border border-gray-200 rounded-lg p-4">
                <div class="flex items-center justify-between mb-4">
                  <div class="flex items-center space-x-3">
                    <input 
                      type="checkbox" 
                      :id="`day-${schedule.day_of_week}`"
                      v-model="schedule.is_working"
                      @change="handleWorkingDayChange(schedule)"
                      class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                    >
                    <label :for="`day-${schedule.day_of_week}`" class="font-medium text-gray-900">
                      {{ schedule.day_name }}
                    </label>
                  </div>
                  <span v-if="schedule.is_working" class="text-green-600 text-sm font-medium">
                    Рабочий день
                  </span>
                  <span v-else class="text-gray-500 text-sm">
                    Выходной
                  </span>
                </div>

                <!-- Working Hours (only if is_working) -->
                <div v-if="schedule.is_working" class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Время начала работы
                    </label>
                    <input 
                      type="time" 
                      v-model="schedule.start_time"
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Время окончания работы
                    </label>
                    <input 
                      type="time" 
                      v-model="schedule.end_time"
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Начало обеда
                    </label>
                    <input 
                      type="time" 
                      v-model="schedule.lunch_start"
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Конец обеда
                    </label>
                    <input 
                      type="time" 
                      v-model="schedule.lunch_end"
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
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
                    >
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
          <li>• Длительность слота определяет интервалы записи (например, 60 мин = слоты по часу)</li>
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
import AppHeader from '../components/AppHeader.vue'

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
  6: 'Суббота'
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

    const response = await fetch('http://localhost:3000/api/v1/working_schedules', {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
      },
    })
    
    if (!response.ok) {
      throw new Error('Failed to fetch working schedules')
    }
    
    const schedulesData = await response.json()
    
    // Add day names and ensure all days are present
    workingSchedules.value = schedulesData.map(schedule => ({
      ...schedule,
      day_name: dayNames[schedule.day_of_week]
    }))
    
    // Sort by day of week
    workingSchedules.value.sort((a, b) => a.day_of_week - b.day_of_week)
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

    console.log('Saving schedules:', workingSchedules.value)

    // Update each schedule
    const updatePromises = workingSchedules.value.map(async (schedule) => {
      const scheduleData = {
        working_schedule: {
          is_working: schedule.is_working,
          start_time: schedule.start_time,
          end_time: schedule.end_time,
          lunch_start: schedule.lunch_start,
          lunch_end: schedule.lunch_end,
          slot_duration_minutes: schedule.slot_duration_minutes
        }
      }
      
      console.log('Updating schedule:', schedule.id, scheduleData)

      const response = await fetch(`http://localhost:3000/api/v1/working_schedules/${schedule.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.token}`,
        },
        body: JSON.stringify(scheduleData)
      })
      
      console.log('Response status:', response.status)
      
      if (!response.ok) {
        const errorData = await response.json()
        console.error('Error response:', errorData)
        const errorMessage = errorData.errors ? 
          (Array.isArray(errorData.errors) ? errorData.errors.join(', ') : errorData.errors) : 
          'Failed to update schedule'
        throw new Error(errorMessage)
      }
      
      const result = await response.json()
      console.log('Update result:', result)
      return result
    })
    
    await Promise.all(updatePromises)
    
    // Перезагружаем данные после сохранения
    await loadWorkingSchedules()
    
    alert('Расписание успешно сохранено!')
  } catch (error) {
    console.error('Error saving schedule:', error)
    alert('Ошибка при сохранении расписания: ' + error.message)
  } finally {
    saving.value = false
  }
}

const setDefaultSchedule = () => {
  workingSchedules.value.forEach(schedule => {
    if (schedule.day_of_week >= 1 && schedule.day_of_week <= 5) {
      // Weekdays
      schedule.is_working = true
      schedule.start_time = '09:00'
      schedule.end_time = '19:00'
      schedule.lunch_start = '13:00'
      schedule.lunch_end = '14:00'
      schedule.slot_duration_minutes = 60
    } else {
      // Weekends
      schedule.is_working = false
    }
  })
}

const setWeekendSchedule = () => {
  workingSchedules.value.forEach(schedule => {
    if (schedule.day_of_week >= 1 && schedule.day_of_week <= 5) {
      // Weekdays
      schedule.is_working = true
      schedule.start_time = '09:00'
      schedule.end_time = '19:00'
      schedule.lunch_start = '13:00'
      schedule.lunch_end = '14:00'
      schedule.slot_duration_minutes = 60
    } else {
      // Weekends
      schedule.is_working = false
    }
  })
}

const setFullWeekSchedule = () => {
  workingSchedules.value.forEach(schedule => {
    schedule.is_working = true
    schedule.start_time = '09:00'
    schedule.end_time = '19:00'
    schedule.lunch_start = '13:00'
    schedule.lunch_end = '14:00'
    schedule.slot_duration_minutes = 60
  })
}

// Navigation function
const goBackToDashboard = () => {
  router.push('/master/dashboard')
}

// Auto-fill default values when enabling working day
const handleWorkingDayChange = (schedule) => {
  if (schedule.is_working) {
    schedule.start_time = schedule.start_time || '09:00'
    schedule.end_time = schedule.end_time || '19:00'
    schedule.lunch_start = schedule.lunch_start || '13:00'
    schedule.lunch_end = schedule.lunch_end || '14:00'
    schedule.slot_duration_minutes = schedule.slot_duration_minutes || 60
  }
}
</script> 