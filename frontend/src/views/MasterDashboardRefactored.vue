<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <AppHeader 
      :show-navigation="true" 
      user-type="master" 
      :pending-bookings-count="pendingBookingsCount" 
      @scroll-to-section="handleScrollToSection" 
      @notification-click="handleNotificationClick" 
    />
    
    <!-- Confirmation Modal -->
    <ConfirmationModal 
      :is-visible="showConfirmationModal"
      :type="modalType"
      :booking="selectedBooking"
      @close="closeConfirmationModal"
      @confirm="handleModalConfirm"
    />

    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-6 py-8 mt-20">
      <!-- Welcome Section -->
      <WelcomeSection :user="user" />

      <!-- Calendar Section -->
      <Calendar />

      <!-- Recent Bookings Section -->
      <BookingsList />

      <!-- Services Management -->
      <ServicesList />
    </div>

    <!-- Footer -->
    <footer class="bg-gray-900 text-white mt-16">
      <div class="max-w-7xl mx-auto px-6 py-12">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div>
            <div class="flex items-center space-x-3 mb-6">
              <div class="flex space-x-1">
                <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
                <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
                <div class="w-3 h-3 bg-red-500 rounded-full"></div>
              </div>
              <h4 class="text-lg font-bold">BookMaster</h4>
            </div>
            <p class="text-gray-400 leading-relaxed">
              Удобное управление записями для мастеров и клиентов. Профессиональный инструмент для вашего бизнеса.
            </p>
          </div>
          <div>
            <h4 class="text-sm font-semibold mb-6">Для мастеров</h4>
            <ul class="text-gray-400 space-y-3">
              <li><a href="#" class="hover:text-white transition-colors">Учет клиентов</a></li>
              <li><a href="#" class="hover:text-white transition-colors">Расписание</a></li>
              <li><a href="#" class="hover:text-white transition-colors">Уведомления</a></li>
              <li><a href="#" class="hover:text-white transition-colors">Аналитика</a></li>
            </ul>
          </div>
          <div>
            <h4 class="text-sm font-semibold mb-6">Для клиентов</h4>
            <ul class="text-gray-400 space-y-3">
              <li><a href="#" class="hover:text-white transition-colors">Записаться</a></li>
              <li><a href="#" class="hover:text-white transition-colors">История</a></li>
              <li><a href="#" class="hover:text-white transition-colors">Напоминания</a></li>
              <li><a href="#" class="hover:text-white transition-colors">Отзывы</a></li>
            </ul>
          </div>
          <div>
            <h4 class="text-sm font-semibold mb-6">Поддержка</h4>
            <ul class="text-gray-400 space-y-3">
              <li><a href="#" class="hover:text-white transition-colors">Помощь</a></li>
              <li><a href="#" class="hover:text-white transition-colors">Контакты</a></li>
              <li><a href="#" class="hover:text-white transition-colors">О нас</a></li>
              <li><a href="#" class="hover:text-white transition-colors">Блог</a></li>
            </ul>
          </div>
        </div>
        <div class="border-t border-gray-800 mt-12 pt-8 text-center">
          <p class="text-gray-400">© 2024 BookMaster. Все права защищены.</p>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, onActivated, nextTick } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useCalendar } from '../composables/useCalendar'
import { useBookings } from '../composables/useBookings'
import { useServices } from '../composables/useServices'
import AppHeader from '../components/AppHeader.vue'
import ConfirmationModal from '../components/ConfirmationModal.vue'
import WelcomeSection from '../components/master/Dashboard/WelcomeSection.vue'
import Calendar from '../components/master/Calendar/Calendar.vue'
import BookingsList from '../components/master/Bookings/BookingsList.vue'
import ServicesList from '../components/master/Services/ServicesList.vue'

const authStore = useAuthStore()

// Используем composables
const {
  // Functions
  loadWorkingSchedules,
  loadWorkingDayExceptions,
  loadSlotsForVisibleDates,
  refreshCalendar
} = useCalendar()

const {
  // State
  showConfirmationModal,
  modalType,
  selectedBooking,
  
  // Computed
  pendingBookingsCount,
  
  // Functions
  loadBookings,
  closeConfirmationModal,
  handleModalConfirm
} = useBookings()

const {
  // Functions
  loadServices,
  loadServiceTypes
} = useServices()

// User data
const user = ref(null)

// Navigation functions
const handleScrollToSection = (sectionId) => {
  const element = document.getElementById(sectionId)
  if (element) {
    element.scrollIntoView({ behavior: 'smooth' })
  }
}

const handleNotificationClick = () => {
  handleScrollToSection('bookings')
  // Устанавливаем фильтр на неподтвержденные записи
  // Это будет сделано через composable
}

onMounted(async () => {
  console.log('MasterDashboard mounted')
  
  // Загружаем данные пользователя
  try {
    if (authStore.token) {
      const response = await fetch('http://localhost:3000/api/v1/auth/profile', {
        headers: {
          'Authorization': `Bearer ${authStore.token}`,
        },
      })
      if (response.ok) {
        user.value = await response.json()
      }
    }
  } catch (error) {
    console.error('Error loading user data:', error)
  }
  
  // Загружаем все данные
  await loadWorkingSchedules()
  await loadWorkingDayExceptions()
  await loadServices()
  await loadServiceTypes()
  await loadBookings()
  await loadSlotsForVisibleDates()
  
  // Проверяем, возвращаемся ли мы из настроек расписания
  const fromSettings = sessionStorage.getItem('fromScheduleSettings')
  const clearCache = sessionStorage.getItem('clearSlotsCache')
  
  if (fromSettings === 'true' || clearCache === 'true') {
    console.log('Returning from schedule settings or cache clear requested, refreshing calendar...')
    await refreshCalendar()
    sessionStorage.removeItem('fromScheduleSettings')
    sessionStorage.removeItem('clearSlotsCache')
  }
})

// Очищаем кэш при активации компонента
onActivated(() => {
  // Это будет обработано в useCalendar
})
</script> 