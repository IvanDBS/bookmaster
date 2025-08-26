<template>
  <div class="space-y-5">
    <h4 class="text-sm font-semibold text-gray-900">Выберите время</h4>
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <ClientCalendar :master-id="masterId" @date-selected="$emit('date-selected', $event)" />
      <ClientTimeSlots
        v-if="selectedDate"
        :selected-date="selectedDate"
        :master-id="masterId"
        :service="service"
        @slot-selected="$emit('slot-selected', $event)"
      />
    </div>
    <div class="flex justify-between">
      <button class="text-sm text-gray-600" @click="$emit('back')">← Назад к выбору мастера</button>
    </div>
  </div>
</template>

<script setup>
import ClientCalendar from '../../master/Calendar/ClientCalendar.vue'
import ClientTimeSlots from '../../master/Calendar/ClientTimeSlots.vue'

defineProps({ masterId: Number, selectedDate: Object, service: Object })
defineEmits(['date-selected', 'slot-selected', 'back'])
</script>
