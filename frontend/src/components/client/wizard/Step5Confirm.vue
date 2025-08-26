<template>
  <div class="space-y-5">
    <h4 class="text-sm font-semibold text-gray-900">Подтверждение</h4>
    <div class="rounded-xl border border-gray-200 p-4">
      <div class="text-sm text-gray-700">Услуга</div>
      <div class="font-semibold text-gray-900">
        {{ service.name }} — {{ service.price }} MDL ({{ service.duration }} мин)
      </div>
      <div class="mt-2 text-sm text-gray-700">Мастер</div>
      <div class="font-semibold text-gray-900">
        {{ master.user.first_name }} {{ master.user.last_name }}
      </div>
      <div class="mt-2 text-sm text-gray-700">Время</div>
      <div class="font-semibold text-gray-900">
        {{ formatBookingDate(date) }} • {{ formatBookingTime(timeSlot.start_time) }}
      </div>
    </div>
    <div class="flex items-center justify-between">
      <button class="text-sm text-gray-600" @click="$emit('back')">← Назад</button>
      <button
        class="bg-gradient-to-r from-lime-500 to-lime-600 hover:from-lime-600 hover:to-lime-700 text-white font-bold px-8 py-3 rounded-lg transition-all duration-300 text-sm shadow-md hover:shadow-lg transform hover:scale-105"
        @click="$emit('submit')"
      >
        Подтвердить запись
      </button>
    </div>
  </div>
</template>

<script setup>
import { useFormatters } from '../../../composables/useFormatters'
const { formatBookingDate, formatBookingTime } = useFormatters()
defineProps({ master: Object, service: Object, date: String, timeSlot: Object })
defineEmits(['back', 'submit'])
</script>
