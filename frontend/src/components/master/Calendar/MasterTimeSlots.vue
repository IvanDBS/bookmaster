<template>
  <div v-if="selectedDate" class="mt-8">
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center space-x-2">
        <div class="w-1 h-6 bg-gradient-to-b from-blue-500 to-blue-600 rounded-full"></div>
        <div>
          <h5 class="text-lg font-semibold text-gray-900">
            Временные слоты на {{ formatSelectedDate() }}
          </h5>
          <p class="text-xs text-gray-600 mt-0.5">Управление расписанием</p>
        </div>
      </div>

      <!-- Toggle Switch для управления статусом дня -->
      <div
        class="flex items-center space-x-3 bg-gray-50 px-3 py-1.5 rounded-lg border border-gray-200"
      >
        <span class="text-sm text-gray-700">Рабочий день</span>
        <button
          @click="$emit('toggleDayStatus')"
          :class="[
            'relative inline-flex h-5 w-9 items-center rounded-full transition-all duration-200 focus:outline-none focus:ring-1 focus:ring-blue-500',
            isDayWorking ? 'bg-blue-600' : 'bg-gray-300 hover:bg-gray-400',
          ]"
          role="switch"
          :aria-checked="isDayWorking"
        >
          <span
            :class="[
              'inline-block h-3 w-3 transform rounded-full bg-white transition-all duration-200',
              isDayWorking ? 'translate-x-4' : 'translate-x-0.5',
            ]"
          />
        </button>
      </div>
    </div>

    <!-- Slots Grid (only show if there are slots) -->
    <div
      v-if="selectedDateSlots.length > 0"
      class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-2"
    >
      <div
        v-for="slot in selectedDateSlots"
        :key="slot.id"
        class="bg-white rounded-lg p-3 border border-gray-200 shadow-sm hover:shadow-md transition-all duration-200"
        :class="{
          'border-green-200 bg-green-50/30': slot.is_available && !slot.booked,
          'border-blue-200 bg-blue-50/30': slot.booked,
          'border-gray-200 bg-gray-50/30': slot.slot_type === 'lunch',
          'border-red-200 bg-red-50/30': slot.slot_type === 'blocked',
        }"
      >
        <!-- Время и статус в одной строке -->
        <div class="flex justify-between items-center mb-2">
          <span class="text-sm font-semibold text-gray-900"
            >{{ slot.start_time }}-{{ slot.end_time }}</span
          >
          <span
            :class="getSlotStatusClass(slot)"
            class="px-2 py-1 rounded-full text-xs font-semibold"
          >
            {{ getSlotStatusText(slot) }}
          </span>
        </div>

        <!-- Тип слота (только для свободных слотов) -->
        <p v-if="!slot.booked" class="text-xs text-gray-600 mb-2">
          {{ getSlotTypeText(slot.slot_type) }}
        </p>

        <!-- Переключатель перерыва для свободных слотов -->
        <div v-if="!slot.booked" class="flex justify-between items-center mb-2">
          <button
            @click="$emit('toggleSlotBreak', slot, !isBreak(slot))"
            :class="[
              'relative inline-flex h-5 w-9 items-center rounded-full transition-all duration-200 focus:outline-none focus:ring-1 focus:ring-blue-500',
              isBreak(slot) ? 'bg-red-500' : 'bg-gray-200 hover:bg-gray-300',
            ]"
            :title="isBreak(slot) ? 'Сделать свободным' : 'Отметить как перерыв'"
          >
            <span
              :class="[
                'inline-block h-3 w-3 transform rounded-full bg-white transition-all duration-200',
                isBreak(slot) ? 'translate-x-4' : 'translate-x-0.5',
              ]"
            />
          </button>
        </div>

        <!-- Информация о записи (компактно) -->
        <div v-if="slot.booking" class="space-y-2 text-xs">
          <!-- Клиент -->
          <div class="text-gray-700 font-medium">{{ slot.booking.client_name }}</div>

          <!-- Услуга -->
          <div class="text-gray-600">{{ slot.booking.service_name }}</div>

          <!-- Цена -->
          <div class="text-gray-600 text-xs">{{ props.getSlotPrice(slot.booking) }} MDL</div>

          <!-- Статус записи и кнопка отмены в одной строке -->
          <div
            v-if="slot.booking.status === 'confirmed'"
            class="flex justify-between items-center text-xs mb-2"
          >
            <span class="text-gray-500 flex items-center">
              <svg class="w-3 h-3 text-green-500 mr-1" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fill-rule="evenodd"
                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                  clip-rule="evenodd"
                ></path>
              </svg>
              {{ props.getStatusText(slot.booking.status) }}
            </span>
            <button
              @click="props.showDeleteModal(slot.booking)"
              class="text-red-600 hover:text-red-700"
              title="Отменить запись"
            >
              Отменить
            </button>
          </div>

          <!-- Кнопки действий для pending -->
          <div
            v-if="slot.booking.status === 'pending'"
            class="flex justify-between items-center text-xs"
          >
            <button
              @click="props.showConfirmModal(slot.booking)"
              class="text-green-600 hover:text-green-700 font-medium"
              title="Подтвердить"
            >
              Подтвердить
            </button>
            <button
              @click="props.showCancelModal(slot.booking)"
              class="text-red-600 hover:text-red-700 font-medium"
              title="Отменить"
            >
              Отменить
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Кнопка добавления нового слота -->
    <div v-if="selectedDateSlots.length > 0" class="mt-4 flex justify-center">
      <button
        @click="$emit('addNewSlot')"
        class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-lg shadow-sm transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-blue-700"
        :class="[isAddingSlot ? 'bg-gray-400 text-white' : 'bg-blue-600 text-white']"
        :disabled="isAddingSlot"
      >
        <svg
          v-if="isAddingSlot"
          class="animate-spin -ml-1 mr-2 h-4 w-4"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle
            class="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            stroke-width="4"
          ></circle>
          <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          ></path>
        </svg>
        <svg
          v-else
          class="-ml-1 mr-2 h-4 w-4"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 6v6m0 0v6m0-6h6m-6 0H6"
          ></path>
        </svg>
        <span>{{ isAddingSlot ? 'Добавляем...' : 'Добавить слот' }}</span>
      </button>
    </div>
  </div>

  <div v-if="selectedDate && selectedDateSlots.length === 0" class="mt-6 text-center py-8">
    <div class="max-w-md mx-auto">
      <div class="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-3">
        <svg class="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
          ></path>
        </svg>
      </div>
      <h3 class="text-base font-semibold text-gray-900 mb-2">Слотов пока нет</h3>
      <p class="text-sm text-gray-600 mb-4">
        На выбранную дату временные слоты не созданы. Создайте первый слот, чтобы начать принимать
        записи.
      </p>
      <button
        @click="$emit('addNewSlot')"
        class="inline-flex items-center px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-medium rounded-lg transition-colors duration-200 shadow-sm"
      >
        <svg class="w-3 h-3 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 6v6m0 0v6m0-6h6m-6 0H6"
          ></path>
        </svg>
        Создать слот
      </button>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  selectedDate: Date,
  selectedDateSlots: Array,
  isDayWorking: Boolean,
  isAddingSlot: Boolean,
  showConfirmModal: Function,
  showCancelModal: Function,
  showDeleteModal: Function,
  getStatusText: Function,
  getSlotPrice: Function,
})

const emit = defineEmits(['toggleDayStatus', 'toggleSlotBreak', 'addNewSlot'])

const formatSelectedDate = () => {
  if (!props.selectedDate) return ''
  return props.selectedDate.toLocaleDateString('ru-RU', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
}

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

const isBreak = (slot) => slot.slot_type === 'blocked' || slot.slot_type === 'lunch'

const getStatusText = (status) => {
  const texts = {
    pending: 'Ожидает подтверждения',
    confirmed: 'Подтверждено',
    cancelled: 'Отменено',
  }
  return texts[status] || status
}
</script>

<style scoped></style>
