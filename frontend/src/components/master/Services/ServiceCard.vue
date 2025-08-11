<template>
  <div class="flex justify-between items-center p-4 bg-gray-50 rounded-lg">
    <div>
      <h4 class="font-semibold text-gray-900">{{ service.name }}</h4>
      <p class="text-sm text-gray-600">{{ service.description }}</p>
      <p class="text-sm text-gray-600">{{ service.duration }} мин</p>
    </div>
    <div class="text-right">
      <p class="text-lg font-semibold text-gray-900">{{ service.price }} MDL</p>
      <div class="flex space-x-2 mt-2">
        <button
          @click="$emit('edit-service', service)"
          class="text-blue-600 hover:text-blue-700 text-sm font-medium"
        >
          Редактировать
        </button>
        <button
          @click="$emit('delete-service', service.id)"
          class="text-red-600 hover:text-red-700 text-sm font-medium"
        >
          Удалить
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
// Props
const props = defineProps({
  service: {
    type: Object,
    required: true,
  },
})

// Emits
const emit = defineEmits(['edit-service', 'delete-service'])
</script>
