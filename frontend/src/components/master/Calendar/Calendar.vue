<template>
  <div id="calendar" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
    <div class="px-6 py-4 border-b border-gray-200">
      <div class="flex justify-between items-center">
        <h3 class="text-lg font-semibold text-gray-900">Календарь записей</h3>
        <button 
          @click="goToScheduleSettings"
          class="bg-blue-600 hover:bg-blue-700 text-white font-medium px-4 py-2 rounded-lg transition-colors text-sm"
        >
          ⚙️ Настройки расписания
        </button>
      </div>
    </div>
    <div class="p-6">
      <!-- Two Months Calendar -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Current Month -->
        <CalendarMonth 
          :dates="calendarDates"
          :month-year="currentMonthYear"
          :show-previous-button="true"
          :get-date-bg-class="getDateBgClass"
          :get-date-border-class="getDateBorderClass"
          :get-booking-dot-class="getBookingDotClass"
          @previous-month="previousMonth"
          @select-date="selectDate"
        />

        <!-- Next Month -->
        <CalendarMonth 
          :dates="nextMonthDates"
          :month-year="nextMonthYear"
          :show-next-button="true"
          :get-date-bg-class="getDateBgClass"
          :get-date-border-class="getDateBorderClass"
          :get-booking-dot-class="getBookingDotClass"
          @next-month="nextMonth"
          @select-date="selectDate"
        />
      </div>

      <!-- Calendar Legend -->
      <CalendarLegend />

      <!-- Selected Date Slots -->
      <CalendarSlots 
        v-if="selectedDate"
        :selected-date="selectedDate"
        :selected-date-slots="selectedDateSlots"
        :is-day-working="isDayWorking"
        :format-selected-date="formatSelectedDate"
        @toggle-day-status="toggleDayStatus"
        @confirm-booking="showConfirmModal"
        @cancel-booking="showCancelModal"
        @toggle-slot-break="onToggleSlotBreak"
      />

      <!-- Selected Date Bookings -->
      <div v-if="selectedDateBookings.length > 0" class="mt-6">
        <h5 class="font-semibold text-gray-900 mb-3">
          Записи на {{ formatSelectedDate() }}
        </h5>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
          <div v-for="booking in sortedSelectedDateBookings" :key="booking.id" 
               class="bg-gray-50 rounded-lg p-3 border-l-4"
               :class="{
                 'border-green-500': booking.status === 'confirmed',
                 'border-yellow-500': booking.status === 'pending',
                 'border-red-500': booking.status === 'cancelled'
               }">
            <div class="flex justify-between items-start mb-2">
              <div class="flex-1">
                <h6 class="font-semibold text-gray-900 text-sm">{{ booking.service?.name }}</h6>
                <p class="text-xs text-gray-600">{{ booking.client_name }}</p>
              </div>
              <span :class="getStatusClass(booking.status)" class="px-2 py-1 rounded-full text-xs font-semibold ml-2">
                {{ getStatusText(booking.status) }}
              </span>
            </div>
            <div class="flex justify-between items-center">
              <div class="text-xs text-gray-600">
                {{ formatTime(booking.start_time) }} - {{ formatTime(booking.end_time) }}
              </div>
              <div class="text-right">
                <p class="text-sm font-semibold text-gray-900">₽{{ booking.service?.price }}</p>
                <div v-if="booking.status === 'pending'" class="flex space-x-1 mt-1">
                  <button @click="showConfirmModal(booking)" class="text-green-600 hover:text-green-700 text-xs font-medium">
                    ✓
                  </button>
                  <button @click="showCancelModal(booking)" class="text-red-600 hover:text-red-700 text-xs font-medium">
                    ✕
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div v-else-if="selectedDate && selectedDateSlots.length === 0" class="mt-6 text-center py-4">
        <p class="text-gray-500">На выбранную дату слотов нет</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useCalendar } from '../../../composables/useCalendar'
import { useBookings } from '../../../composables/useBookings'
import api from '../../../services/api'
import { useAuthStore } from '../../../stores/auth'
import CalendarMonth from './CalendarMonth.vue'
import CalendarLegend from './CalendarLegend.vue'
import CalendarSlots from './CalendarSlots.vue'

const router = useRouter()

// Используем composables
const {
  // State
  selectedDate,
  selectedDateSlots,
  isDayWorking,
  
  // Computed
  currentMonthYear,
  nextMonthYear,
  calendarDates,
  nextMonthDates,
  
  // Functions
  previousMonth,
  nextMonth,
  selectDate,
  toggleDayStatus,
  getDateBgClass,
  getDateBorderClass,
  getBookingDotClass,
  formatSelectedDate,
  loadSlotsForSelectedDate,
  invalidateCacheForDate
} = useCalendar()

const {
  // State
  selectedDateBookings,
  
  // Computed
  sortedSelectedDateBookings,
  
  // Functions
  showConfirmModal,
  showCancelModal,
  getStatusClass,
  getStatusText,
  formatTime
} = useBookings()

// Navigation function
const goToScheduleSettings = () => {
  router.push('/master/schedule')
}

// Toggle per-slot break
const onToggleSlotBreak = async ({ slot, isBreak }) => {
  try {
    const date = selectedDate.value
    if (!date) return
    const authStore = useAuthStore()
    await api.updateTimeSlot(slot.id, { is_break: isBreak }, authStore.token)
    // Refresh slots for selected date only с инвалидированием кэша
    invalidateCacheForDate(date)
    await loadSlotsForSelectedDate(date)
  } catch (e) {
    console.error('Failed to toggle break for slot', slot.id, e)
    alert('Не удалось изменить статус слота: ' + e.message)
  }
}
</script> 