<template>
  <div class="space-y-5">
    <div class="flex items-center justify-between">
      <h4 class="text-sm font-semibold text-gray-900">
        {{ master?.user?.first_name }} {{ master?.user?.last_name }}
      </h4>
      <button class="text-sm text-gray-500 hover:text-gray-700" @click="$emit('back')">
        Выбрать другого мастера
      </button>
    </div>
    <MasterServicesPicker
      :services="services"
      :selected-id="selectedServiceId || null"
      @select="$emit('select', $event)"
    />
    <div class="flex justify-between">
      <button class="text-sm text-gray-600" @click="$emit('back')">← Назад</button>
    </div>
  </div>
</template>

<script setup>
import MasterServicesPicker from '../../client/MasterServicesPicker.vue'

defineProps({
  master: Object,
  services: Array,
  selectedServiceId: [Number, null],
})
defineEmits(['select', 'back'])
</script>
