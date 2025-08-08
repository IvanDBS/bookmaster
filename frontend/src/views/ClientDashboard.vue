<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <AppHeader :show-navigation="true" user-type="client" :pending-bookings-count="0" @scroll-to-section="handleScrollToSection" />

    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-6 py-8 mt-20">
      <!-- Welcome Section -->
      <div class="mb-8">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">
          Добро пожаловать, {{ user?.first_name }}!
        </h2>
        <p class="text-gray-600">Управляйте своими записями и находите новых мастеров</p>
      </div>

      <!-- My Masters Section -->
      <div id="masters" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Мои мастера</h3>
        </div>
        <div class="p-6">
          <div v-if="myMasters.length === 0" class="text-center py-8">
            <p class="text-gray-500">У вас пока нет избранных мастеров</p>
          </div>
          <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div v-for="master in myMasters" :key="master.id" class="bg-gray-50 rounded-lg p-4">
              <div class="flex items-center space-x-4 mb-3">
                <div class="w-12 h-12 bg-lime-100 rounded-full flex items-center justify-center">
                  <span class="text-lime-600 font-semibold text-lg">{{ master.first_name[0] }}{{ master.last_name[0] }}</span>
                </div>
                <div>
                  <h4 class="font-semibold text-gray-900">{{ master.first_name }} {{ master.last_name }}</h4>
                  <p class="text-sm text-gray-600">{{ master.services?.length || 0 }} услуг</p>
                </div>
              </div>
              <div class="space-y-1 mb-3">
                <div v-for="service in master.services?.slice(0, 2)" :key="service.id" class="flex justify-between items-center text-sm">
                  <span class="text-gray-700">{{ service.name }}</span>
                  <span class="font-semibold text-gray-900">₽{{ service.price }}</span>
                </div>
              </div>
              <button @click="bookService(master)" class="w-full bg-lime-500 hover:bg-lime-600 text-white font-semibold px-4 py-2 rounded-lg transition-colors text-sm">
                Записаться
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Booking Wizard (минималистичный) -->
      <div id="search" class="bg-white rounded-xl shadow-sm border border-gray-200 mb-8">
        <div class="px-6 py-5 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Запись на услугу</h3>
        </div>
        <div class="p-6 space-y-8">
          <!-- Stepper -->
          <div class="flex items-center space-x-6">
            <div class="flex items-center space-x-2" :class="currentStep >= 1 ? 'text-lime-600' : 'text-gray-400'">
              <div class="w-6 h-6 rounded-full flex items-center justify-center border" :class="currentStep>=1?'border-lime-500':'border-gray-300'">1</div>
              <span class="text-sm">Выбор услуги</span>
            </div>
            <div class="h-px flex-1 bg-gray-200"></div>
            <div class="flex items-center space-x-2" :class="currentStep >= 2 ? 'text-lime-600' : 'text-gray-400'">
              <div class="w-6 h-6 rounded-full flex items-center justify-center border" :class="currentStep>=2?'border-lime-500':'border-gray-300'">2</div>
              <span class="text-sm">Мастер</span>
            </div>
            <div class="h-px flex-1 bg-gray-200"></div>
            <div class="flex items-center space-x-2" :class="currentStep >= 3 ? 'text-lime-600' : 'text-gray-400'">
              <div class="w-6 h-6 rounded-full flex items-center justify-center border" :class="currentStep>=3?'border-lime-500':'border-gray-300'">3</div>
              <span class="text-sm">Время</span>
            </div>
            <div class="h-px flex-1 bg-gray-200"></div>
            <div class="flex items-center space-x-2" :class="currentStep >= 4 ? 'text-lime-600' : 'text-gray-400'">
              <div class="w-6 h-6 rounded-full flex items-center justify-center border" :class="currentStep>=4?'border-lime-500':'border-gray-300'">4</div>
              <span class="text-sm">Подтверждение</span>
            </div>
          </div>

          <!-- Step 1: choose service type -->
          <div v-if="currentStep === 1" class="space-y-5">
            <h4 class="text-sm font-semibold text-gray-900">Выберите тип услуги</h4>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
              <button v-for="type in serviceTypes" :key="type" @click="selectServiceType(type)"
                      :class="['flex flex-col items-center justify-center rounded-xl border p-5 text-center transition', selectedServiceType===type? 'border-lime-500 bg-lime-50' : 'border-gray-200 hover:border-gray-300']">
                <span class="text-2xl mb-1" v-if="type==='маникюр'">💅</span>
                <span class="text-2xl mb-1" v-else-if="type==='педикюр'">🦶</span>
                <span class="text-2xl mb-1" v-else>💆‍♀️</span>
                <span class="font-semibold text-gray-900">{{ type.charAt(0).toUpperCase() + type.slice(1) }}</span>
                <span class="text-xs text-gray-500 mt-1">Выбор категории</span>
              </button>
            </div>
          </div>

          <!-- Step 2: choose master -->
          <div v-if="currentStep === 2" class="space-y-5">
            <h4 class="text-sm font-semibold text-gray-900">Выберите мастера</h4>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
              <button v-for="master in mastersForType" :key="master.id" @click="selectMaster(master)"
                      :class="['rounded-xl border p-4 text-left transition', selectedMaster?.id===master.id? 'border-lime-500 bg-lime-50' : 'border-gray-200 hover:border-gray-300']">
                <div class="flex items-center space-x-3">
                  <div class="w-10 h-10 rounded-full bg-lime-100 flex items-center justify-center text-lime-600 font-semibold">
                    {{ master.user.first_name[0] }}
                  </div>
                  <div class="flex-1">
                    <div class="font-semibold text-gray-900">{{ master.user.first_name }} {{ master.user.last_name }}</div>
                    <div class="text-xs text-gray-500">{{ master.services.length }} услуг</div>
                  </div>
                  <div class="text-right">
                    <div class="text-sm font-semibold text-gray-900">от ₽{{ minPrice(master.services) }}</div>
                  </div>
                </div>
              </button>
            </div>
            <div class="flex justify-between">
              <button class="text-sm text-gray-600" @click="currentStep=1">← Назад</button>
            </div>
          </div>

          <!-- Step 3: choose concrete service -->
          <div v-if="currentStep === 3" class="space-y-5">
            <h4 class="text-sm font-semibold text-gray-900">Выберите услугу у {{ selectedMaster?.user.first_name }}</h4>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <button v-for="srv in selectedMasterServices" :key="srv.id" @click="selectConcreteService(srv)"
                      :class="['rounded-xl border p-4 text-left transition', selectedService?.id===srv.id? 'border-lime-500 bg-lime-50' : 'border-gray-200 hover:border-gray-300']">
                <div class="font-semibold text-gray-900">{{ srv.name }}</div>
                <div class="text-xs text-gray-500">{{ srv.duration }} мин</div>
                <div class="mt-1 font-semibold text-gray-900">₽{{ srv.price }}</div>
              </button>
            </div>
            <div class="flex justify-between">
              <button class="text-sm text-gray-600" @click="currentStep=2">← Назад</button>
            </div>
          </div>

          <!-- Step 4: choose time slot -->
          <div v-if="currentStep === 4" class="space-y-5">
            <h4 class="text-sm font-semibold text-gray-900">Выберите время</h4>
            <div class="flex items-center space-x-3">
              <input type="date" v-model="selectedDate" class="px-3 py-2 border rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500 text-sm"/>
              <button class="text-sm text-gray-600" @click="currentStep=3">← Назад</button>
            </div>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-2">
              <button v-for="slot in daySlots" :key="slot.id" @click="selectSlot(slot)"
                      :disabled="!(slot.is_available && !slot.booked && slot.slot_type==='work')"
                      :class="['rounded-lg border px-3 py-2 text-sm transition',
                               selectedSlot?.id===slot.id ? 'border-lime-500 bg-lime-50' : 'border-gray-200 hover:border-gray-300',
                               !(slot.is_available && !slot.booked && slot.slot_type==='work') ? 'opacity-40 cursor-not-allowed' : '']">
                {{ slot.start_time }} - {{ slot.end_time }}
              </button>
            </div>
          </div>

          <!-- Step 5: confirm -->
          <div v-if="currentStep === 5" class="space-y-5">
            <h4 class="text-sm font-semibold text-gray-900">Подтверждение</h4>
            <div class="rounded-xl border border-gray-200 p-4">
              <div class="text-sm text-gray-700">Услуга</div>
              <div class="font-semibold text-gray-900">{{ selectedService.name }} — ₽{{ selectedService.price }} ({{ selectedService.duration }} мин)</div>
              <div class="mt-2 text-sm text-gray-700">Мастер</div>
              <div class="font-semibold text-gray-900">{{ selectedMaster.user.first_name }} {{ selectedMaster.user.last_name }}</div>
              <div class="mt-2 text-sm text-gray-700">Время</div>
              <div class="font-semibold text-gray-900">{{ selectedDate }} • {{ selectedSlot.start_time }}–{{ selectedSlot.end_time }}</div>
            </div>
            <div class="flex items-center justify-between">
              <button class="text-sm text-gray-600" @click="currentStep=4">← Назад</button>
              <button @click="submitBooking" class="bg-lime-500 hover:bg-lime-600 text-white font-semibold px-6 py-2 rounded-lg transition-colors text-sm">Подтвердить запись</button>
            </div>
          </div>
        </div>
      </div>

      <!-- My Current Bookings -->
      <div id="bookings" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Мои записи</h3>
        </div>
        <div class="p-6">
          <div v-if="currentBookings.length === 0" class="text-center py-8">
            <p class="text-gray-500">У вас пока нет активных записей</p>
          </div>
          <div v-else class="space-y-4">
            <div v-for="booking in currentBookings" :key="booking.id" class="flex justify-between items-center p-4 bg-gray-50 rounded-lg">
              <div class="flex-1">
                <div class="flex items-center space-x-4">
                  <div class="w-10 h-10 bg-lime-100 rounded-full flex items-center justify-center">
                    <span class="text-lime-600 font-semibold text-sm">{{ booking.master?.first_name[0] }}{{ booking.master?.last_name[0] }}</span>
                  </div>
                  <div>
                    <h4 class="font-semibold text-gray-900">{{ booking.service?.name }}</h4>
                    <p class="text-sm text-gray-600">{{ booking.master?.first_name }} {{ booking.master?.last_name }}</p>
                    <p class="text-sm text-gray-600">{{ formatDate(booking.start_time) }} в {{ formatTime(booking.start_time) }}</p>
                  </div>
                </div>
              </div>
              <div class="text-right">
                <span :class="getStatusClass(booking.status)" class="px-3 py-1 rounded-full text-xs font-semibold">
                  {{ getStatusText(booking.status) }}
                </span>
                <p class="text-sm font-semibold text-gray-900 mt-1">₽{{ booking.service?.price }}</p>
                <button @click="cancelBooking(booking.id)" class="mt-2 text-red-600 hover:text-red-700 text-sm font-medium">
                  Отменить запись
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Booking History -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200">
        <div class="px-6 py-4 border-b border-gray-200">
          <div class="flex justify-between items-center">
            <h3 class="text-lg font-semibold text-gray-900">История записей</h3>
            <button @click="clearHistory" class="text-red-600 hover:text-red-700 text-sm font-medium">
              Очистить историю
            </button>
          </div>
        </div>
        <div class="p-6">
          <div v-if="bookingHistory.length === 0" class="text-center py-8">
            <p class="text-gray-500">История записей пуста</p>
          </div>
          <div v-else class="space-y-4">
            <div v-for="booking in bookingHistory" :key="booking.id" class="flex justify-between items-center p-4 bg-gray-50 rounded-lg">
              <div class="flex-1">
                <div class="flex items-center space-x-4">
                  <div class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                    <span class="text-gray-600 font-semibold text-sm">{{ booking.master?.first_name[0] }}{{ booking.master?.last_name[0] }}</span>
                  </div>
                  <div>
                    <h4 class="font-semibold text-gray-900">{{ booking.service?.name }}</h4>
                    <p class="text-sm text-gray-600">{{ booking.master?.first_name }} {{ booking.master?.last_name }}</p>
                    <p class="text-sm text-gray-600">{{ formatDate(booking.start_time) }} в {{ formatTime(booking.start_time) }}</p>
                  </div>
                </div>
              </div>
              <div class="text-right">
                <span :class="getStatusClass(booking.status)" class="px-3 py-1 rounded-full text-xs font-semibold">
                  {{ getStatusText(booking.status) }}
                </span>
                <p class="text-sm font-semibold text-gray-900 mt-1">₽{{ booking.service?.price }}</p>
                <button @click="deleteBooking(booking.id)" class="mt-2 text-red-600 hover:text-red-700 text-sm font-medium">
                  Удалить
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
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
              Удобная платформа для записи к мастерам. Найдите своего мастера и запишитесь на услугу в несколько кликов.
            </p>
            <div class="flex space-x-4">
              <a href="#" class="text-gray-400 hover:text-white transition-colors">
                <span class="sr-only">Telegram</span>
                <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.894 8.221l-1.97 9.28c-.145.658-.537.818-1.084.508l-3-2.21-1.446 1.394c-.14.18-.357.295-.6.295-.002 0-.003 0-.005 0l.213-3.054 5.56-5.022c.24-.213-.054-.334-.373-.121l-6.869 4.326-2.96-.924c-.64-.203-.658-.64.135-.954l11.566-4.458c.538-.196 1.006.128.832.941z"/>
                </svg>
              </a>
              <a href="#" class="text-gray-400 hover:text-white transition-colors">
                <span class="sr-only">WhatsApp</span>
                <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.885 3.488"/>
                </svg>
              </a>
            </div>
          </div>

          <!-- Quick Links -->
          <div>
            <h4 class="text-lg font-semibold mb-4">Быстрые ссылки</h4>
            <ul class="space-y-2">
              <li><a href="#" class="text-gray-400 hover:text-white transition-colors">О нас</a></li>
              <li><a href="#" class="text-gray-400 hover:text-white transition-colors">Как это работает</a></li>
              <li><a href="#" class="text-gray-400 hover:text-white transition-colors">Стать мастером</a></li>
              <li><a href="#" class="text-gray-400 hover:text-white transition-colors">Поддержка</a></li>
            </ul>
          </div>

          <!-- Contact -->
          <div>
            <h4 class="text-lg font-semibold mb-4">Контакты</h4>
            <ul class="space-y-2">
              <li class="text-gray-400">+7 999 123-45-67</li>
              <li class="text-gray-400">support@bookmaster.ru</li>
              <li class="text-gray-400">Москва, Россия</li>
            </ul>
          </div>
        </div>

        <div class="border-t border-gray-800 mt-8 pt-8">
          <div class="flex flex-col md:flex-row justify-between items-center">
            <p class="text-gray-400 text-sm">
              © 2024 BookMaster. Все права защищены.
            </p>
            <div class="flex space-x-6 mt-4 md:mt-0">
              <a href="#" class="text-gray-400 hover:text-white text-sm transition-colors">Политика конфиденциальности</a>
              <a href="#" class="text-gray-400 hover:text-white text-sm transition-colors">Условия использования</a>
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
import AppHeader from '../components/AppHeader.vue'
import api from '../services/api'

const authStore = useAuthStore()

const user = computed(() => authStore.user)
const myMasters = ref([])
const currentBookings = ref([])
const bookingHistory = ref([])

// Booking wizard state
const currentStep = ref(1)
const serviceTypes = ref(['маникюр', 'педикюр', 'массаж'])
const selectedServiceType = ref(null)
const mastersForType = ref([])
const selectedMaster = ref(null)
const selectedMasterServices = ref([])
const selectedService = ref(null)
const selectedDate = ref(new Date().toISOString().slice(0,10))
const daySlots = ref([])
const selectedSlot = ref(null)
// Для клиента, авторизованного в системе, backend возьмет email/имя из профиля,
// поэтому дополнительных полей на фронте не требуется

onMounted(async () => {
  await loadServiceTypes()
  // Загружаем пользователя и восстанавливаем сессию, чтобы не выкидывало на главную после refresh
  if (authStore.token && !authStore.user) {
    await authStore.getCurrentUser().catch(()=>{})
  }
  await loadCurrentBookings()
})

const loadServiceTypes = async () => {
  try {
    const data = await api.getServiceTypes()
    serviceTypes.value = data.service_types || serviceTypes.value
  } catch (_) {}
}

const loadMyMasters = async () => {
  myMasters.value = []
}

const loadCurrentBookings = async () => {
  try {
    if (!authStore.token) return
    const res = await fetch('http://localhost:3000/api/v1/bookings', {
      headers: { 'Authorization': `Bearer ${authStore.token}` }
    })
    if (!res.ok) throw new Error('Failed to load bookings')
    const data = await res.json()
    // Новые записи первыми: сортируем по created_at desc, если нет — по start_time desc
    currentBookings.value = [...data].sort((a,b) => {
      const aCreated = a.created_at ? new Date(a.created_at).getTime() : 0
      const bCreated = b.created_at ? new Date(b.created_at).getTime() : 0
      if (aCreated !== 0 || bCreated !== 0) return bCreated - aCreated
      return new Date(b.start_time).getTime() - new Date(a.start_time).getTime()
    })
  } catch (e) {
    console.error('Failed to load client bookings:', e)
    currentBookings.value = []
  }
}

const loadBookingHistory = async () => {
  bookingHistory.value = []
}

const selectServiceType = async (type) => {
  selectedServiceType.value = type
  const services = await api.getServicesByType(type)
  const byMasterId = new Map()
  services.forEach(s => {
    if (!byMasterId.has(s.user.id)) {
      byMasterId.set(s.user.id, { id: s.user.id, user: s.user, services: [] })
    }
    byMasterId.get(s.user.id).services.push(s)
  })
  mastersForType.value = Array.from(byMasterId.values())
  selectedMaster.value = null
  selectedMasterServices.value = []
  selectedService.value = null
  currentStep.value = 2
}

const minPrice = (services) => Math.min(...services.map(s => s.price))

const selectMaster = (master) => {
  selectedMaster.value = master
  selectedMasterServices.value = master.services
  selectedService.value = null
  currentStep.value = 3
}

const selectConcreteService = (srv) => {
  selectedService.value = srv
  selectedSlot.value = null
  daySlots.value = []
  fetchSlots()
  currentStep.value = 4
}

const fetchSlots = async () => {
  if (!selectedMaster.value) return
  const res = await api.getPublicSlots(selectedMaster.value.id, selectedDate.value)
  daySlots.value = res.slots || []
}

watch(selectedDate, fetchSlots)

const selectSlot = (slot) => {
  selectedSlot.value = slot
  currentStep.value = 5
}

const submitBooking = async () => {
  try {
    const payload = {
      master_id: selectedMaster.value.id,
      time_slot_id: selectedSlot.value.id,
      booking: {
        service_id: selectedService.value.id
        // имя/email/телефон возьмем из профиля пользователя на бэкенде
      }
    }
    await api.createBooking(payload, authStore.token)
    alert('Запись создана!')
    currentStep.value = 1
    selectedServiceType.value = null
    selectedMaster.value = null
    selectedService.value = null
    selectedSlot.value = null
  } catch (e) {
    alert('Не удалось создать запись: ' + e.message)
  }
}

const bookService = (master) => {}
const cancelBooking = (bookingId) => {}
const deleteBooking = (bookingId) => {}
const clearHistory = () => {}

const handleScrollToSection = (sectionId) => {
  const element = document.getElementById(sectionId)
  if (element) {
    element.scrollIntoView({ behavior: 'smooth' })
  }
}

const formatDate = (dateString) => new Date(dateString).toLocaleDateString('ru-RU')
const formatTime = (dateString) => new Date(dateString).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })

const getStatusClass = (status) => {
  const classes = {
    pending: 'bg-yellow-100 text-yellow-800',
    confirmed: 'bg-green-100 text-green-800',
    cancelled: 'bg-red-100 text-red-800'
  }
  return classes[status] || 'bg-gray-100 text-gray-800'
}

const getStatusText = (status) => {
  const texts = { pending: 'Ожидает подтверждения', confirmed: 'Подтверждено', cancelled: 'Отменено' }
  return texts[status] || status
}
</script>