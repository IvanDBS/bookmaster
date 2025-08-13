<template>
  <div class="min-h-screen bg-gray-50">
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
    <div class="max-w-7xl mx-auto px-6 py-6 mt-8">
      <!-- Welcome Section -->
      <WelcomeSection :user="user || {}" />

      <!-- Calendar Section -->
      <div id="calendar" class="mb-6 mt-8">
        <MasterCalendar
          :on-confirm-booking="bookings.showConfirmModal"
          :on-cancel-booking="bookings.showCancelModal"
          :on-delete-booking="bookings.showCancelModal"
          :get-status-text="bookings.getStatusText"
          :get-slot-price="bookings.getSlotPrice"
          :refresh-tick="bookings.refreshTick.value"
          @goToScheduleSettings="goToScheduleSettings"
        />
      </div>
      <!-- Recent Bookings Section -->
      <div id="bookings" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-6 mt-8">
        <div class="px-6 py-3 border-b border-gray-200">
          <div class="flex justify-between items-center">
            <h3 class="text-lg font-semibold text-gray-900">Мои записи</h3>
            <!-- Кнопки сортировки -->
            <div class="flex space-x-1">
              <button
                @click="bookings.setBookingFilter('all')"
                :class="
                  bookings.bookingFilter.value === 'all'
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-700'
                "
                class="px-2 py-1 text-xs font-medium rounded transition-colors border bg-white"
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
                class="px-2 py-1 text-xs font-medium rounded transition-colors border bg-white"
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
                class="px-2 py-1 text-xs font-medium rounded transition-colors border bg-white"
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
                class="px-2 py-1 text-xs font-medium rounded transition-colors border bg-white"
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
            <div
              v-for="booking in (bookings.filteredBookings.value || []).filter((b) => b && b.id)"
              :key="booking.id"
              class="flex justify-between items-center p-3 bg-gray-50 rounded-lg"
            >
              <div>
                <p class="font-medium text-gray-900 text-sm">{{ booking.service?.name }}</p>
                <p class="text-xs text-gray-600">{{ booking.client_name }}</p>
                <p class="text-xs text-gray-600">
                  {{ bookings.formatDate(booking.start_time) }} в
                  {{ bookings.formatTime(booking.start_time) }}
                </p>
              </div>
              <div class="text-right">
                <span
                  :class="bookings.getStatusClass(booking.status)"
                  class="px-2 py-1 rounded-full text-xs font-semibold"
                >
                  {{ bookings.getStatusText(booking.status) }}
                </span>
                <p class="text-sm font-semibold text-gray-900 mt-1">
                  {{ booking?.service?.price ? Math.round(booking.service.price) : 0 }} MDL
                </p>
                <div
                  v-if="booking.status === 'pending'"
                  class="flex justify-between items-center text-xs mt-2"
                >
                  <button
                    @click="bookings.showConfirmModal(booking)"
                    class="text-green-600 hover:text-green-700 font-light focus:outline-none focus:ring-2 focus:ring-green-500/20 rounded"
                    title="Подтвердить"
                  >
                    Подтвердить
                  </button>
                  <button
                    @click="bookings.showCancelModal(booking)"
                    class="text-red-600 hover:text-red-700 font-light focus:outline-none focus:ring-2 focus:ring-red-500/20 rounded"
                    title="Отменить"
                  >
                    Отменить
                  </button>
                </div>
              </div>
            </div>
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
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import AppHeader from '../components/AppHeader.vue'
import AppFooter from '../components/AppFooter.vue'
import ConfirmationModal from '../components/ConfirmationModal.vue'
import WelcomeSection from '../components/master/Dashboard/WelcomeSection.vue'
import ServicesList from '../components/master/Services/ServicesList.vue'
import MasterCalendar from '../components/master/Calendar/MasterCalendar.vue'
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
})

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
