<template>
  <div class="mb-8">
    <h2 class="text-3xl font-bold text-gray-900 mb-2">
      Добро пожаловать, {{ user?.first_name }}!
    </h2>
    <p class="text-gray-600">Управляйте своими услугами и записями</p>
  </div>
</template>

<script setup>
// Props
const props = defineProps({
  user: {
    type: Object,
    required: true
  }
})
</script> 