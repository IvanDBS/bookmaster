<template>
  <div class="space-y-5">
    <h4 class="text-sm font-semibold text-gray-900">Выберите тип услуги</h4>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <button
        v-for="type in serviceTypes"
        :key="type"
        @click="$emit('select', type)"
        :class="[
          'flex flex-col items-center justify-center rounded-xl border-2 p-6 text-center transition-all duration-300 transform hover:scale-105',
          selectedServiceType === type
            ? 'border-lime-500 bg-gradient-to-br from-lime-50 to-lime-100 shadow-lg'
            : 'border-gray-200 hover:border-lime-300 hover:shadow-md',
        ]"
      >
        <span class="text-3xl mb-2" v-if="type === 'маникюр'">💅</span>
        <span class="text-3xl mb-2" v-else-if="type === 'педикюр'">🦶</span>
        <span class="text-3xl mb-2" v-else>💆‍♀️</span>
        <span class="font-bold text-gray-900 text-lg">{{
          type.charAt(0).toUpperCase() + type.slice(1)
        }}</span>
        <span class="text-sm text-gray-500 mt-1">Выбор категории</span>
      </button>
    </div>
  </div>
</template>

<script setup>
defineProps({ serviceTypes: Array, selectedServiceType: String })
defineEmits(['select'])
</script>
