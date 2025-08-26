<template>
  <div class="flex justify-between items-center p-4 bg-gray-50 rounded-lg">
    <div>
      <h4 class="font-semibold text-gray-900">{{ safeServiceName }}</h4>
      <p class="text-sm text-gray-600">{{ safeServiceDescription }}</p>
      <p class="text-sm text-gray-600">{{ service.duration }} мин</p>
    </div>
    <div class="text-right">
      <p class="text-lg font-semibold text-gray-900">{{ formatPrice(service.price) }} MDL</p>
      <div class="flex space-x-2 mt-2 text-xs font-light">
        <button @click="$emit('edit-service', service)" class="text-blue-600 hover:text-blue-700">
          Редактировать
        </button>
        <button
          @click="$emit('delete-service', service.id)"
          class="text-red-600 hover:text-red-700"
        >
          Удалить
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useSanitization } from '../../../composables/useSanitization'

const props = defineProps({
  service: {
    type: Object,
    required: true,
  },
})

defineEmits(['edit-service', 'delete-service'])

const { safeName, safeDescription } = useSanitization()

// Безопасные computed свойства
const safeServiceName = computed(() => safeName(props.service?.name).value)
const safeServiceDescription = computed(() => safeDescription(props.service?.description).value)

const formatPrice = (value) => {
  const num = Number(value)
  if (Number.isNaN(num)) return 0
  return Math.round(num)
}
</script>
