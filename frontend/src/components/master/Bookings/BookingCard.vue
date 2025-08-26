<template>
  <div
    class="flex flex-col sm:flex-row sm:justify-between sm:items-center p-4 bg-gray-50 rounded-lg space-y-3 sm:space-y-0"
  >
    <div class="flex-1">
      <p class="font-medium text-gray-900 text-sm sm:text-base">{{ safeServiceName }}</p>
      <p v-if="safeClientName" class="text-xs sm:text-sm text-gray-600 font-medium">
        {{ safeClientName }}
      </p>
      <p v-if="safeClientPhone" class="text-xs sm:text-sm text-gray-500">{{ safeClientPhone }}</p>
      <p class="text-xs sm:text-sm text-gray-600">
        {{ formatDate(booking.start_time) }} в {{ formatTime(booking.start_time) }}
      </p>
    </div>
    <div class="flex flex-col sm:text-right tabular-nums space-y-2 sm:space-y-1">
      <span
        :class="getStatusClass(booking.status)"
        class="px-2 py-1 rounded-full text-xs font-semibold self-start sm:self-auto"
      >
        {{ getStatusText(booking.status) }}
      </span>
      <p class="text-sm font-semibold text-gray-900">
        {{ booking?.service?.price ? Math.round(booking.service.price) : 0 }} MDL
      </p>
      <div v-if="booking.status === 'pending'" class="flex space-x-2 sm:justify-end">
        <button
          @click="$emit('show-confirm-modal', booking)"
          class="text-green-600 hover:text-green-700 text-xs font-medium px-2 py-1 rounded hover:bg-green-50 transition-colors"
        >
          Подтвердить
        </button>
        <button
          @click="$emit('show-cancel-modal', booking)"
          class="text-red-600 hover:text-red-700 text-xs font-medium px-2 py-1 rounded hover:bg-red-50 transition-colors"
        >
          Отменить
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useBookings } from '../../../composables/useBookings'
import { useSanitization } from '../../../composables/useSanitization'

const props = defineProps({
  booking: {
    type: Object,
    required: true,
  },
})

defineEmits(['show-confirm-modal', 'show-cancel-modal'])

// Используем функции из composable
const { formatDate, formatTime, getStatusClass, getStatusText } = useBookings()
const { safeName } = useSanitization()

// Безопасные computed свойства
const safeServiceName = computed(() => safeName(props.booking?.service?.name).value)
const safeClientName = computed(() => safeName(props.booking?.client_name).value)
const safeClientPhone = computed(() => safeName(props.booking?.client_phone).value)
</script>
