<template>
  <div v-if="showModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div class="bg-white rounded-lg p-6 w-full max-w-md">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">{{ editingServiceId ? 'Редактировать услугу' : 'Добавить услугу' }}</h3>
      <form @submit.prevent="$emit('add-service')">
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Тип услуги</label>
            <select v-model="newService.service_type" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500">
              <option value="">Выберите тип услуги</option>
              <option v-for="serviceType in availableServiceTypes" :key="serviceType" :value="serviceType">
                {{ serviceType.charAt(0).toUpperCase() + serviceType.slice(1) }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Название</label>
            <input v-model="newService.name" type="text" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Описание</label>
            <textarea v-model="newService.description" rows="3" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500"></textarea>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
                                  <label class="block text-sm font-medium text-gray-700 mb-2">Цена (MDL)</label>
              <input v-model="newService.price" type="number" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Длительность (мин)</label>
              <input v-model="newService.duration" type="number" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500" />
            </div>
          </div>
        </div>
        <div class="flex space-x-4 mt-6">
          <button type="submit" class="flex-1 bg-lime-500 hover:bg-lime-600 text-white font-semibold px-4 py-2 rounded-lg transition-colors">
            {{ editingServiceId ? 'Обновить' : 'Добавить' }}
          </button>
          <button type="button" @click="$emit('close-modal')" class="flex-1 bg-gray-300 hover:bg-gray-400 text-gray-700 font-semibold px-4 py-2 rounded-lg transition-colors">
            Отмена
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
// Props
const props = defineProps({
  showModal: {
    type: Boolean,
    required: true
  },
  editingServiceId: {
    type: [Number, null],
    required: true
  },
  newService: {
    type: Object,
    required: true
  },
  availableServiceTypes: {
    type: Array,
    required: true
  }
})

// Emits
const emit = defineEmits(['close-modal', 'add-service'])
</script> 