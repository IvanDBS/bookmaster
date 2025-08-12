<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
    <!-- Header -->
    <AppHeader
      :show-navigation="true"
      user-type="client"
      :pending-bookings-count="0"
      @scroll-to-section="handleScrollToSection"
    />

    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-6 py-6">
      <!-- Welcome Section -->
      <div class="mb-6">
        <h2
          class="text-3xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 bg-clip-text text-transparent mb-2"
        >
          Добро пожаловать, {{ user?.first_name }}!
        </h2>
        <p class="text-gray-600 text-lg">Управляйте своими записями и находите новых мастеров</p>
      </div>

      

      <!-- My Masters Section removed per request: show only booking wizard -->

      <!-- Booking Wizard (минималистичный) -->
      <BookingWizard>
        <div class="space-y-8">
          <!-- Stepper -->
          <WizardStepper :current="currentStep" />

          <!-- Step 1: choose service type -->
          <div v-if="currentStep === 1" class="space-y-5">
            <h4 class="text-sm font-semibold text-gray-900">Выберите тип услуги</h4>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <button
                v-for="type in serviceTypes"
                :key="type"
                @click="selectServiceType(type)"
                :class="[
                  'flex flex-col items-center justify-center rounded-xl border-2 p-6 text-center transition-all duration-300 transform hover:scale-105',
                  selectedServiceType === type
                    ? 'border-lime-500 bg-gradient-to-br from-lime-50 to-lime-100 shadow-lg'
                    : 'border-gray-200 hover:border-lime-300 hover:shadow-md',
                ]"
              >
                <span class="text-3xl mb-2" v-if="type === 'маникюр'">💅</span>
                <span class="text-3xl mb-2" v-else-if="type === 'педикюр'">🦶</span>
                <span class="text-3xl mb-2" v-else>💆‍♀️</span>
                <span class="font-bold text-gray-900 text-lg">{{
                  type.charAt(0).toUpperCase() + type.slice(1)
                }}</span>
                <span class="text-sm text-gray-500 mt-1">Выбор категории</span>
              </button>
            </div>
          </div>

          <!-- Step 2: choose master -->
          <div v-if="currentStep === 2" class="space-y-5">
            <h4 class="text-sm font-semibold text-gray-900">
              Выберите мастера для услуги "{{ selectedServiceType }}"
            </h4>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <button
                v-for="master in mastersForType"
                :key="master.id"
                @click="selectMaster(master)"
                :class="[
                  'rounded-xl border-2 p-5 text-left transition-all duration-300 transform hover:scale-105',
                  selectedMaster?.id === master.id
                    ? 'border-lime-500 bg-gradient-to-br from-lime-50 to-lime-100 shadow-lg'
                    : 'border-gray-200 hover:border-lime-300 hover:shadow-md',
                ]"
              >
                <div class="flex items-center space-x-4">
                  <div
                    class="w-12 h-12 rounded-full bg-gradient-to-br from-lime-400 to-lime-600 flex items-center justify-center text-white font-bold shadow-md"
                  >
                    {{ master.user.first_name[0] }}
                  </div>
                  <div class="flex-1">
                    <div class="font-bold text-gray-900 text-lg">
                      {{ master.user.first_name }} {{ master.user.last_name }}
                    </div>
                    <div class="text-sm text-gray-500">{{ master.services.length }} услуг</div>
                  </div>
                  <div class="text-right">
                    <div class="text-sm font-bold text-lime-600">
                      от {{ minPrice(master.services) }} MDL
                    </div>
                  </div>
                </div>
              </button>
            </div>
            <div class="flex justify-between">
              <button class="text-sm text-gray-600" @click="goBackToStep1">← Назад</button>
              <button class="text-sm text-lime-700" @click="currentStep = 3">Далее →</button>
            </div>
          </div>

          <!-- Step 3: choose concrete service -->
          <Step3SelectService
            v-if="currentStep === 3"
            :master="selectedMaster"
            :services="selectedMasterServices"
            :selected-service-id="selectedService?.id || null"
            @select="selectConcreteService"
            @back="currentStep = 2"
          />

          <!-- Step 4: choose time slot -->
          <Step4SelectTime
            v-if="currentStep === 4"
            :master-id="selectedMaster?.id"
            :selected-date="selectedCalendarDate"
            @date-selected="onDateSelected"
            @slot-selected="onSlotSelected"
            @back="goBackToMasters"
          />

          <!-- Step 5: confirm -->
          <Step5Confirm
            v-if="currentStep === 5"
            :master="selectedMaster"
            :service="selectedService"
            :date="selectedDate"
            :slot="selectedSlot"
            @back="currentStep = 4"
            @submit="submitBooking"
          />
        </div>
      </BookingWizard>
      <!-- My Masters Section (ниже визарда) -->
      <div id="masters" class="mt-8">
        <MyMasters :masters="myMasters" @select-master="selectMasterForBooking" />
      </div>

      <!-- My Current Bookings -->
      <BookingsList id="bookings" :bookings="currentBookings" />

      <!-- Booking History -->
      <BookingHistory :bookings="bookingHistory" @delete-booking="deleteBooking" @clear-history="clearHistory" />
    </div>

    <!-- Footer -->
    <footer class="bg-gray-900 text-white mt-16">
      <div class="max-w-7xl mx-auto px-6 py-12">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
          <!-- Logo and Description -->
          <div class="col-span-1 md:col-span-2">
            <div class="flex items-center space-x-3 mb-4">
              <div class="flex space-x-1">
                <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
                <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
                <div class="w-3 h-3 bg-red-500 rounded-full"></div>
              </div>
              <h3 class="text-xl font-bold">BookMaster</h3>
            </div>
            <p class="text-gray-400 mb-4">
              Удобная платформа для записи к мастерам. Найдите своего мастера и запишитесь на услугу
              в несколько кликов.
            </p>
            <div class="flex space-x-4">
              <a href="#" class="text-gray-400 hover:text-white transition-colors">
                <span class="sr-only">Telegram</span>
                <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24">
                  <path
                    d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.894 8.221l-1.97 9.28c-.145.658-.537.818-1.084.508l-3-2.21-1.446 1.394c-.14.18-.357.295-.6.295-.002 0-.003 0-.005 0l.213-3.054 5.56-5.022c.24-.213-.054-.334-.373-.121l-6.869 4.326-2.96-.924c-.64-.203-.658-.64.135-.954l11.566-4.458c.538-.196 1.006.128.832.941z"
                  />
                </svg>
              </a>
              <a href="#" class="text-gray-400 hover:text-white transition-colors">
                <span class="sr-only">WhatsApp</span>
                <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24">
                  <path
                    d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.885 3.488"
                  />
                </svg>
              </a>
            </div>
          </div>

          <!-- Quick Links -->
          <div>
            <h4 class="text-lg font-semibold mb-4">Быстрые ссылки</h4>
            <ul class="space-y-2">
              <li>
                <a href="#" class="text-gray-400 hover:text-white transition-colors">О нас</a>
              </li>
              <li>
                <a href="#" class="text-gray-400 hover:text-white transition-colors"
                  >Как это работает</a
                >
              </li>
              <li>
                <a href="#" class="text-gray-400 hover:text-white transition-colors"
                  >Стать мастером</a
                >
              </li>
              <li>
                <a href="#" class="text-gray-400 hover:text-white transition-colors">Поддержка</a>
              </li>
            </ul>
          </div>

          <!-- Contact -->
          <div>
            <h4 class="text-lg font-semibold mb-4">Контакты</h4>
            <ul class="space-y-2">
              <li class="text-gray-400">+373 699 9 999</li>
              <li class="text-gray-400">support@bookmaster.ru</li>
              <li class="text-gray-400">Chisinau, MD</li>
            </ul>
          </div>
        </div>

        <div class="border-t border-gray-800 mt-8 pt-8">
          <div class="flex flex-col md:flex-row justify-between items-center">
            <p class="text-gray-400 text-sm">© 2024 BookMaster. Все права защищены.</p>
            <div class="flex space-x-6 mt-4 md:mt-0">
              <a href="#" class="text-gray-400 hover:text-white text-sm transition-colors"
                >Политика конфиденциальности</a
              >
              <a href="#" class="text-gray-400 hover:text-white text-sm transition-colors"
                >Условия использования</a
              >
            </div>
          </div>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useClientBookingWizard } from '../composables/useClientBookingWizard'
import { useClientMasters } from '../composables/useClientMasters'
import AppHeader from '../components/AppHeader.vue'
import AppFooter from '../components/AppFooter.vue'
import MyMasters from '../components/client/MyMasters.vue'
import BookingWizard from '../components/client/BookingWizard.vue'
import WizardStepper from '../components/client/WizardStepper.vue'
import Step1SelectType from '../components/client/wizard/Step1SelectType.vue'
import Step2SelectMaster from '../components/client/wizard/Step2SelectMaster.vue'
import Step3SelectService from '../components/client/wizard/Step3SelectService.vue'
import Step4SelectTime from '../components/client/wizard/Step4SelectTime.vue'
import Step5Confirm from '../components/client/wizard/Step5Confirm.vue'
import BookingsList from '../components/client/BookingsList.vue'
import BookingHistory from '../components/client/BookingHistory.vue'
import api from '../services/api'

const authStore = useAuthStore()
// formatters used inside step components

const user = computed(() => authStore.user)
// Masters list via composable
const { myMasters, isLoadingMasters, loadMyMasters } = useClientMasters(authStore)
const currentBookings = ref([])
const bookingHistory = ref([])

// Booking wizard state via composable
const {
  currentStep,
  serviceTypes,
  selectedServiceType,
  mastersForType,
  selectedMaster,
  selectedMasterServices,
  selectedService,
  selectedDate,
  selectedCalendarDate,
  daySlots,
  selectedSlot,
  loadServiceTypes,
  selectServiceType,
  selectMaster,
  resetToStep1,
  goBackToStep1,
  goBackToMasters,
  selectConcreteService,
  fetchSlots,
  selectSlot,
  onDateSelected,
  onSlotSelected,
  submitBooking,
} = useClientBookingWizard()
const selectedMasterForBooking = ref(null)
// Для клиента, авторизованного в системе, backend возьмет email/имя из профиля,
// поэтому дополнительных полей на фронте не требуется

onMounted(async () => {
  await loadServiceTypes()
  // Загружаем пользователя и восстанавливаем сессию, чтобы не выкидывало на главную после refresh
  if (authStore.token && !authStore.user) {
    await authStore.getCurrentUser().catch(() => {})
  }
  await loadCurrentBookings() // Это теперь загружает и активные записи, и историю
  await loadMyMasters()
})

// loadServiceTypes provided by useClientBookingWizard

// loadMyMasters now provided by useClientMasters composable

const loadCurrentBookings = async () => {
  try {
    if (!authStore.token) { return }
    const data = await api.getBookings(authStore.token)

    // Разделяем записи на активные и историю
    const activeBookings = data.filter(
      (booking) => booking.status === 'pending' || booking.status === 'confirmed',
    )
    const historyBookings = data.filter(
      (booking) => booking.status === 'cancelled' || booking.status === 'completed',
    )

    currentBookings.value = activeBookings
    bookingHistory.value = historyBookings

    
  } catch (e) {
    console.error('Failed to load client bookings:', e)
    currentBookings.value = []
    bookingHistory.value = []
  }
}

const loadBookingHistory = async () => {
  // История загружается вместе с активными записями в loadCurrentBookings
  
}

// provided by useClientBookingWizard

const minPrice = (services) => Math.min(...services.map((s) => s.price))

// provided by useClientBookingWizard

// provided by useClientBookingWizard

// provided by useClientBookingWizard

// provided by useClientBookingWizard

// provided by useClientBookingWizard

watch(selectedDate, fetchSlots)

// provided by useClientBookingWizard

// provided by useClientBookingWizard

// provided by useClientBookingWizard

// provided by useClientBookingWizard

const selectMasterForBooking = (master) => {
  
  selectedMasterForBooking.value = master
}

const cancelMasterSelection = () => {
  selectedMasterForBooking.value = null
}

// provided by useClientBookingWizard

const selectServiceAndGoToTime = (master, service) => {
  

  // Выбираем мастера и услугу, сразу переходим к выбору времени
  selectedServiceType.value = null

  // Устанавливаем только выбранного мастера с его услугами
  selectedMaster.value = {
    id: master.id,
    user: master,
    services: master.services,
  }

  // Устанавливаем только услуги выбранного мастера
  selectedMasterServices.value = master.services

  selectedService.value = service
  selectedSlot.value = null
  selectedMasterForBooking.value = null // Скрываем услуги в карточке

  

  // Устанавливаем дату для календаря (сегодня или ближайший рабочий день)
  const today = new Date()
  selectedCalendarDate.value = {
    date: today,
    key: today.toISOString().split('T')[0],
    isCurrentMonth: true,
    isToday: true,
    isPast: false,
  }

  

  currentStep.value = 4 // Переходим сразу к выбору времени

  // Скрываем секцию "Мои мастера" после выбора услуги
  
}

const deleteBooking = async (bookingId) => {
  try {
    if (!confirm('Вы уверены, что хотите удалить эту запись из истории?')) return
    if (!authStore.token) throw new Error('Не авторизован')

    // Оптимистично убираем запись из UI
    const prevCurrent = [...currentBookings.value]
    const prevHistory = [...bookingHistory.value]
    currentBookings.value = prevCurrent.filter((b) => b.id !== bookingId)
    bookingHistory.value = prevHistory.filter((b) => b.id !== bookingId)

    // Серверный вызов
    await api.deleteBooking(bookingId, authStore.token)

    // Фоновая синхронизация (не блокируем UI)
    Promise.all([loadCurrentBookings(), loadMyMasters()]).catch(() => {})
  } catch (e) {
    console.error('Failed to delete booking:', e)
    alert('Не удалось удалить запись: ' + e.message)
    // Явного отката не делаем, так как повторная загрузка пересоберет списки
    await loadCurrentBookings().catch(() => {})
  }
}

const clearHistory = async () => {
  try {
    if (!confirm('Вы уверены, что хотите очистить всю историю записей?')) return
    if (!authStore.token) throw new Error('Не авторизован')
    await Promise.all(bookingHistory.value.map((b) => api.deleteBooking(b.id, authStore.token)))
    alert('История очищена')
    await loadCurrentBookings()
    await loadMyMasters()
  } catch (e) {
    console.error('Failed to clear history:', e)
    alert('Не удалось очистить историю: ' + e.message)
  }
}

const handleScrollToSection = (sectionId) => {
  const element = document.getElementById(sectionId)
  if (element) {
    // Добавляем отступ сверху, чтобы заголовок был виден
    const headerHeight = 80 // Высота хедера
    const offset = 20 // Дополнительный отступ
    const elementPosition = element.offsetTop - headerHeight - offset

    window.scrollTo({
      top: elementPosition,
      behavior: 'smooth',
    })
  }
}

const formatDate = (dateString) => new Date(dateString).toLocaleDateString('ru-RU')
const formatTime = (dateString) =>
  new Date(dateString).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })

// Removed local booking/date/status helpers in favor of useFormatters()
</script>
