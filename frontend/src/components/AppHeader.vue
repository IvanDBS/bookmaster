<template>
  <header class="bg-white border-b border-gray-100 sticky top-0 z-50">
    <div class="max-w-7xl mx-auto px-4 sm:px-6">
      <div class="flex justify-between items-center h-16 sm:h-20">
        <!-- Logo (match HomeView) -->
        <button
          @click="goToHome"
          class="flex items-center space-x-2 sm:space-x-3 hover:opacity-80 transition-opacity duration-200"
        >
          <div class="flex space-x-1">
            <div class="w-2 h-2 sm:w-3 sm:h-3 bg-blue-500 rounded-full"></div>
            <div class="w-2 h-2 sm:w-3 sm:h-3 bg-yellow-500 rounded-full"></div>
            <div class="w-2 h-2 sm:w-3 sm:h-3 bg-red-500 rounded-full"></div>
          </div>
          <h1 class="text-lg sm:text-2xl font-bold text-gray-900 font-sans">BookMaster</h1>
        </button>

        <!-- Navigation -->
        <nav v-if="showNavigation" class="hidden lg:flex items-center space-x-8">
          <!-- Меню для клиентов -->
          <template v-if="userType === 'client'">
            <button
              @click="scrollToSection('masters')"
              class="text-gray-600 hover:text-gray-900 font-medium transition-colors"
            >
              Мои мастера
            </button>
            <button
              @click="scrollToSection('bookings')"
              class="text-gray-600 hover:text-gray-900 font-medium transition-colors"
            >
              Мои записи
            </button>
            <button
              @click="scrollToSection('search')"
              class="text-gray-600 hover:text-gray-900 font-medium transition-colors"
            >
              Все услуги
            </button>
          </template>
          <!-- Меню для мастеров -->
          <template v-else-if="userType === 'master'">
            <button
              @click="scrollToSection('services')"
              class="text-gray-600 hover:text-gray-900 font-medium transition-colors"
            >
              Мои услуги
            </button>
            <button
              @click="scrollToSection('bookings')"
              class="text-gray-600 hover:text-gray-900 font-medium transition-colors"
            >
              Мои записи
            </button>
            <button
              @click="scrollToSection('calendar')"
              class="text-gray-600 hover:text-gray-900 font-medium transition-colors"
            >
              Календарь записей
            </button>
          </template>
        </nav>

        <!-- Actions -->
        <div class="flex items-center space-x-1 sm:space-x-2">
          <!-- Notifications Bell - только для мастеров -->
          <div v-if="userType === 'master'" class="relative">
            <button
              v-if="showNavigation && pendingBookingsCount > 0"
              @click="handleNotificationClick"
              class="w-5 h-5 sm:w-4 sm:h-4 text-gray-600 hover:text-orange-600 transition-colors"
            >
              <svg fill="currentColor" viewBox="0 0 24 24" class="w-5 h-5 sm:w-4 sm:h-4">
                <path
                  d="M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11zM7 10h5v5H7z"
                />
              </svg>
              <span
                class="absolute -top-1 -right-1 sm:-top-0.5 sm:-right-0.5 bg-red-500 text-white text-xs rounded-full h-4 w-4 sm:h-3 sm:w-3 flex items-center justify-center font-medium"
              >
                {{ pendingBookingsCount }}
              </span>
            </button>
            <div v-else-if="showNavigation" class="w-5 h-5 sm:w-4 sm:h-4 text-gray-400">
              <svg fill="currentColor" viewBox="0 0 24 24" class="w-5 h-5 sm:w-4 sm:h-4">
                <path
                  d="M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11zM7 10h5v5H7z"
                />
              </svg>
            </div>
          </div>

          <!-- User name - скрываем на мобильных и планшетах -->
          <span class="hidden xl:block text-gray-600 font-medium text-sm mr-2"
            >{{ safeFirstName }} {{ safeLastName }}</span
          >

          <!-- Mobile menu button -->
          <button
            v-if="showNavigation"
            @click="toggleMobileMenu"
            class="lg:hidden p-1.5 text-gray-600 hover:text-gray-900"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 6h16M4 12h16M4 18h16"
              ></path>
            </svg>
          </button>

          <!-- Logout button - исправляем отступы -->
          <button
            @click="handleLogout"
            class="px-2 py-1.5 text-gray-700 border border-gray-300 hover:bg-gray-50 rounded-lg transition-colors text-xs sm:text-sm whitespace-nowrap"
          >
            Выйти
          </button>
        </div>
      </div>

      <!-- Mobile Navigation Menu -->
      <div
        v-if="showNavigation && isMobileMenuOpen"
        class="lg:hidden border-t border-gray-100 py-4"
      >
        <nav class="flex flex-col space-y-4">
          <!-- Меню для клиентов -->
          <template v-if="userType === 'client'">
            <button
              @click="scrollToSection('masters')"
              class="text-left text-gray-600 hover:text-gray-900 font-medium transition-colors py-2"
            >
              Мои мастера
            </button>
            <button
              @click="scrollToSection('bookings')"
              class="text-left text-gray-600 hover:text-gray-900 font-medium transition-colors py-2"
            >
              Мои записи
            </button>
            <button
              @click="scrollToSection('search')"
              class="text-left text-gray-600 hover:text-gray-900 font-medium transition-colors py-2"
            >
              Все услуги
            </button>
          </template>
          <!-- Меню для мастеров -->
          <template v-else-if="userType === 'master'">
            <button
              @click="scrollToSection('services')"
              class="text-left text-gray-600 hover:text-gray-900 font-medium transition-colors py-2"
            >
              Мои услуги
            </button>
            <button
              @click="scrollToSection('bookings')"
              class="text-left text-gray-600 hover:text-gray-900 font-medium transition-colors py-2"
            >
              Мои записи
            </button>
            <button
              @click="scrollToSection('calendar')"
              class="text-left text-gray-600 hover:text-gray-900 font-medium transition-colors py-2"
            >
              Календарь записей
            </button>
          </template>
        </nav>
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'
import { useSanitization } from '../composables/useSanitization'

defineProps({
  showNavigation: {
    type: Boolean,
    default: false,
  },
  userType: {
    type: String,
    default: 'client',
  },
  pendingBookingsCount: {
    type: Number,
    default: 0,
  },
})

const emit = defineEmits(['scroll-to-section', 'notification-click'])

const authStore = useAuthStore()
const router = useRouter()
const { safeName } = useSanitization()

const user = computed(() => authStore.user)
const isMobileMenuOpen = ref(false)

// Безопасные computed свойства для имени пользователя
const safeFirstName = computed(() => safeName(user.value?.first_name).value)
const safeLastName = computed(() => safeName(user.value?.last_name).value)

const handleLogout = async () => {
  await authStore.logout()
  router.push('/')
}

const scrollToSection = (sectionId) => {
  // emit event for parent
  emit('scroll-to-section', sectionId)
  isMobileMenuOpen.value = false // Закрываем мобильное меню после клика
}

const handleNotificationClick = () => {
  emit('notification-click')
}

const toggleMobileMenu = () => {
  isMobileMenuOpen.value = !isMobileMenuOpen.value
}

const goToHome = () => {
  // Переходим на главную страницу в зависимости от роли пользователя
  if (user.value?.role === 'master') {
    router.push('/master/dashboard')
  } else if (user.value?.role === 'client') {
    router.push('/client/dashboard')
  } else {
    router.push('/')
  }
}
</script>
