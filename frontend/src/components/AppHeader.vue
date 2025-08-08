<template>
  <header class="bg-white border-b border-gray-100 sticky top-0 z-50">
    <div class="max-w-7xl mx-auto px-6">
      <div class="flex justify-between items-center h-20">
        <!-- Logo (match HomeView) -->
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
          <button @click="scrollToSection('masters')" class="text-gray-600 hover:text-gray-900 font-medium transition-colors">Мои мастера</button>
          <button @click="scrollToSection('bookings')" class="text-gray-600 hover:text-gray-900 font-medium transition-colors">Мои записи</button>
          <button @click="scrollToSection('search')" class="text-gray-600 hover:text-gray-900 font-medium transition-colors">Все услуги</button>
        </nav>

        <!-- Actions -->
        <div class="flex items-center space-x-6">
          <div class="hidden md:flex items-center space-x-4">
            <!-- Notifications Bell -->
            <div class="relative">
              <button v-if="showNavigation && pendingBookingsCount > 0" @click="handleNotificationClick" class="w-6 h-6 text-gray-600 hover:text-orange-600 transition-colors">
                <svg fill="currentColor" viewBox="0 0 20 20">
                  <path d="M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6zM10 18a3 3 0 01-3-3h6a3 3 0 01-3 3z"/>
                </svg>
                <span class="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center font-medium">
                  {{ pendingBookingsCount }}
                </span>
              </button>
              <div v-else-if="showNavigation" class="w-6 h-6 text-gray-400">
                <svg fill="currentColor" viewBox="0 0 20 20">
                  <path d="M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6zM10 18a3 3 0 01-3-3h6a3 3 0 01-3 3z"/>
                </svg>
              </div>
            </div>
            <span class="text-gray-600 font-medium">{{ user?.first_name }} {{ user?.last_name }}</span>
          </div>
          
          <!-- Mobile menu button -->
          <button v-if="showNavigation" @click="toggleMobileMenu" class="md:hidden p-2 text-gray-600 hover:text-gray-900">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
            </svg>
          </button>
          
          <button @click="handleLogout" class="btn-primary px-6 py-2">
            Выйти
          </button>
        </div>
      </div>
      
      <!-- Mobile Navigation Menu -->
      <div v-if="showNavigation && isMobileMenuOpen" class="md:hidden border-t border-gray-100 py-4">
        <nav class="flex flex-col space-y-4">
          <button @click="scrollToSection('masters')" class="text-left text-gray-600 hover:text-gray-900 font-medium transition-colors py-2">Мои мастера</button>
          <button @click="scrollToSection('bookings')" class="text-left text-gray-600 hover:text-gray-900 font-medium transition-colors py-2">Мои записи</button>
          <button @click="scrollToSection('search')" class="text-left text-gray-600 hover:text-gray-900 font-medium transition-colors py-2">Все услуги</button>
        </nav>
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref } from 'vue'
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
const isMobileMenuOpen = ref(false)

const handleLogout = async () => {
  await authStore.logout()
  router.push('/')
}

const scrollToSection = (sectionId) => {
  emit('scroll-to-section', sectionId)
  isMobileMenuOpen.value = false // Закрываем мобильное меню после клика
}

const handleNotificationClick = () => {
  emit('notification-click')
}

const toggleMobileMenu = () => {
  isMobileMenuOpen.value = !isMobileMenuOpen.value
}
</script> 