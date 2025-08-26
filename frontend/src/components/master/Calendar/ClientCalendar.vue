<template>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200">
    <!-- Calendar Header -->
    <div class="px-6 py-4 border-b border-gray-200">
      <div class="flex items-center justify-between">
        <h3 class="text-lg font-semibold text-gray-900">Календарь доступности</h3>
        <div class="flex items-center space-x-2">
          <button @click="previousMonth" class="p-2 hover:bg-gray-100 rounded-lg transition-colors">
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
          <span class="text-lg font-semibold text-gray-900"
            >{{ currentMonthName }} {{ currentYear }}</span
          >
          <button @click="nextMonth" class="p-2 hover:bg-gray-100 rounded-lg transition-colors">
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
      </div>
    </div>

    <!-- Calendar Grid -->
    <div class="p-6">
      <!-- Week days header -->
      <div class="grid grid-cols-7 gap-1 mb-2">
        <div
          v-for="day in weekDays"
          :key="day"
          class="text-center text-sm font-medium text-gray-500 py-2"
        >
          {{ day }}
        </div>
      </div>

      <!-- Calendar dates -->
      <div class="grid grid-cols-7 gap-1">
        <div
          v-for="date in calendarDates"
          :key="date.key"
          @click="selectDate(date)"
          class="relative"
          :class="[
            'h-12 flex flex-col items-center justify-center text-sm cursor-pointer rounded-lg transition-all duration-200 border-2 hover:scale-105',
            date.isCurrentMonth ? 'hover:shadow-lg' : 'text-gray-400',
            date.isSelected
              ? 'border-blue-500 text-gray-900 shadow-lg scale-105'
              : 'border-transparent',
            date.isToday && !date.isSelected ? 'bg-blue-50 border-blue-200 font-semibold' : '',
            date.isPast ? 'text-gray-400 cursor-not-allowed hover:scale-100' : '',
            getDateBgClass(date),
            getDateBorderClass(date),
          ]"
        >
          <span class="text-xs font-medium">{{ date.day }}</span>
        </div>
      </div>

      <!-- Calendar Legend -->
      <div class="mt-6 flex flex-wrap gap-4 text-xs">
        <div class="flex items-center space-x-2">
          <div class="w-3 h-3 bg-gray-100 border border-gray-300 rounded"></div>
          <span class="text-gray-600">Выходной</span>
        </div>
        <div class="flex items-center space-x-2">
          <div class="w-3 h-3 bg-green-50 border border-green-300 rounded"></div>
          <span class="text-gray-600">Свободные слоты</span>
        </div>
        <div class="flex items-center space-x-2">
          <div class="w-3 h-3 bg-orange-100 border border-orange-300 rounded"></div>
          <span class="text-gray-600">Есть записи</span>
        </div>
        <div class="flex items-center space-x-2">
          <div class="w-3 h-3 bg-red-100 border border-red-300 rounded"></div>
          <span class="text-gray-600">Нет свободных мест</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, watch } from 'vue'
import { useClientCalendar } from '@/composables/useClientCalendar'

const props = defineProps({
  masterId: {
    type: Number,
    required: true,
  },
})

const emit = defineEmits(['date-selected'])

const {
  // currentDate,
  calendarDates,
  currentMonthName,
  currentYear,
  previousMonth,
  nextMonth,
  selectDate: selectDateBase,
  getDateBgClass,
  getDateBorderClass,
  setMasterId,
} = useClientCalendar()

const weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']

// Override selectDate to emit the selected date
const selectDate = (date) => {
  if (date.isPast) return
  selectDateBase(date)
  emit('date-selected', date)
}

// Set master ID and load slots when component mounts or masterId changes
onMounted(() => {
  if (props.masterId) {
    setMasterId(props.masterId)
  }
})

// Watch for masterId changes
watch(
  () => props.masterId,
  (newMasterId) => {
    if (newMasterId) {
      setMasterId(newMasterId)
    }
  },
)
</script>
