<template>
  <div v-if="selectedDate" class="mt-6">
    <div class="flex items-center justify-between mb-3">
      <h5 class="font-semibold text-gray-900">Временные слоты на {{ formatSelectedDate() }}</h5>

      <!-- Toggle Switch для управления статусом дня -->
      <div class="flex items-center space-x-3">
        <span class="text-sm text-gray-700">Рабочий день</span>
        <button
          @click="$emit('toggle-day-status')"
          :class="[
            'relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
            isDayWorking ? 'bg-blue-600' : 'bg-gray-200',
          ]"
          role="switch"
          :aria-checked="isDayWorking"
        >
          <span
            :class="[
              'inline-block h-4 w-4 transform rounded-full bg-white transition duration-200 ease-in-out',
              isDayWorking ? 'translate-x-6' : 'translate-x-1',
            ]"
          />
        </button>
      </div>
    </div>

    <!-- Slots Grid (only show if there are slots) -->
    <div
      v-if="selectedDateSlots.length > 0"
      class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3"
    >
      <div
        v-for="slot in selectedDateSlots"
        :key="slot.id"
        class="bg-gray-50 rounded-lg p-3 border-l-4"
        :class="{
          'border-green-500': slot.is_available && !slot.booked,
          'border-blue-500': slot.booked,
          'border-gray-400': slot.slot_type === 'lunch',
          'border-red-400': slot.slot_type === 'blocked',
        }"
      >
        <div class="flex justify-between items-start mb-2">
          <div class="flex-1">
            <h6 class="font-semibold text-gray-900 text-sm">
              {{ formatSlotTime(slot.start_time) }} - {{ formatSlotTime(slot.end_time) }}
            </h6>
            <p class="text-xs text-gray-600">
              {{ getSlotTypeText(slot.slot_type) }}
            </p>
          </div>
          <div class="flex items-center space-x-2 ml-2">
            <!-- Break toggle for free/non-booked slots -->
            <button
              v-if="!slot.booked"
              @click="$emit('toggle-slot-break', { slot, isBreak: !isBreak(slot) })"
              :class="[
                'relative inline-flex h-5 w-10 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
                isBreak(slot) ? 'bg-red-500' : 'bg-gray-200',
              ]"
              :title="isBreak(slot) ? 'Сделать свободным' : 'Отметить как перерыв'"
            >
              <span
                :class="[
                  'inline-block h-3.5 w-3.5 transform rounded-full bg-white transition duration-200 ease-in-out',
                  isBreak(slot) ? 'translate-x-5' : 'translate-x-1',
                ]"
              />
            </button>

            <span
              :class="getSlotStatusClass(slot)"
              class="px-2 py-1 rounded-full text-xs font-semibold"
            >
              {{ getSlotStatusText(slot) }}
            </span>

            <!-- Inline approve / reject for pending booking -->
            <div v-if="slot.booking && slot.booking.status === 'pending'" class="flex space-x-1">
              <button
                @click="$emit('confirm-booking', slot.booking)"
                class="text-green-600 hover:text-green-700 text-xs font-medium"
                title="Принять"
              >
                ✓
              </button>
              <button
                @click="$emit('cancel-booking', slot.booking)"
                class="text-red-600 hover:text-red-700 text-xs font-medium"
                title="Отменить"
              >
                ✕
              </button>
            </div>
          </div>
        </div>
        <div v-if="slot.booking" class="mt-2 p-2 bg-blue-50 rounded">
          <p class="text-xs text-gray-700">
            <strong>Клиент:</strong> {{ slot.booking.client_name }}
          </p>
          <p class="text-xs text-gray-700">
            <strong>Услуга:</strong> {{ slot.booking.service_name }}
          </p>
          <p class="text-xs text-gray-700">
            <strong>Статус:</strong> {{ getStatusText(slot.booking.status) }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
// Props
const props = defineProps({
  selectedDate: {
    type: Date,
    required: true,
  },
  selectedDateSlots: {
    type: Array,
    required: true,
  },
  isDayWorking: {
    type: Boolean,
    required: true,
  },
  formatSelectedDate: {
    type: Function,
    required: true,
  },
})

// Emits
const emit = defineEmits([
  'toggle-day-status',
  'confirm-booking',
  'cancel-booking',
  'toggle-slot-break',
])

// Slot helper functions
const getSlotTypeText = (slotType) => {
  const texts = {
    work: 'Рабочий слот',
    lunch: 'Перерыв',
    blocked: 'Перерыв',
  }
  return texts[slotType] || slotType
}

const getSlotStatusClass = (slot) => {
  if (slot.slot_type === 'lunch') {
    return 'bg-gray-100 text-gray-800'
  }
  if (slot.slot_type === 'blocked') {
    return 'bg-red-100 text-red-800'
  }
  if (slot.booked) {
    return 'bg-blue-100 text-blue-800'
  }
  if (slot.is_available) {
    return 'bg-green-100 text-green-800'
  }
  return 'bg-gray-100 text-gray-800'
}

const getSlotStatusText = (slot) => {
  if (slot.slot_type === 'lunch') {
    return 'Перерыв'
  }
  if (slot.slot_type === 'blocked') {
    return 'Перерыв'
  }
  if (slot.booked) {
    return 'Занято'
  }
  if (slot.is_available) {
    return 'Свободно'
  }
  return 'Недоступно'
}

const getStatusText = (status) => {
  const texts = {
    pending: 'Ожидает подтверждения',
    confirmed: 'Подтверждено',
    cancelled: 'Отменено',
  }
  return texts[status] || status
}

const isBreak = (slot) => {
  return slot.slot_type === 'blocked' || slot.slot_type === 'lunch'
}

const formatSlotTime = (timeString) => {
  // Слоты от API уже приходят как HH:MM, не используем ISO/UTC
  if (typeof timeString === 'string') {
    return timeString.substring(0, 5)
  }
  return timeString
}
</script>
