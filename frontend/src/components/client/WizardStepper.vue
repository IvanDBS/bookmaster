<template>
  <div class="flex items-center justify-between">
    <div
      v-for="(label, idx) in steps"
      :key="idx"
      class="flex items-center space-x-2"
      :class="current >= idx + 1 ? 'text-lime-600' : 'text-gray-400'"
    >
      <div
        class="w-6 h-6 rounded-full flex items-center justify-center border text-xs font-semibold"
        :class="current >= idx + 1 ? 'border-lime-500 bg-lime-50' : 'border-gray-300'"
      >
        <span v-if="current > idx + 1">✓</span>
        <span v-else>{{ idx + 1 }}</span>
      </div>
      <span class="text-sm font-medium">{{ label }}</span>
    </div>
  </div>
</template>

<script setup>
defineProps({ current: { type: Number, required: true } })
const steps = ['Выбор услуги', 'Мастер', 'Время', 'Подтверждение']
</script>
