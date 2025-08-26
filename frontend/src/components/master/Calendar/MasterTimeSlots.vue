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
          @click="$emit('toggle-day-status')"
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
        v-for="item in groupedItems"
        :key="
          item.type === 'booking'
            ? 'b-' + item.booking.id + '-' + item.start_time
            : 's-' + item.slot.id
        "
        class="bg-white rounded-lg p-3 border border-gray-200 shadow-sm hover:shadow-md transition-all duration-200"
        :class="
          item.type === 'booking'
            ? 'border-blue-200 bg-blue-50/30'
            : {
                'border-green-200 bg-green-50/30': item.slot.is_available && !item.slot.booked,
                'border-gray-200 bg-gray-50/30': item.slot.slot_type === 'lunch',
                'border-red-200 bg-red-50/30': item.slot.slot_type === 'blocked',
              }
        "
      >
        <!-- Заголовок с временем -->
        <div class="flex justify-between items-center mb-2">
          <span class="text-sm font-semibold text-gray-900">
            <template v-if="item.type === 'booking'">
              {{ item.start_time }}-{{ item.end_time }}
            </template>
            <template v-else> {{ item.slot.start_time }}-{{ item.slot.end_time }} </template>
          </span>
          <span
            v-if="item.type !== 'booking'"
            :class="getSlotStatusClass(item.slot)"
            class="px-2 py-1 rounded-full text-xs font-semibold"
          >
            {{ getSlotStatusText(item.slot) }}
          </span>
          <span
            v-else
            class="px-2 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800"
          >
            Занято
          </span>
        </div>

        <!-- Действия/данные для свободного слота -->
        <template v-if="item.type !== 'booking'">
          <p v-if="!item.slot.booked" class="text-xs text-gray-600 mb-2">
            {{ getSlotTypeText(item.slot.slot_type) }}
          </p>
          <div v-if="!item.slot.booked" class="flex justify-between items-center mb-2">
            <button
              @click="$emit('toggle-slot-break', item.slot, !isBreak(item.slot))"
              :class="[
                'relative inline-flex h-5 w-9 items-center rounded-full transition-all duration-200 focus:outline-none focus:ring-1 focus:ring-blue-500',
                isBreak(item.slot) ? 'bg-red-500' : 'bg-gray-200 hover:bg-gray-300',
              ]"
              :title="isBreak(item.slot) ? 'Сделать свободным' : 'Отметить как перерыв'"
            >
              <span
                :class="[
                  'inline-block h-3 w-3 transform rounded-full bg-white transition-all duration-200',
                  isBreak(item.slot) ? 'translate-x-4' : 'translate-x-0.5',
                ]"
              />
            </button>
          </div>
        </template>

        <!-- Данные и действия для объединенной брони -->
        <template v-else>
          <div class="space-y-1 text-xs">
            <!-- Строка 1: Имя пользователя и телефон -->
            <div class="flex justify-between items-center">
              <span class="text-gray-700 font-medium">{{ safeClientName }}</span>
              <span class="text-gray-500">{{ safeClientPhone }}</span>
            </div>
            <!-- Строка 2: Услуга и цена -->
            <div class="flex justify-between items-center">
              <span class="text-gray-600">{{ safeServiceName }}</span>
              <span class="text-gray-600 font-medium"
                >{{ props.getSlotPrice(item.booking) }} MDL</span
              >
            </div>

            <div
              v-if="item.booking.status === 'confirmed'"
              class="flex justify-between items-center text-xs mt-1"
            >
              <span class="text-gray-500 flex items-center">
                <svg class="w-3 h-3 text-green-500 mr-1" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                    clip-rule="evenodd"
                  ></path>
                </svg>
                {{ props.getStatusText(item.booking.status) }}
              </span>
              <button
                @click="props.onDeleteBooking(item.booking)"
                class="text-red-600 hover:text-red-700 font-light focus:outline-none focus:ring-2 focus:ring-red-500/20 rounded"
                title="Отменить запись"
              >
                Отменить
              </button>
            </div>

            <div
              v-if="item.booking.status === 'pending'"
              class="flex justify-between items-center text-xs mt-1"
            >
              <button
                @click="props.onConfirmBooking(item.booking)"
                class="text-green-600 hover:text-green-700 font-light focus:outline-none focus:ring-2 focus:ring-green-500/20 rounded"
                title="Подтвердить"
              >
                Подтвердить
              </button>
              <button
                @click="props.onCancelBooking(item.booking)"
                class="text-red-600 hover:text-red-700 font-light focus:outline-none focus:ring-2 focus:ring-red-500/20 rounded"
                title="Отменить"
              >
                Отменить
              </button>
            </div>
          </div>
        </template>
      </div>
    </div>

    <!-- Кнопка добавления нового слота -->
    <div v-if="selectedDateSlots.length > 0" class="mt-4 flex justify-center">
      <button
        @click="$emit('add-new-slot')"
        class="inline-flex items-center px-4 py-2 border text-sm font-medium rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:opacity-50 disabled:cursor-not-allowed bg-white"
        :class="[
          isAddingSlot
            ? 'border-gray-300 text-gray-400'
            : 'border-blue-500 text-blue-500 hover:bg-blue-50',
        ]"
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
        @click="$emit('add-new-slot')"
        class="inline-flex items-center px-3 py-1.5 border border-blue-500 text-blue-500 hover:bg-blue-50 text-xs font-medium rounded-lg transition-colors duration-200"
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
import { useFormatters } from '../../../composables/useFormatters'
import { useSanitization } from '../../../composables/useSanitization'
import { computed } from 'vue'

const props = defineProps({
  selectedDate: Date,
  selectedDateSlots: Array,
  isDayWorking: Boolean,
  isAddingSlot: Boolean,
  onConfirmBooking: Function,
  onCancelBooking: Function,
  onDeleteBooking: Function,
  getStatusText: Function,
  getSlotPrice: Function,
})

defineEmits(['toggleDayStatus', 'toggleSlotBreak', 'addNewSlot'])

const formatSelectedDate = () => {
  if (!props.selectedDate) return ''
  return props.selectedDate.toLocaleDateString('ru-RU', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
}

const { getSlotTypeText, getSlotStatusClass, getSlotStatusText, isBreak } = useFormatters()
const { safeName, safePhone } = useSanitization()

// Безопасные computed свойства для текущего элемента
const safeClientName = computed(() => {
  const currentItem = groupedItems.value.find((item) => item.type === 'booking')
  return currentItem ? safeName(currentItem.booking?.client_name).value : ''
})

const safeClientPhone = computed(() => {
  const currentItem = groupedItems.value.find((item) => item.type === 'booking')
  return currentItem ? safePhone(currentItem.booking?.client_phone).value : ''
})

const safeServiceName = computed(() => {
  const currentItem = groupedItems.value.find((item) => item.type === 'booking')
  return currentItem ? safeName(currentItem.booking?.service_name).value : ''
})

// Removed duplicated status text helper; use parent-provided getStatusText

// Группируем слоты выбранной даты: непрерывные занятые слоты одной брони → один блок
const propsLocal = props
const groupedItems = computed(() => {
  const slots = Array.isArray(propsLocal.selectedDateSlots) ? [...propsLocal.selectedDateSlots] : []
  if (slots.length === 0) return []

  // Отсортировать по времени начала (HH:MM)
  const toMinutes = (hhmm) => {
    const [h, m] = String(hhmm || '00:00')
      .split(':')
      .map((v) => parseInt(v, 10))
    return h * 60 + m
  }
  const sorted = slots.slice().sort((a, b) => toMinutes(a.start_time) - toMinutes(b.start_time))

  const items = []
  let i = 0
  while (i < sorted.length) {
    const s = sorted[i]
    if (s.booking) {
      // Начинаем группу брони
      const bookingId = s.booking.id
      let startMin = toMinutes(s.start_time)
      let endMin = toMinutes(s.end_time)
      let j = i + 1
      while (j < sorted.length) {
        const n = sorted[j]
        if (!n.booking || n.booking.id !== bookingId) break
        const nextStart = toMinutes(n.start_time)
        if (nextStart !== endMin) break // не непрерывно
        endMin = toMinutes(n.end_time)
        j += 1
      }
      const fmt = (m) =>
        `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`
      items.push({
        type: 'booking',
        booking: s.booking,
        start_time: fmt(startMin),
        end_time: fmt(endMin),
      })
      i = j
    } else {
      items.push({ type: 'slot', slot: s })
      i += 1
    }
  }
  return items
})
</script>

<style scoped></style>
