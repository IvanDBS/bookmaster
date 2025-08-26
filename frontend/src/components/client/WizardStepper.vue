<template>
  <div class="flex items-center justify-between">
    <div
      v-for="(label, idx) in steps"
      :key="idx"
      class="flex items-center space-x-1 sm:space-x-2"
      :class="current >= idx + 1 ? 'text-lime-600' : 'text-gray-400'"
    >
      <div
        class="w-5 h-5 sm:w-6 sm:h-6 rounded-full flex items-center justify-center border text-xs font-semibold"
        :class="current >= idx + 1 ? 'border-lime-500 bg-lime-50' : 'border-gray-300'"
      >
        <span v-if="current > idx + 1">✓</span>
        <span v-else>{{ idx + 1 }}</span>
      </div>
      <span
        class="text-xs sm:text-sm font-medium block max-w-[60px] sm:max-w-none truncate sm:truncate-none"
        >{{ getShortLabel(label) }}</span
      >
    </div>
  </div>
</template>

<script setup>
defineProps({ current: { type: Number, required: true } })
const steps = ['Выбор услуги', 'Мастер', 'Время', 'Подтверждение']

const getShortLabel = (label) => {
  const shortLabels = {
    'Выбор услуги': 'Услуга',
    Мастер: 'Мастер',
    Время: 'Время',
    Подтверждение: 'Готово',
  }
  return shortLabels[label] || label
}
</script>
