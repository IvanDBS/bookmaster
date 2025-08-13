<template>
  <div class="flex justify-between items-center p-4 bg-gray-50 rounded-lg">
    <div>
      <p class="font-medium text-gray-900">{{ booking.service?.name }}</p>
      <p class="text-sm text-gray-600">{{ booking.client_name }}</p>
      <p class="text-sm text-gray-600">
        {{ formatDate(booking.start_time) }} в {{ formatTime(booking.start_time) }}
      </p>
    </div>
    <div class="text-right tabular-nums">
      <span
        :class="getStatusClass(booking.status)"
        class="px-2 py-1 rounded-full text-xs font-semibold"
      >
        {{ getStatusText(booking.status) }}
      </span>
      <p class="text-sm font-semibold text-gray-900 mt-1">
        {{ booking?.service?.price ? Math.round(booking.service.price) : 0 }} MDL
      </p>
      <div v-if="booking.status === 'pending'" class="flex space-x-2 mt-2">
        <button
          @click="$emit('show-confirm-modal', booking)"
          class="text-green-600 hover:text-green-700 text-xs font-light"
        >
          Подтвердить
        </button>
        <button
          @click="$emit('show-cancel-modal', booking)"
          class="text-red-600 hover:text-red-700 text-xs font-light"
        >
          Отменить
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useBookings } from '../../../composables/useBookings'

defineProps({
  booking: {
    type: Object,
    required: true,
  },
})

defineEmits(['show-confirm-modal', 'show-cancel-modal'])

// Используем функции из composable
const { formatDate, formatTime, getStatusClass, getStatusText } = useBookings()
</script>
