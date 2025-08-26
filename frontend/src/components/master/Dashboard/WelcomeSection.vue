<template>
  <div class="mb-4 sm:mb-6">
    <h2 class="text-xl sm:text-2xl lg:text-3xl font-bold text-gray-900 mb-1 sm:mb-2">
      Добро пожаловать, {{ safeFirstName }}!
    </h2>
    <p class="text-gray-600 text-sm sm:text-base">Управляйте своими услугами и записями</p>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useSanitization } from '../../../composables/useSanitization'

const props = defineProps({
  user: {
    type: Object,
    required: true,
  },
})

const { safeName } = useSanitization()

// Безопасное отображение имени
const safeFirstName = computed(() => safeName(props.user?.first_name).value)
</script>
