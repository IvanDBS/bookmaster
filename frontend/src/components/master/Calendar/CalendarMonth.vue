<template>
  <div>
    <div class="flex items-center justify-between mb-4">
      <button
        v-if="showPreviousButton"
        @click="$emit('previous-month')"
        class="p-2 hover:bg-gray-100 rounded"
      >
        <svg class="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M15 19l-7-7 7-7"
          ></path>
        </svg>
      </button>
      <h4 class="text-lg font-semibold text-gray-900">{{ monthYear }}</h4>
      <button
        v-if="showNextButton"
        @click="$emit('next-month')"
        class="p-2 hover:bg-gray-100 rounded"
      >
        <svg class="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
        v-for="date in dates"
        :key="date.key"
        @click="$emit('select-date', date)"
        class="relative"
        :class="[
          'aspect-square min-h-[3rem] flex flex-col items-center justify-center text-sm cursor-pointer rounded-lg transition-all duration-200 border',
          date.isCurrentMonth ? 'hover:shadow-md' : 'text-gray-400',
          date.isSelected ? 'bg-blue-500 text-white border-blue-600 shadow-lg' : '',
          date.isToday && !date.isSelected ? 'bg-blue-50 border-blue-200 font-semibold' : '',
          date.isPast ? 'text-gray-400 cursor-not-allowed' : '',
          !date.isSelected && !date.isToday && getDateBgClass(date),
          !date.isSelected && !date.isToday && getDateBorderClass(date),
        ]"
      >
        <span class="text-xs font-medium">{{ date.day }}</span>
        <!-- Индикатор нерабочего дня (приоритет выше загруженности) -->
        <div v-if="date.loadLevel === 'non_working' && !date.isSelected" class="mt-0.5">
          <span class="text-xs text-gray-400">⚫</span>
        </div>
        <!-- Индикатор загруженности на основе слотов -->
        <div
          v-else-if="date.totalSlots > 0 && !date.isSelected"
          class="flex items-center space-x-0.5 mt-0.5"
        >
          <div
            v-for="n in Math.min(date.bookedSlots, 4)"
            :key="n"
            :class="['w-1 h-1 rounded-full', getBookingDotClass(date)]"
          ></div>
          <span v-if="date.bookedSlots > 4" class="text-xs font-bold">+</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
//

defineProps({
  dates: {
    type: Array,
    required: true,
  },
  monthYear: {
    type: String,
    required: true,
  },
  showPreviousButton: {
    type: Boolean,
    default: false,
  },
  showNextButton: {
    type: Boolean,
    default: false,
  },
  getDateBgClass: {
    type: Function,
    required: true,
  },
  getDateBorderClass: {
    type: Function,
    required: true,
  },
  getBookingDotClass: {
    type: Function,
    required: true,
  },
})

defineEmits(['previous-month', 'next-month', 'select-date'])
</script>
