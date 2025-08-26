<template>
  <div class="min-h-screen bg-gray-50 overflow-x-hidden">
    <!-- Header -->
    <AppHeader
      :show-navigation="true"
      user-type="master"
      :pending-bookings-count="bookings.pendingBookingsCount.value"
      @scroll-to-section="handleScrollToSection"
      @notification-click="handleNotificationClick"
    />

    <!-- Confirmation Modal -->
    <ConfirmationModal
      :is-visible="bookings.showConfirmationModal.value"
      :type="bookings.modalType.value"
      :booking="bookings.selectedBooking.value"
      :get-slot-price="bookings.getSlotPrice"
      @close="bookings.closeConfirmationModal"
      @confirm="bookings.handleModalConfirm"
    />

    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 py-2">
      <!-- Welcome Section -->
      <div class="pt-1 sm:pt-2">
        <WelcomeSection :user="user || {}" />
      </div>

      <!-- Calendar Section -->
      <div id="calendar" class="mb-6 mt-8">
        <MasterCalendar
          :on-confirm-booking="bookings.showConfirmModal"
          :on-cancel-booking="bookings.showCancelModal"
          :on-delete-booking="bookings.showCancelModal"
          :get-status-text="bookings.getStatusText"
          :get-slot-price="bookings.getSlotPrice"
          :refresh-tick="bookings.refreshTick.value"
          @go-to-schedule-settings="goToScheduleSettings"
        />
      </div>
      <!-- Recent Bookings Section -->
      <div id="bookings" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-6 mt-8">
        <div class="px-4 sm:px-6 py-3 border-b border-gray-200">
          <div
            class="flex flex-col sm:flex-row sm:justify-between sm:items-center space-y-3 sm:space-y-0"
          >
            <h3 class="text-lg font-semibold text-gray-900">Мои записи</h3>
            <!-- Кнопки сортировки - адаптивные -->
            <div class="flex flex-wrap gap-1">
              <button
                @click="bookings.setBookingFilter('all')"
                :class="
                  bookings.bookingFilter.value === 'all'
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-700'
                "
                class="px-2 py-1 text-xs font-medium rounded transition-colors border bg-white whitespace-nowrap"
              >
                Все
              </button>
              <button
                @click="bookings.setBookingFilter('pending')"
                :class="
                  bookings.bookingFilter.value === 'pending'
                    ? 'border-yellow-500 text-yellow-600'
                    : 'border-transparent text-gray-700'
                "
                class="px-2 py-1 text-xs font-medium rounded transition-colors border bg-white whitespace-nowrap"
              >
                Ожидает
              </button>
              <button
                @click="bookings.setBookingFilter('confirmed')"
                :class="
                  bookings.bookingFilter.value === 'confirmed'
                    ? 'border-green-500 text-green-600'
                    : 'border-transparent text-gray-700'
                "
                class="px-2 py-1 text-xs font-medium rounded transition-colors border bg-white whitespace-nowrap"
              >
                Подтверждено
              </button>
              <button
                @click="bookings.setBookingFilter('cancelled')"
                :class="
                  bookings.bookingFilter.value === 'cancelled'
                    ? 'border-red-500 text-red-600'
                    : 'border-transparent text-gray-700'
                "
                class="px-2 py-1 text-xs font-medium rounded transition-colors border bg-white whitespace-nowrap"
              >
                Отменено
              </button>
            </div>
          </div>
        </div>
        <div class="p-4">
          <div v-if="bookings.filteredBookings.value.length === 0" class="text-center py-6">
            <p class="text-gray-500">У вас пока нет записей</p>
          </div>
          <div v-else class="space-y-2">
            <BookingCard
              v-for="booking in (bookings.filteredBookings.value || []).filter((b) => b && b.id)"
              :key="booking.id"
              :booking="booking"
              @show-confirm-modal="bookings.showConfirmModal"
              @show-cancel-modal="bookings.showCancelModal"
            />
          </div>
        </div>
      </div>

      <!-- Services Management -->
      <div class="mt-6">
        <ServicesList />
      </div>
    </div>

    <AppFooter />
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import AppHeader from '../components/AppHeader.vue'
import AppFooter from '../components/AppFooter.vue'
import ConfirmationModal from '../components/ConfirmationModal.vue'
import WelcomeSection from '../components/master/Dashboard/WelcomeSection.vue'
import ServicesList from '../components/master/Services/ServicesList.vue'
import MasterCalendar from '../components/master/Calendar/MasterCalendar.vue'
import BookingCard from '../components/master/Bookings/BookingCard.vue'
import { useBookings } from '../composables/useBookings'

const authStore = useAuthStore()
const router = useRouter()
const bookings = useBookings()
const user = ref(null)

onMounted(async () => {
  // sync local user for WelcomeSection
  user.value = authStore.user
  if (authStore.token && !authStore.user) {
    await authStore.getCurrentUser()
    user.value = authStore.user
  }
  await bookings.loadBookings()
  
  // Добавляем обработчик события создания записи
  window.addEventListener('booking:created', handleBookingCreated)
  
  // Автообновление при фокусе на окно
  window.addEventListener('focus', handleBookingCreated)
})

onBeforeUnmount(() => {
  // Удаляем обработчики событий
  window.removeEventListener('booking:created', handleBookingCreated)
  window.removeEventListener('focus', handleBookingCreated)
})

const handleBookingCreated = async () => {
  try {
    // Обновляем данные записей
    await bookings.loadBookings()
    // Увеличиваем refreshTick для обновления календаря
    bookings.refreshTick.value++
  } catch (error) {
    console.error('Error handling booking created event:', error)
  }
}



const handleScrollToSection = (sectionId) => {
  const element = document.getElementById(sectionId)
  if (!element) return
  const offset = 100
  const elementPosition = element.offsetTop - offset
  window.scrollTo({ top: elementPosition, behavior: 'smooth' })
}

const handleNotificationClick = () => {
  handleScrollToSection('bookings')
  bookings.setBookingFilter('pending')
}

const goToScheduleSettings = () => {
  router.push('/master/schedule')
}

// price/status helpers moved into useBookings
</script>
