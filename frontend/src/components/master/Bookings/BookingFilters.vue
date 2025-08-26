<template>
  <div class="flex space-x-2">
    <button
      @click="$emit('set-booking-filter', 'all')"
      :class="bookingFilter === 'all' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700'"
      class="px-3 py-1 text-sm font-medium rounded hover:bg-gray-200 transition-colors"
    >
      Все
    </button>
    <button
      @click="$emit('set-booking-filter', 'pending')"
      :class="
        bookingFilter === 'pending' ? 'bg-yellow-500 text-white' : 'bg-gray-100 text-gray-700'
      "
      class="px-3 py-1 text-sm font-medium rounded hover:bg-gray-200 transition-colors"
    >
      Ожидает подтверждения
    </button>
    <button
      @click="$emit('set-booking-filter', 'confirmed')"
      :class="
        bookingFilter === 'confirmed' ? 'bg-green-500 text-white' : 'bg-gray-100 text-gray-700'
      "
      class="px-3 py-1 text-sm font-medium rounded hover:bg-gray-200 transition-colors"
    >
      Подтверждено
    </button>
    <button
      @click="$emit('set-booking-filter', 'cancelled')"
      :class="bookingFilter === 'cancelled' ? 'bg-red-500 text-white' : 'bg-gray-100 text-gray-700'"
      class="px-3 py-1 text-sm font-medium rounded hover:bg-gray-200 transition-colors"
    >
      Отменено
    </button>
  </div>
</template>

<script setup>
defineProps({
  bookingFilter: {
    type: String,
    required: true,
  },
})

defineEmits(['set-booking-filter'])
</script>
