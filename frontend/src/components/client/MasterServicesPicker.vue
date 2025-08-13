<template>
  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <button
      v-for="srv in services"
      :key="srv.id"
      @click="$emit('select', srv)"
      :class="[
        'rounded-xl border-2 p-5 text-left transition-all duration-300 transform hover:scale-105',
        selectedId === srv.id
          ? 'border-lime-500 bg-gradient-to-br from-lime-50 to-lime-100 shadow-lg'
          : 'border-gray-200 hover:border-lime-300 hover:shadow-md',
      ]"
    >
      <div class="font-bold text-gray-900 text-lg">{{ srv.name }}</div>
      <div class="text-sm text-gray-500">{{ srv.duration }} мин</div>
      <div class="mt-2 font-bold text-lime-600 text-lg">{{ srv.price }} MDL</div>
    </button>
  </div>
</template>

<script setup>
defineProps({
  services: { type: Array, default: () => [] },
  selectedId: { type: Number, default: null },
})
defineEmits(['select'])
</script>
