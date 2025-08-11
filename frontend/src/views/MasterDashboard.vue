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
      @close="bookings.closeConfirmationModal"
      @confirm="bookings.handleModalConfirm"
    />

    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-6 py-6 mt-20">
      <!-- Welcome Section -->
      <WelcomeSection :user="user" />

      <!-- Calendar Section -->
      <div id="calendar" class="mb-6 mt-8">
        <MasterCalendar
          :show-confirm-modal="bookings.showConfirmModal"
          :show-cancel-modal="bookings.showCancelModal"
          :show-delete-modal="bookings.showCancelModal"
          :get-status-text="bookings.getStatusText"
          :get-slot-price="getSlotPrice"
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
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700'
                "
                class="px-2 py-1 text-xs font-medium rounded hover:bg-gray-200 transition-colors"
              >
                Все
              </button>
              <button
                @click="bookings.setBookingFilter('pending')"
                :class="
                  bookings.bookingFilter.value === 'pending'
                    ? 'bg-yellow-500 text-white'
                    : 'bg-gray-100 text-gray-700'
                "
                class="px-2 py-1 text-xs font-medium rounded hover:bg-gray-200 transition-colors"
              >
                Ожидает
              </button>
              <button
                @click="bookings.setBookingFilter('confirmed')"
                :class="
                  bookings.bookingFilter.value === 'confirmed'
                    ? 'bg-green-500 text-white'
                    : 'bg-gray-100 text-gray-700'
                "
                class="px-2 py-1 text-xs font-medium rounded hover:bg-gray-200 transition-colors"
              >
                Подтверждено
              </button>
              <button
                @click="bookings.setBookingFilter('cancelled')"
                :class="
                  bookings.bookingFilter.value === 'cancelled'
                    ? 'bg-red-500 text-white'
                    : 'bg-gray-100 text-gray-700'
                "
                class="px-2 py-1 text-xs font-medium rounded hover:bg-gray-200 transition-colors"
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
                    class="text-green-600 hover:text-green-700 font-medium"
                    title="Подтвердить"
                  >
                    Подтвердить
                  </button>
                  <button
                    @click="bookings.showCancelModal(booking)"
                    class="text-red-600 hover:text-red-700 font-medium"
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
              Удобное управление записями для мастеров и клиентов. Профессиональный инструмент для
              вашего бизнеса.
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
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import AppHeader from '../components/AppHeader.vue'
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
  if (authStore.token && !authStore.user) {
    await authStore.getCurrentUser()
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

const getSlotPrice = (booking) => {
  if (booking?.price) return Math.round(booking.price)
  if (!booking?.service?.price) {
    const source = Array.isArray(bookings.recentBookings?.value)
      ? bookings.recentBookings.value
      : []
    const fullVersion = source.find((b) => b && b.id === booking.id)
    if (fullVersion?.service?.price) return Math.round(fullVersion.service.price)
  }
  if (booking?.service?.price) return Math.round(booking.service.price)
  return 0
}
</script>
