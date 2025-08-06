<template>
  <header class="bg-white border-b border-gray-200 fixed top-0 left-0 right-0 z-50">
    <div class="max-w-7xl mx-auto px-6">
      <div class="flex justify-between items-center h-16">
        <div class="flex items-center space-x-3">
          <div class="flex space-x-1">
            <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
            <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
            <div class="w-3 h-3 bg-red-500 rounded-full"></div>
          </div>
          <h1 class="text-xl font-bold text-gray-900">BookMaster</h1>
        </div>
        
        <div class="flex items-center space-x-4">
          <!-- Навигационные кнопки для мастера -->
          <div v-if="showNavigation" class="flex space-x-2">
            <button class="px-3 py-1 text-sm font-medium text-gray-700 bg-gray-100 rounded hover:bg-gray-200 transition-colors">
              Календарь
            </button>
            <button class="px-3 py-1 text-sm font-medium text-gray-700 bg-gray-100 rounded hover:bg-gray-200 transition-colors">
              Записи
            </button>
            <button class="px-3 py-1 text-sm font-medium text-gray-700 bg-gray-100 rounded hover:bg-gray-200 transition-colors">
              Услуги
            </button>
          </div>
          <span class="text-gray-700 font-medium">{{ user?.first_name }} {{ user?.last_name }}</span>
          <button @click="handleLogout" class="text-gray-700 font-semibold px-4 py-2 rounded-lg border border-gray-300 hover:bg-gray-50 transition-colors">
            Выйти
          </button>
        </div>
      </div>
    </div>
    <!-- Синяя полоска под хедером на всю ширину -->
    <div class="h-1 bg-gray-900 w-full"></div>
  </header>
</template>

<script setup>
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'

const props = defineProps({
  showNavigation: {
    type: Boolean,
    default: false
  }
})

const authStore = useAuthStore()
const router = useRouter()

const user = authStore.user

const handleLogout = () => {
  authStore.logout()
  router.push('/')
}
</script> 