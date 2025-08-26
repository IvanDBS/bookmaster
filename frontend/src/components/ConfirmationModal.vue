<template>
  <div v-if="isVisible" class="fixed inset-0 z-50 overflow-y-auto">
    <!-- Backdrop -->
    <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity" @click="closeModal"></div>

    <!-- Modal -->
    <div class="flex min-h-full items-center justify-center p-4">
      <div
        class="relative transform overflow-hidden rounded-lg bg-white shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg"
      >
        <!-- Header -->
        <div class="bg-gradient-to-r from-blue-600 to-purple-600 px-6 py-4">
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold text-white">
              {{ title }}
            </h3>
            <button @click="closeModal" class="text-white hover:text-gray-200 transition-colors">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                ></path>
              </svg>
            </button>
          </div>
        </div>

        <!-- Content -->
        <div class="px-6 py-6">
          <div class="flex items-center mb-4">
            <div class="flex-shrink-0">
              <div
                class="w-12 h-12 rounded-full flex items-center justify-center"
                :class="{
                  'bg-yellow-100 text-yellow-600': type === 'confirm',
                  'bg-red-100 text-red-600': type === 'cancel',
                }"
              >
                <svg
                  v-if="type === 'confirm'"
                  class="w-6 h-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  ></path>
                </svg>
                <svg v-else class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
                  ></path>
                </svg>
              </div>
            </div>
            <div class="ml-4">
              <h4 class="text-lg font-medium text-gray-900">
                {{ title }}
              </h4>
              <p class="text-sm text-gray-600 mt-1">
                {{ message }}
              </p>
            </div>
          </div>

          <div v-if="booking" class="bg-gray-50 rounded-lg p-4 mb-6">
            <div class="flex justify-between items-center">
              <div>
                <p class="font-semibold text-gray-900">{{ booking?.service?.name }}</p>
                <p class="text-sm text-gray-600">{{ booking?.client_name }}</p>
                <p v-if="booking?.client_phone" class="text-sm text-gray-600">
                  {{ booking?.client_phone }}
                </p>
                <p class="text-sm text-gray-600">
                  {{ formatTime(booking?.start_time) }} - {{ formatTime(booking?.end_time) }}
                </p>
              </div>
              <div class="text-right">
                <p class="text-lg font-bold text-gray-900">{{ getSlotPrice(booking) }} MDL</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="bg-gray-50 px-6 py-4 flex justify-end space-x-3">
          <button
            @click="closeModal"
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
          >
            Отмена
          </button>
          <button
            @click="confirmAction"
            class="px-4 py-2 text-sm font-medium text-white rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors"
            :class="{
              'bg-green-600 hover:bg-green-700 focus:ring-green-500': type === 'confirm',
              'bg-red-600 hover:bg-red-700 focus:ring-red-500':
                type === 'cancel' || type === 'delete',
            }"
          >
            {{ type === 'confirm' ? 'Подтвердить' : type === 'cancel' ? 'Отменить' : 'Удалить' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { defineProps, defineEmits } from 'vue'

const props = defineProps({
  isVisible: {
    type: Boolean,
    default: false,
  },
  type: {
    type: String,
    default: 'confirm', // 'confirm' or 'cancel' or 'delete'
    validator: (value) => ['confirm', 'cancel', 'delete'].includes(value),
  },
  titleText: {
    type: String,
    default: '',
  },
  messageText: {
    type: String,
    default: '',
  },
  booking: {
    type: Object,
    required: false,
    default: null,
  },
  getSlotPrice: {
    type: Function,
    required: false,
    default: (booking) => {
      if (booking?.price) return Math.round(booking.price)
      if (booking?.service?.price) return Math.round(booking.service.price)
      return 0
    },
  },
})

const emit = defineEmits(['close', 'confirm'])

const baseTitle =
  props.type === 'confirm'
    ? 'Подтверждение записи'
    : props.type === 'cancel'
      ? 'Отмена записи'
      : 'Удаление записи'

const title = props.titleText || baseTitle

const baseMessage =
  props.type === 'confirm'
    ? 'Вы уверены, что хотите подтвердить эту запись?'
    : props.type === 'cancel'
      ? 'Вы уверены, что хотите отменить эту запись?'
      : 'Вы уверены, что хотите удалить эту запись?'

const message = props.messageText || baseMessage

const closeModal = () => {
  emit('close')
}

const confirmAction = () => {
  emit('confirm', props.booking ? props.booking.id : true)
}

const formatTime = (timeString) => {
  if (!timeString) return ''
  const date = new Date(timeString)
  return date.toLocaleTimeString('ru-RU', {
    hour: '2-digit',
    minute: '2-digit',
  })
}

// Цена берется из переданной функции родителя (или fallback по умолчанию)
</script>
