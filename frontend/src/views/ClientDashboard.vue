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

      <!-- Search Masters Section -->
      <div id="search" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Поиск мастеров</h3>
        </div>
        <div class="p-6">
          <div class="flex items-end space-x-4">
            <div class="flex-1">
              <label class="block text-sm font-medium text-gray-700 mb-2">Услуга</label>
              <select v-model="search.service" @change="filterMastersByService" class="w-full px-3 py-2 pr-8 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500 appearance-none bg-white bg-no-repeat bg-right-2 bg-center" style="background-image: url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTIiIGhlaWdodD0iOCIgdmlld0JveD0iMCAwIDEyIDgiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxwYXRoIGQ9Ik0xLjQxIDAuNTlMNiA1LjE3TDEwLjU5IDAuNTlMMTIgMkw2IDhMMCAyWiIgZmlsbD0iIzY2NiIvPgo8L3N2Zz4K')">
                <option value="">Все услуги</option>
                <option value="manicure">Маникюр</option>
                <option value="pedicure">Педикюр</option>
                <option value="massage">Массаж</option>
              </select>
            </div>
            <div class="flex-1">
              <label class="block text-sm font-medium text-gray-700 mb-2">Мастер</label>
              <select v-model="search.master" class="w-full px-3 py-2 pr-8 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500 appearance-none bg-white bg-no-repeat bg-right-2 bg-center" style="background-image: url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTIiIGhlaWdodD0iOCIgdmlld0JveD0iMCAwIDEyIDgiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxwYXRoIGQ9Ik0xLjQxIDAuNTlMNiA1LjE3TDEwLjU5IDAuNTlMMTIgMkw2IDhMMCAyWiIgZmlsbD0iIzY2NiIvPgo8L3N2Zz4K')">
                <option value="">Все мастера</option>
                <option v-for="master in filteredMasters" :key="master.id" :value="master.id">
                  {{ master.first_name }} {{ master.last_name }}
                </option>
              </select>
            </div>
            <div class="flex-shrink-0">
              <button @click="searchMasters" class="bg-lime-500 hover:bg-lime-600 text-white font-semibold px-6 py-2 rounded-lg transition-colors">
                Записаться
              </button>
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
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from '../stores/auth'
import AppHeader from '../components/AppHeader.vue'

const authStore = useAuthStore()

const user = computed(() => authStore.user)
const myMasters = ref([])
const availableMasters = ref([])
const filteredMasters = ref([])
const currentBookings = ref([])
const bookingHistory = ref([])
const search = ref({
  service: '',
  master: ''
})

onMounted(async () => {
  await loadData()
})

const loadData = async () => {
  await loadMyMasters()
  await loadAvailableMasters()
  await loadCurrentBookings()
  await loadBookingHistory()
  // Инициализируем отфильтрованных мастеров
  filteredMasters.value = availableMasters.value
}

const loadMyMasters = async () => {
  try {
    // Здесь будет загрузка избранных мастеров с API
    // Пока возвращаем пустой список - будет реализовано позже
    myMasters.value = []
  } catch (error) {
    console.error('Error loading my masters:', error)
    myMasters.value = []
  }
}

const loadAvailableMasters = async () => {
  try {
    // Здесь будет загрузка всех доступных мастеров с API
    // Пока возвращаем пустой список - будет реализовано позже
    availableMasters.value = []
    filteredMasters.value = []
  } catch (error) {
    console.error('Error loading available masters:', error)
    availableMasters.value = []
    filteredMasters.value = []
  }
}

const filterMastersByService = () => {
  if (!search.value.service) {
    filteredMasters.value = availableMasters.value
  } else {
    filteredMasters.value = availableMasters.value.filter(master => 
      master.services.includes(search.value.service)
    )
  }
  // Сбрасываем выбранного мастера при смене услуги
  search.value.master = ''
}

const loadCurrentBookings = async () => {
  try {
    // Здесь будет загрузка текущих записей с API
    // Пока возвращаем пустой список - будет реализовано позже
    currentBookings.value = []
  } catch (error) {
    console.error('Error loading current bookings:', error)
    currentBookings.value = []
  }
}

const loadBookingHistory = async () => {
  try {
    // Здесь будет загрузка истории записей с API
    // Пока возвращаем пустой список - будет реализовано позже
    bookingHistory.value = []
  } catch (error) {
    console.error('Error loading booking history:', error)
    bookingHistory.value = []
  }
}

const searchMasters = () => {
  console.log('Searching masters:', search.value)
  // Здесь будет логика поиска и записи
}

const bookService = (master) => {
  console.log('Booking service for master:', master)
  // Здесь будет логика записи
}

const cancelBooking = (bookingId) => {
  console.log('Cancelling booking:', bookingId)
  // Здесь будет логика отмены записи
}

const deleteBooking = (bookingId) => {
  console.log('Deleting booking:', bookingId)
  // Здесь будет логика удаления записи из истории
}

const clearHistory = () => {
  console.log('Clearing booking history')
  // Здесь будет логика очистки истории
}

const handleScrollToSection = (sectionId) => {
  const element = document.getElementById(sectionId);
  if (element) {
    element.scrollIntoView({ behavior: 'smooth' });
  }
};


const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('ru-RU')
}

const formatTime = (dateString) => {
  return new Date(dateString).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })
}

const getStatusClass = (status) => {
  const classes = {
    'pending': 'bg-yellow-100 text-yellow-800',
    'confirmed': 'bg-green-100 text-green-800',
    'cancelled': 'bg-red-100 text-red-800'
  }
  return classes[status] || 'bg-gray-100 text-gray-800'
}

const getStatusText = (status) => {
  const texts = {
    'pending': 'Ожидает подтверждения',
    'confirmed': 'Подтверждено',
    'cancelled': 'Отменено'
  }
  return texts[status] || status
}
</script> 