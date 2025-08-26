<template>
  <div id="bookings" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
    <div class="px-6 py-4 border-b border-gray-200">
      <div class="flex justify-between items-center">
        <h3 class="text-lg font-semibold text-gray-900">Последние записи</h3>
        <!-- Кнопки сортировки -->
        <BookingFilters :booking-filter="bookingFilter" @set-booking-filter="setBookingFilter" />
      </div>
    </div>
    <div class="p-6">
      <div v-if="filteredBookings.length === 0" class="text-center py-8">
        <p class="text-gray-500">У вас пока нет записей</p>
      </div>
      <div v-else class="space-y-4">
        <BookingCard
          v-for="booking in filteredBookings"
          :key="booking.id"
          :booking="booking"
          @show-confirm-modal="showConfirmModal"
          @show-cancel-modal="showCancelModal"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { useBookings } from '../../../composables/useBookings'
import BookingFilters from './BookingFilters.vue'
import BookingCard from './BookingCard.vue'

// Используем composable
const {
  // State
  bookingFilter,

  // Computed
  filteredBookings,

  // Functions
  setBookingFilter,
  showConfirmModal,
  showCancelModal,
} = useBookings()
</script>
