<template>
  <div id="bookings" class="bg-white rounded-xl shadow-lg border border-gray-100 mb-8">
    <div class="px-8 py-6 border-b border-gray-100">
      <h3 class="text-2xl font-bold text-gray-900">Мои записи</h3>
    </div>
    <div class="p-6">
      <div v-if="bookings.length === 0" class="text-center py-8">
        <p class="text-gray-500">У вас пока нет активных записей</p>
      </div>
      <div v-else class="space-y-4">
        <div
          v-for="booking in bookings"
          :key="booking.id"
          class="flex justify-between items-center p-6 bg-gradient-to-r from-gray-50 to-gray-100 rounded-xl border border-gray-200 hover:shadow-md transition-all duration-300"
        >
          <div class="flex-1">
            <div>
              <h4 class="font-bold text-gray-900 text-lg">{{ booking.service?.name }}</h4>
              <p class="text-sm text-gray-600">
                {{ booking.user?.first_name }} {{ booking.user?.last_name }}
              </p>
              <p class="text-sm text-gray-600">
                {{ formatDate(booking.start_time) }} в {{ formatTime(booking.start_time) }}
              </p>
            </div>
          </div>
          <div class="text-right">
            <span
              :class="getStatusClass(booking.status)"
              class="px-4 py-2 rounded-full text-xs font-bold shadow-sm"
            >
              {{ getStatusText(booking.status) }}
            </span>
            <p class="text-lg font-bold text-gray-900 mt-2">{{ booking.service?.price }} MDL</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useFormatters } from '../../composables/useFormatters'
const { formatDate, formatTime, getStatusClass, getStatusText } = useFormatters()
defineProps({ bookings: { type: Array, default: () => [] } })
</script>
