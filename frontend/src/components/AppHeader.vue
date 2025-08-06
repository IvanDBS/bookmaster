<template>
  <header class="bg-white border-b border-gray-100 sticky top-0 z-50">
    <div class="max-w-7xl mx-auto px-6">
      <div class="flex justify-between items-center h-20">
        <!-- Logo -->
        <div class="flex items-center space-x-3">
          <div class="flex space-x-1">
            <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
            <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
            <div class="w-3 h-3 bg-red-500 rounded-full"></div>
          </div>
          <h1 class="text-2xl font-bold text-gray-900">BookMaster</h1>
        </div>

        <!-- Navigation -->
        <nav v-if="showNavigation" class="hidden md:flex items-center space-x-8">
          <button @click="scrollToSection('calendar')" class="text-gray-600 hover:text-gray-900 font-medium transition-colors">Календарь</button>
          <button @click="scrollToSection('bookings')" class="text-gray-600 hover:text-gray-900 font-medium transition-colors">Записи</button>
          <button @click="scrollToSection('services')" class="text-gray-600 hover:text-gray-900 font-medium transition-colors">Услуги</button>
          <span v-if="pendingBookingsCount > 0" class="relative">
            <button @click="handleNotificationClick" class="text-orange-600 hover:text-orange-700 font-medium transition-colors">
              Уведомления
              <span class="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                {{ pendingBookingsCount }}
              </span>
            </button>
          </span>
        </nav>

        <!-- Actions -->
        <div class="flex items-center space-x-6">
          <div class="hidden md:flex items-center space-x-4">
            <div class="w-5 h-5 text-gray-600">
              <svg fill="currentColor" viewBox="0 0 20 20">
                <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z"/>
                <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z"/>
              </svg>
            </div>
            <span class="text-gray-600 font-medium">{{ user?.first_name }} {{ user?.last_name }}</span>
          </div>
          <button @click="handleLogout" class="bg-lime-500 hover:bg-lime-600 text-white font-semibold px-6 py-2 rounded-lg transition-colors shadow-sm">
            Выйти
          </button>
        </div>
      </div>
    </div>
  </header>
</template>

<script setup>
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'

const props = defineProps({
  showNavigation: {
    type: Boolean,
    default: false
  },
  pendingBookingsCount: {
    type: Number,
    default: 0
  }
})

const emit = defineEmits(['scroll-to-section', 'notification-click'])

const authStore = useAuthStore()
const router = useRouter()

const user = authStore.user

const handleLogout = async () => {
  await authStore.logout()
  router.push('/')
}

const scrollToSection = (sectionId) => {
  emit('scroll-to-section', sectionId)
}

const handleNotificationClick = () => {
  emit('notification-click')
}
</script> 