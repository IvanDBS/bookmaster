<template>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 mb-6 mt-8">
    <div class="px-6 py-3 border-b border-gray-200">
      <div class="flex justify-between items-center">
        <h3 class="text-xl font-semibold text-gray-900">Календарь записей</h3>
        <button
          @click="$emit('goToScheduleSettings')"
          class="text-blue-500 border border-blue-500 hover:bg-blue-50 font-medium px-3 py-1.5 rounded-lg transition-colors text-sm"
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
            <button @click="previousMonth" class="p-2 hover:bg-gray-100 rounded">
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
                'h-12 flex flex-col items-center justify-center text-sm cursor-pointer rounded-lg transition-all duration-200 border-2',
                date.isCurrentMonth ? 'hover:shadow-md' : 'text-gray-400',
                date.isSelected ? 'border-blue-500 text-gray-900 shadow-md' : 'border-transparent',
                date.isToday && !date.isSelected ? 'bg-blue-50 border-blue-200 font-semibold' : '',
                date.isPast ? 'text-gray-400 cursor-not-allowed' : '',
                getDateBgClass(date),
                getDateBorderClass(date),
              ]"
            >
              <span class="text-xs font-medium">{{ date.day }}</span>
              <!-- Индикатор нерабочего дня (приоритет выше загруженности) -->
              <!-- <div v-if="date.loadLevel === 'non_working'" class="mt-0.5">
                <span class="text-xs text-gray-400">⚫</span>
              </div> -->
              <!-- Индикатор загруженности на основе слотов -->
              <!-- <div v-else-if="date.totalSlots > 0" class="flex items-center space-x-0.5 mt-0.5">
                <div v-for="n in Math.min(date.bookedSlots, 4)" :key="n" 
                     :class="[
                       'w-1 h-1 rounded-full',
                       getBookingDotClass(date)
                     ]">
                </div>
                <span v-if="date.bookedSlots > 4" class="text-xs font-bold">+</span>
              </div> -->
            </div>
          </div>
        </div>

        <!-- Next Month -->
        <div>
          <div class="flex items-center justify-between mb-4">
            <div></div>
            <h4 class="text-lg font-semibold text-gray-900">{{ nextMonthYear }}</h4>
            <button @click="nextMonth" class="p-2 hover:bg-gray-100 rounded">
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
                'h-12 flex flex-col items-center justify-center text-sm cursor-pointer rounded-lg transition-all duration-200 border-2',
                date.isCurrentMonth ? 'hover:shadow-md' : 'text-gray-400',
                date.isSelected ? 'border-blue-500 text-gray-900 shadow-md' : 'border-transparent',
                date.isToday && !date.isSelected ? 'bg-blue-50 border-blue-200 font-semibold' : '',
                date.isPast ? 'text-gray-400 cursor-not-allowed' : '',
                getDateBgClass(date),
                getDateBorderClass(date),
              ]"
            >
              <span class="text-xs font-medium">{{ date.day }}</span>
              <!-- Индикатор нерабочего дня (приоритет выше загруженности) -->
              <!-- <div v-if="date.loadLevel === 'non_working'" class="mt-0.5">
                <span class="text-xs text-gray-400">⚫</span>
              </div> -->
              <!-- Индикатор загруженности на основе слотов -->
              <!-- <div v-else-if="date.totalSlots > 0" class="flex items-center space-x-0.5 mt-0.5">
                <div v-for="n in Math.min(date.bookedSlots, 4)" :key="n" 
                     :class="[
                       'w-1 h-1 rounded-full',
                       getBookingDotClass(date)
                     ]">
                </div>
                <span v-if="date.bookedSlots > 4" class="text-xs font-bold">+</span>
              </div> -->
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
        :show-confirm-modal="props.showConfirmModal"
        :show-cancel-modal="props.showCancelModal"
        :show-delete-modal="props.showDeleteModal"
        :get-status-text="props.getStatusText"
        :get-slot-price="props.getSlotPrice"
      />
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
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
  toggleDayStatus,
  onToggleSlotBreak,
  addNewSlot,
  getDateBgClass,
  getDateBorderClass,
} = useMasterCalendar()

// Props from MasterDashboard.vue
const props = defineProps({
  showConfirmModal: Function,
  showCancelModal: Function,
  showDeleteModal: Function,
  getStatusText: Function,
  getSlotPrice: Function,
})

defineEmits(['goToScheduleSettings'])

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
