<template>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200">
    <div class="px-6 py-4 border-b border-gray-200">
      <h3 class="text-lg font-semibold text-gray-900">
        Временные слоты на {{ formatSelectedDate }}
      </h3>
    </div>

    <div class="p-6">
      <div v-if="loading" class="flex justify-center py-8">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-lime-500"></div>
      </div>

      <div v-else-if="availableSlots.length === 0" class="text-center py-8">
        <p class="text-gray-500">На выбранную дату нет доступных слотов</p>
        <p class="text-xs text-gray-400 mt-2">Все слоты забронированы или заблокированы</p>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
        <button
          v-for="slot in availableSlots"
          :key="slot.id"
          @click="selectSlot(slot)"
          :class="[
            'rounded-lg p-4 text-left transition-all duration-200 border-2 hover:scale-105',
            selectedSlot?.id === slot.id
              ? 'border-lime-500 bg-lime-50 shadow-lg scale-105'
              : 'border-gray-200 hover:border-lime-300 hover:shadow-md',
          ]"
        >
          <div class="flex justify-between items-center">
            <div>
              <h6 class="font-semibold text-gray-900 text-sm">
                {{ formatTime(slot.start_time) }} - {{ formatTime(slot.end_time) }}
              </h6>
              <p class="text-xs text-gray-600 mt-1">{{ slot.duration_minutes }} минут</p>
            </div>
            <div class="flex items-center space-x-2">
              <span
                class="px-2 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-800"
              >
                Свободно
              </span>
            </div>
          </div>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import api from '../../../services/api'

const props = defineProps({
  selectedDate: {
    type: Object,
    required: true,
  },
  masterId: {
    type: Number,
    required: true,
  },
})

const emit = defineEmits(['slot-selected'])

const loading = ref(false)
const availableSlots = ref([])
const selectedSlot = ref(null)

const formatSelectedDate = computed(() => {
  if (!props.selectedDate) return ''
  const date = new Date(props.selectedDate.date)
  return date.toLocaleDateString('ru-RU', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
})

const formatTime = (timeString) => {
  if (!timeString) return ''
  // Extract time from ISO string or time format
  const time = timeString.includes('T')
    ? timeString.split('T')[1].substring(0, 5)
    : timeString.substring(0, 5)
  return time
}

const selectSlot = (slot) => {
  selectedSlot.value = slot
  emit('slot-selected', slot)
}

const loadSlotsForDate = async () => {
  if (!props.selectedDate || !props.masterId) return

  loading.value = true
  try {
    // Преобразуем дату в строку YYYY-MM-DD
    let dateString
    if (props.selectedDate.key) {
      dateString = props.selectedDate.key
    } else if (props.selectedDate.date instanceof Date) {
      dateString = props.selectedDate.date.toISOString().split('T')[0]
    } else {
      dateString = props.selectedDate.date
    }

    console.log('Selected date object:', props.selectedDate)
    console.log('Using date string:', dateString)

    console.log(`Loading slots for date: ${dateString}, master: ${props.masterId}`)

    const data = await api.getPublicSlots(props.masterId, dateString)
    const slots = Array.isArray(data) ? data : (data.slots || [])
    // Filter only available work slots (exclude blocked slots)
    availableSlots.value = slots.filter(
      (slot) => slot.is_available && !slot.booked && slot.slot_type === 'work',
    )
  } catch (error) {
    console.error('Error loading slots:', error)
    availableSlots.value = []
  } finally {
    loading.value = false
  }
}

// Watch for date changes
watch(
  () => props.selectedDate,
  () => {
    selectedSlot.value = null
    loadSlotsForDate()
  },
  { immediate: true },
)
</script>
