<template>
  <div class="flex space-x-2">
    <select
      :value="hour"
      @change="onHourChange($event.target.value)"
      class="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
    >
      <option value="" disabled>{{ placeholderHour }}</option>
      <option v-for="h in hours" :key="h" :value="h">{{ h }}</option>
    </select>
    <span class="self-center text-gray-500">:</span>
    <select
      :value="minute"
      @change="onMinuteChange($event.target.value)"
      class="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
    >
      <option value="" disabled>{{ placeholderMinute }}</option>
      <option v-for="m in minutes" :key="m" :value="m">{{ m }}</option>
    </select>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  modelValue: { type: String, default: null }, // 'HH:MM' | null
  step: { type: Number, default: 15 }, // minutes step for minutes select
  placeholderHour: { type: String, default: '--' },
  placeholderMinute: { type: String, default: '--' },
})

const emit = defineEmits(['update:modelValue'])

const parsed = computed(() => {
  if (!props.modelValue || typeof props.modelValue !== 'string') return { h: '', m: '' }
  const match = props.modelValue.match(/^(\d{2}):(\d{2})$/)
  if (!match) return { h: '', m: '' }
  return { h: match[1], m: match[2] }
})

const hour = computed(() => parsed.value.h)
const minute = computed(() => parsed.value.m)

const hours = computed(() => Array.from({ length: 24 }, (_, i) => String(i).padStart(2, '0')))
const minutes = computed(() => {
  const step = Math.max(1, Math.min(60, props.step))
  const arr = []
  for (let m = 0; m < 60; m += step) arr.push(String(m).padStart(2, '0'))
  if (!arr.includes('00')) arr.unshift('00')
  return arr
})

function onHourChange(val) {
  const h = String(val || '').padStart(2, '0')
  const m = minute.value || '00'
  emit('update:modelValue', h && m ? `${h}:${m}` : null)
}

function onMinuteChange(val) {
  const h = hour.value || '00'
  const m = String(val || '').padStart(2, '0')
  emit('update:modelValue', h && m ? `${h}:${m}` : null)
}
</script>

<style scoped></style>
