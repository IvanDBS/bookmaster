<template>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 mb-6 mt-8">
    <div class="px-4 sm:px-6 py-3 border-b border-gray-200">
      <div
        class="flex flex-col sm:flex-row sm:justify-between sm:items-center space-y-2 sm:space-y-0"
      >
        <h3 class="text-lg sm:text-xl font-semibold text-gray-900">Календарь записей</h3>
        <button
          @click="$emit('go-to-schedule-settings')"
          class="text-blue-500 border border-blue-500 hover:bg-blue-50 font-medium px-2 sm:px-3 py-1.5 rounded-lg transition-colors text-xs sm:text-sm whitespace-nowrap"
        >
          Настройка расписания
        </button>
      </div>
    </div>
    <div class="p-4">
      <!-- Two Months Calendar -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Current Month -->
        <div>
          <div class="flex items-center justify-between mb-4">
            <button
              @click="previousMonth"
              class="p-3 hover:bg-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/30"
              aria-label="Предыдущий месяц"
            >
              <svg
                class="w-5 h-5 text-gray-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 19l-7-7 7-7"
                ></path>
              </svg>
            </button>
            <h4 class="text-lg font-semibold text-gray-900">{{ currentMonthYear }}</h4>
            <div></div>
          </div>

          <!-- Calendar Grid -->
          <div class="grid grid-cols-7 gap-1 mb-4">
            <div
              v-for="day in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']"
              :key="day"
              class="text-center text-sm font-medium text-gray-500 py-2"
            >
              {{ day }}
            </div>
          </div>

          <div class="grid grid-cols-7 gap-1">
            <div
              v-for="date in calendarDates"
              :key="date.key"
              @click="selectDate(date)"
              class="relative"
              :class="[
                'h-12 flex flex-col items-center justify-center text-sm cursor-pointer rounded-lg transition-all duration-200 border-2 hover:border-gray-300',
                getDateHoverBgClass(date),
                date.isCurrentMonth ? 'hover:shadow-md' : 'text-gray-400',
                date.isSelected ? 'border-blue-500 text-gray-900 shadow-md' : 'border-transparent',
                date.isToday && !date.isSelected ? 'bg-blue-50 border-blue-200 font-semibold' : '',
                date.isPast ? 'text-gray-400 cursor-not-allowed' : '',
                getDateBgClass(date),
                getDateBorderClass(date),
              ]"
            >
              <span class="text-xs font-medium">{{ date.day }}</span>
            </div>
          </div>
        </div>

        <!-- Next Month -->
        <div>
          <div class="flex items-center justify-between mb-4">
            <div></div>
            <h4 class="text-lg font-semibold text-gray-900">{{ nextMonthYear }}</h4>
            <button
              @click="nextMonth"
              class="p-3 hover:bg-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/30"
              aria-label="Следующий месяц"
            >
              <svg
                class="w-5 h-5 text-gray-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5l7 7-7 7"
                ></path>
              </svg>
            </button>
          </div>

          <!-- Calendar Grid -->
          <div class="grid grid-cols-7 gap-1 mb-4">
            <div
              v-for="day in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']"
              :key="day"
              class="text-center text-sm font-medium text-gray-500 py-2"
            >
              {{ day }}
            </div>
          </div>

          <div class="grid grid-cols-7 gap-1">
            <div
              v-for="date in nextMonthDates"
              :key="date.key"
              @click="selectDate(date)"
              class="relative"
              :class="[
                'h-12 flex flex-col items-center justify-center text-sm cursor-pointer rounded-lg transition-all duration-200 border-2 hover:border-gray-300',
                getDateHoverBgClass(date),
                date.isCurrentMonth ? 'hover:shadow-md' : 'text-gray-400',
                date.isSelected ? 'border-blue-500 text-gray-900 shadow-md' : 'border-transparent',
                date.isToday && !date.isSelected ? 'bg-blue-50 border-blue-200 font-semibold' : '',
                date.isPast ? 'text-gray-400 cursor-not-allowed' : '',
                getDateBgClass(date),
                getDateBorderClass(date),
              ]"
            >
              <span class="text-xs font-medium">{{ date.day }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Calendar Legend -->
      <CalendarLegend />

      <!-- Selected Date Slots -->
      <MasterTimeSlots
        :selected-date="selectedDate"
        :selected-date-slots="selectedDateSlots"
        :is-day-working="isDayWorking"
        :is-adding-slot="isAddingSlot"
        @toggle-day-status="toggleDayStatus"
        @toggle-slot-break="onToggleSlotBreak"
        @add-new-slot="addNewSlotWrapped"
        :on-confirm-booking="props.onConfirmBooking"
        :on-cancel-booking="props.onCancelBooking"
        :on-delete-booking="props.onDeleteBooking"
        :get-status-text="props.getStatusText"
        :get-slot-price="props.getSlotPrice"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useMasterCalendar } from '../../../composables/useMasterCalendar.js'
import CalendarLegend from './CalendarLegend.vue'
import MasterTimeSlots from './MasterTimeSlots.vue'

const {
  selectedDate,
  selectedDateSlots,
  currentMonthYear,
  nextMonthYear,
  calendarDates,
  nextMonthDates,
  isDayWorking,
  previousMonth,
  nextMonth,
  selectDate,
  loadSlotsForSelectedDate,
  toggleDayStatus,
  onToggleSlotBreak,
  addNewSlot,
  refreshCalendar,
  getDateBgClass,
  getDateBorderClass,
  getDateHoverBgClass,
  slotsCache,
} = useMasterCalendar()

// Props from MasterDashboard.vue
const props = defineProps({
  onConfirmBooking: Function,
  onCancelBooking: Function,
  onDeleteBooking: Function,
  getStatusText: Function,
  getSlotPrice: Function,
  refreshTick: Number,
})

defineEmits(['goToScheduleSettings'])

// Refresh calendar when bookings changed externally
watch(
  () => props.refreshTick,
  async () => {
    try {
      // Лёгкое обновление: если выбрана дата, перезагружаем только её слоты
      if (selectedDate.value) {
        const dateString = `${selectedDate.value.getFullYear()}-${String(
          selectedDate.value.getMonth() + 1,
        ).padStart(2, '0')}-${String(selectedDate.value.getDate()).padStart(2, '0')}`
        // Сбрасываем кэш для выбранной даты, затем подгружаем только её
        slotsCache.value.delete(dateString)
        await loadSlotsForSelectedDate(selectedDate.value)
      } else {
        // Если дата не выбрана, делаем полное обновление
        await refreshCalendar()
      }
    } catch {
      // На случай ошибки в лёгком пути — гарантированный полный рефреш
      await refreshCalendar()
    }
  },
)

// Local UI state for add slot spinner
const isAddingSlot = ref(false)
const addNewSlotWrapped = async () => {
  isAddingSlot.value = true
  try {
    await addNewSlot()
  } finally {
    isAddingSlot.value = false
  }
}
</script>

<style scoped>
/* Your component-specific styles here */
</style>
