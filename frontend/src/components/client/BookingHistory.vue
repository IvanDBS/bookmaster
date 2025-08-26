<template>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200">
    <div class="px-6 py-4 border-b border-gray-200">
      <div class="flex justify-between items-center">
        <h3 class="text-lg font-semibold text-gray-900">История записей</h3>
        <button
          @click="$emit('clear-history')"
          class="text-red-600 hover:text-red-700 text-sm font-medium"
        >
          Очистить историю
        </button>
      </div>
    </div>
    <div class="p-6">
      <div v-if="bookings.length === 0" class="text-center py-8">
        <p class="text-gray-500">История записей пуста</p>
      </div>
      <div v-else class="space-y-4">
        <div
          v-for="booking in bookings"
          :key="booking.id"
          class="flex justify-between items-center p-4 bg-gray-50 rounded-lg"
        >
          <div class="flex-1">
            <div class="flex items-center space-x-4">
              <div class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                <span class="text-gray-600 font-semibold text-sm">
                  {{ booking.user?.first_name[0] }}{{ booking.user?.last_name[0] }}
                </span>
              </div>
              <div>
                <h4 class="font-semibold text-gray-900">{{ booking.service?.name }}</h4>
                <p class="text-sm text-gray-600">
                  {{ booking.user?.first_name }} {{ booking.user?.last_name }}
                </p>
                <p class="text-sm text-gray-600">
                  {{ formatDate(booking.start_time) }} в {{ formatTime(booking.start_time) }}
                </p>
              </div>
            </div>
          </div>
          <div class="text-right">
            <span
              :class="getStatusClass(booking.status)"
              class="px-3 py-1 rounded-full text-xs font-semibold"
            >
              {{ getStatusText(booking.status) }}
            </span>
            <p class="text-sm font-semibold text-gray-900 mt-1">{{ booking.service?.price }} MDL</p>
            <button
              @click="$emit('delete-booking', booking.id)"
              class="mt-2 text-red-600 hover:text-red-700 text-sm font-medium"
            >
              Удалить
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useFormatters } from '../../composables/useFormatters'
defineProps({ bookings: { type: Array, default: () => [] } })
defineEmits(['delete-booking', 'clear-history'])
const { formatDate, formatTime, getStatusClass, getStatusText } = useFormatters()
</script>
