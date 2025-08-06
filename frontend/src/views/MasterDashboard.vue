<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <AppHeader :show-navigation="true" user-type="master" :pending-bookings-count="pendingBookingsCount" @scroll-to-section="handleScrollToSection" @notification-click="handleNotificationClick" />
    
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
      <div class="mb-8">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">
          Добро пожаловать, {{ user?.first_name }}!
        </h2>
        <p class="text-gray-600">Управляйте своими услугами и записями</p>
      </div>

      <!-- Calendar Section -->
      <div id="calendar" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
        <div class="px-6 py-4 border-b border-gray-200">
          <div class="flex justify-between items-center">
            <h3 class="text-lg font-semibold text-gray-900">Календарь записей</h3>
            <button 
              @click="goToScheduleSettings"
              class="bg-blue-600 hover:bg-blue-700 text-white font-medium px-4 py-2 rounded-lg transition-colors text-sm"
            >
              ⚙️ Настройки расписания
            </button>
          </div>
        </div>
        <div class="p-6">
          <!-- Two Months Calendar -->
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <!-- Current Month -->
            <div>
              <div class="flex items-center justify-between mb-4">
                <button @click="previousMonth" class="p-2 hover:bg-gray-100 rounded">
                  <svg class="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                  </svg>
                </button>
                <h4 class="text-lg font-semibold text-gray-900">{{ currentMonthYear }}</h4>
                <div></div>
              </div>

              <!-- Calendar Grid -->
              <div class="grid grid-cols-7 gap-1 mb-4">
                <div v-for="day in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']" :key="day" 
                     class="text-center text-sm font-medium text-gray-500 py-2">
                  {{ day }}
                </div>
              </div>

              <div class="grid grid-cols-7 gap-1">
                <div v-for="date in calendarDates" :key="date.key" 
                     @click="selectDate(date)"
                     class="relative"
                     :class="[
                       'h-12 flex flex-col items-center justify-center text-sm cursor-pointer rounded-lg transition-all duration-200 border',
                       date.isCurrentMonth ? 'hover:shadow-md' : 'text-gray-400',
                       date.isSelected ? 'bg-blue-500 text-white border-blue-600 shadow-lg' : '',
                       date.isToday && !date.isSelected ? 'bg-blue-50 border-blue-200 font-semibold' : '',
                       date.isPast ? 'text-gray-400 cursor-not-allowed' : '',
                       !date.isSelected && !date.isToday && getDateBgClass(date),
                       !date.isSelected && !date.isToday && getDateBorderClass(date)
                     ]">
                  <span class="text-xs font-medium">{{ date.day }}</span>
                  <!-- Индикатор загруженности на основе слотов -->
                  <div v-if="date.totalSlots > 0 && !date.isSelected" class="flex items-center space-x-0.5 mt-0.5">
                    <div v-for="n in Math.min(date.bookedSlots, 4)" :key="n" 
                         :class="[
                           'w-1 h-1 rounded-full',
                           getBookingDotClass(date)
                         ]">
                    </div>
                    <span v-if="date.bookedSlots > 4" class="text-xs font-bold">+</span>
                  </div>
                  <!-- Индикатор нерабочего дня -->
                  <div v-else-if="date.loadLevel === 'non_working' && !date.isSelected" class="mt-0.5">
                    <span class="text-xs text-gray-400">⚫</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Next Month -->
            <div>
              <div class="flex items-center justify-between mb-4">
                <div></div>
                <h4 class="text-lg font-semibold text-gray-900">{{ nextMonthYear }}</h4>
                <button @click="nextMonth" class="p-2 hover:bg-gray-100 rounded">
                  <svg class="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                  </svg>
                </button>
              </div>

              <!-- Calendar Grid -->
              <div class="grid grid-cols-7 gap-1 mb-4">
                <div v-for="day in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']" :key="day" 
                     class="text-center text-sm font-medium text-gray-500 py-2">
                  {{ day }}
                </div>
              </div>

              <div class="grid grid-cols-7 gap-1">
                <div v-for="date in nextMonthDates" :key="date.key" 
                     @click="selectDate(date)"
                     class="relative"
                     :class="[
                       'h-12 flex flex-col items-center justify-center text-sm cursor-pointer rounded-lg transition-all duration-200 border',
                       date.isCurrentMonth ? 'hover:shadow-md' : 'text-gray-400',
                       date.isSelected ? 'bg-blue-500 text-white border-blue-600 shadow-lg' : '',
                       date.isToday && !date.isSelected ? 'bg-blue-50 border-blue-200 font-semibold' : '',
                       date.isPast ? 'text-gray-400 cursor-not-allowed' : '',
                       !date.isSelected && !date.isToday && getDateBgClass(date),
                       !date.isSelected && !date.isToday && getDateBorderClass(date)
                     ]">
                  <span class="text-xs font-medium">{{ date.day }}</span>
                  <!-- Индикатор загруженности на основе слотов -->
                  <div v-if="date.totalSlots > 0 && !date.isSelected" class="flex items-center space-x-0.5 mt-0.5">
                    <div v-for="n in Math.min(date.bookedSlots, 4)" :key="n" 
                         :class="[
                           'w-1 h-1 rounded-full',
                           getBookingDotClass(date)
                         ]">
                    </div>
                    <span v-if="date.bookedSlots > 4" class="text-xs font-bold">+</span>
                  </div>
                  <!-- Индикатор нерабочего дня -->
                  <div v-else-if="date.loadLevel === 'non_working' && !date.isSelected" class="mt-0.5">
                    <span class="text-xs text-gray-400">⚫</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Calendar Legend -->
          <div class="mt-6 bg-gray-50 rounded-lg p-4">
            <h5 class="font-semibold text-gray-900 mb-3">Обозначения загруженности</h5>
            <div class="grid grid-cols-2 md:grid-cols-6 gap-3 text-sm">
              <div class="flex items-center space-x-2">
                <div class="w-4 h-4 bg-gray-100 border border-gray-300 rounded flex items-center justify-center">
                  <span class="text-xs text-gray-400">⚫</span>
                </div>
                <span class="text-gray-700">Выходной</span>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-4 h-4 bg-green-50 border border-green-200 rounded flex items-center justify-center">
                  <div class="w-1 h-1 bg-gray-400 rounded-full opacity-0"></div>
                </div>
                <span class="text-gray-700">Свободен</span>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-4 h-4 bg-lime-50 border border-lime-200 rounded flex items-center justify-center">
                  <div class="w-1 h-1 bg-lime-400 rounded-full"></div>
                </div>
                <span class="text-gray-700">1 слот</span>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-4 h-4 bg-yellow-50 border border-yellow-200 rounded flex items-center justify-center">
                  <div class="flex space-x-0.5">
                    <div class="w-1 h-1 bg-yellow-400 rounded-full"></div>
                    <div class="w-1 h-1 bg-yellow-400 rounded-full"></div>
                  </div>
                </div>
                <span class="text-gray-700">2-3 слота</span>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-4 h-4 bg-orange-50 border border-orange-200 rounded flex items-center justify-center">
                  <div class="flex space-x-0.5">
                    <div class="w-1 h-1 bg-orange-400 rounded-full"></div>
                    <div class="w-1 h-1 bg-orange-400 rounded-full"></div>
                    <div class="w-1 h-1 bg-orange-400 rounded-full"></div>
                  </div>
                </div>
                <span class="text-gray-700">4-5 слотов</span>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-4 h-4 bg-red-50 border border-red-200 rounded flex items-center justify-center">
                  <div class="flex space-x-0.5">
                    <div class="w-1 h-1 bg-red-400 rounded-full"></div>
                    <div class="w-1 h-1 bg-red-400 rounded-full"></div>
                    <div class="w-1 h-1 bg-red-400 rounded-full"></div>
                    <div class="w-1 h-1 bg-red-400 rounded-full"></div>
                  </div>
                </div>
                <span class="text-gray-700">6+ слотов</span>
              </div>
            </div>
          </div>

          <!-- Selected Date Slots -->
          <div v-if="selectedDateSlots.length > 0" class="mt-6">
            <h5 class="font-semibold text-gray-900 mb-3">
              Временные слоты на {{ formatSelectedDate() }}
            </h5>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
              <div v-for="slot in selectedDateSlots" :key="slot.id" 
                   class="bg-gray-50 rounded-lg p-3 border-l-4"
                   :class="{
                     'border-green-500': slot.is_available && !slot.booked,
                     'border-blue-500': slot.booked,
                     'border-gray-400': slot.slot_type === 'lunch',
                     'border-red-400': slot.slot_type === 'blocked'
                   }">
                <div class="flex justify-between items-start mb-2">
                  <div class="flex-1">
                    <h6 class="font-semibold text-gray-900 text-sm">
                      {{ slot.start_time }} - {{ slot.end_time }}
                    </h6>
                    <p class="text-xs text-gray-600">
                      {{ getSlotTypeText(slot.slot_type) }}
                    </p>
                  </div>
                  <span :class="getSlotStatusClass(slot)" class="px-2 py-1 rounded-full text-xs font-semibold ml-2">
                    {{ getSlotStatusText(slot) }}
                  </span>
                </div>
                <div v-if="slot.booking" class="mt-2 p-2 bg-blue-50 rounded">
                  <p class="text-xs text-gray-700">
                    <strong>Клиент:</strong> {{ slot.booking.client_name }}
                  </p>
                  <p class="text-xs text-gray-700">
                    <strong>Услуга:</strong> {{ slot.booking.service_name }}
                  </p>
                  <p class="text-xs text-gray-700">
                    <strong>Статус:</strong> {{ getStatusText(slot.booking.status) }}
                  </p>
                </div>
              </div>
            </div>
          </div>

          <!-- Selected Date Bookings -->
          <div v-if="selectedDateBookings.length > 0" class="mt-6">
            <h5 class="font-semibold text-gray-900 mb-3">
              Записи на {{ formatSelectedDate() }}
            </h5>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div v-for="booking in sortedSelectedDateBookings" :key="booking.id" 
                   class="bg-gray-50 rounded-lg p-3 border-l-4"
                   :class="{
                     'border-green-500': booking.status === 'confirmed',
                     'border-yellow-500': booking.status === 'pending',
                     'border-red-500': booking.status === 'cancelled'
                   }">
                <div class="flex justify-between items-start mb-2">
                  <div class="flex-1">
                    <h6 class="font-semibold text-gray-900 text-sm">{{ booking.service?.name }}</h6>
                    <p class="text-xs text-gray-600">{{ booking.client_name }}</p>
                  </div>
                  <span :class="getStatusClass(booking.status)" class="px-2 py-1 rounded-full text-xs font-semibold ml-2">
                    {{ getStatusText(booking.status) }}
                  </span>
                </div>
                <div class="flex justify-between items-center">
                  <div class="text-xs text-gray-600">
                    {{ formatTime(booking.start_time) }} - {{ formatTime(booking.end_time) }}
                  </div>
                  <div class="text-right">
                    <p class="text-sm font-semibold text-gray-900">₽{{ booking.service?.price }}</p>
                    <div v-if="booking.status === 'pending'" class="flex space-x-1 mt-1">
                      <button @click="showConfirmModal(booking)" class="text-green-600 hover:text-green-700 text-xs font-medium">
                        ✓
                      </button>
                      <button @click="showCancelModal(booking)" class="text-red-600 hover:text-red-700 text-xs font-medium">
                        ✕
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div v-else-if="selectedDate && selectedDateSlots.length === 0" class="mt-6 text-center py-4">
            <p class="text-gray-500">На выбранную дату слотов нет</p>
          </div>
        </div>
      </div>

      <!-- Recent Bookings Section -->
      <div id="bookings" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
        <div class="px-6 py-4 border-b border-gray-200">
          <div class="flex justify-between items-center">
            <h3 class="text-lg font-semibold text-gray-900">Последние записи</h3>
            <!-- Кнопки сортировки -->
            <div class="flex space-x-2">
              <button @click="setBookingFilter('all')" 
                      :class="bookingFilter === 'all' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700'"
                      class="px-3 py-1 text-sm font-medium rounded hover:bg-gray-200 transition-colors">
                Все
              </button>
              <button @click="setBookingFilter('pending')" 
                      :class="bookingFilter === 'pending' ? 'bg-yellow-500 text-white' : 'bg-gray-100 text-gray-700'"
                      class="px-3 py-1 text-sm font-medium rounded hover:bg-gray-200 transition-colors">
                Ожидает подтверждения
              </button>
              <button @click="setBookingFilter('confirmed')" 
                      :class="bookingFilter === 'confirmed' ? 'bg-green-500 text-white' : 'bg-gray-100 text-gray-700'"
                      class="px-3 py-1 text-sm font-medium rounded hover:bg-gray-200 transition-colors">
                Подтверждено
              </button>
              <button @click="setBookingFilter('cancelled')" 
                      :class="bookingFilter === 'cancelled' ? 'bg-red-500 text-white' : 'bg-gray-100 text-gray-700'"
                      class="px-3 py-1 text-sm font-medium rounded hover:bg-gray-200 transition-colors">
                Отменено
              </button>
            </div>
          </div>
        </div>
        <div class="p-6">
          <div v-if="filteredBookings.length === 0" class="text-center py-8">
            <p class="text-gray-500">У вас пока нет записей</p>
          </div>
          <div v-else class="space-y-4">
            <div v-for="booking in filteredBookings" :key="booking.id" 
                 class="flex justify-between items-center p-4 bg-gray-50 rounded-lg">
              <div>
                <p class="font-medium text-gray-900">{{ booking.service?.name }}</p>
                <p class="text-sm text-gray-600">{{ booking.client_name }}</p>
                <p class="text-sm text-gray-600">{{ formatDate(booking.start_time) }} в {{ formatTime(booking.start_time) }}</p>
              </div>
              <div class="text-right">
                <span :class="getStatusClass(booking.status)" class="px-2 py-1 rounded-full text-xs font-semibold">
                  {{ getStatusText(booking.status) }}
                </span>
                <p class="text-sm font-semibold text-gray-900 mt-1">₽{{ booking.service?.price }}</p>
                <div v-if="booking.status === 'pending'" class="flex space-x-2 mt-2">
                  <button @click="showConfirmModal(booking)" class="text-green-600 hover:text-green-700 text-xs font-medium">
                    Подтвердить
                  </button>
                  <button @click="showCancelModal(booking)" class="text-red-600 hover:text-red-700 text-xs font-medium">
                    Отменить
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Services Management -->
      <div id="services" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
        <div class="px-6 py-4 border-b border-gray-200">
          <div class="flex justify-between items-center">
            <h3 class="text-lg font-semibold text-gray-900">Мои услуги</h3>
            <button @click="showModal = true" class="bg-lime-500 hover:bg-lime-600 text-white font-semibold px-4 py-2 rounded-lg transition-colors">
              Добавить услугу
            </button>
          </div>
        </div>
        <div class="p-6">
          <div v-if="services.length === 0" class="text-center py-8">
            <p class="text-gray-500">У вас пока нет услуг</p>
          </div>
          <div v-else class="space-y-4">
            <div v-for="service in services" :key="service.id" class="flex justify-between items-center p-4 bg-gray-50 rounded-lg">
              <div>
                <h4 class="font-semibold text-gray-900">{{ service.name }}</h4>
                <p class="text-sm text-gray-600">{{ service.description }}</p>
                <p class="text-sm text-gray-600">{{ service.duration }} мин</p>
              </div>
              <div class="text-right">
                <p class="text-lg font-semibold text-gray-900">₽{{ service.price }}</p>
                <div class="flex space-x-2 mt-2">
                  <button @click="editService(service)" class="text-blue-600 hover:text-blue-700 text-sm font-medium">
                    Редактировать
                  </button>
                  <button @click="deleteService(service.id)" class="text-red-600 hover:text-red-700 text-sm font-medium">
                    Удалить
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add Service Modal -->
    <div v-if="showModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg p-6 w-full max-w-md">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">{{ editingServiceId ? 'Редактировать услугу' : 'Добавить услугу' }}</h3>
        <form @submit.prevent="addService">
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Название</label>
              <input v-model="newService.name" type="text" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Описание</label>
              <textarea v-model="newService.description" rows="3" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500"></textarea>
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Цена (₽)</label>
                <input v-model="newService.price" type="number" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Длительность (мин)</label>
                <input v-model="newService.duration" type="number" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500" />
              </div>
            </div>
          </div>
          <div class="flex space-x-4 mt-6">
            <button type="submit" class="flex-1 bg-lime-500 hover:bg-lime-600 text-white font-semibold px-4 py-2 rounded-lg transition-colors">
              {{ editingServiceId ? 'Обновить' : 'Добавить' }}
            </button>
            <button type="button" @click="closeModal" class="flex-1 bg-gray-300 hover:bg-gray-400 text-gray-700 font-semibold px-4 py-2 rounded-lg transition-colors">
              Отмена
            </button>
          </div>
        </form>
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
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import AppHeader from '../components/AppHeader.vue'
import ConfirmationModal from '../components/ConfirmationModal.vue'

const authStore = useAuthStore()
const router = useRouter()

// Reactive data
const user = ref(null)
const services = ref([])
const recentBookings = ref([])
const showModal = ref(false)
const editingServiceId = ref(null)
const bookingFilter = ref('all')
const newService = ref({
  name: '',
  description: '',
  price: '',
  duration: ''
})

// Calendar data
const currentDate = ref(new Date())
const selectedDate = ref(null)
const selectedDateBookings = ref([])
const selectedDateSlots = ref([])
const workingSchedules = ref([])
const slotsCache = ref(new Map()) // Кэш слотов по датам

// Modal data
const showConfirmationModal = ref(false)
const modalType = ref('confirm')
const selectedBooking = ref(null)

// Computed properties
const filteredBookings = computed(() => {
  if (bookingFilter.value === 'all') {
    return recentBookings.value
  }
  return recentBookings.value.filter(booking => booking.status === bookingFilter.value)
})

const pendingBookingsCount = computed(() => {
  return recentBookings.value.filter(booking => booking.status === 'pending').length
})

const sortedSelectedDateBookings = computed(() => {
  return [...selectedDateBookings.value].sort((a, b) => {
    const timeA = new Date(a.start_time).getTime()
    const timeB = new Date(b.start_time).getTime()
    return timeA - timeB
  })
})

// Calendar computed properties
const currentMonthYear = computed(() => {
  return currentDate.value.toLocaleDateString('ru-RU', { 
    month: 'long', 
    year: 'numeric' 
  })
})

const nextMonthYear = computed(() => {
  const nextMonth = new Date(currentDate.value)
  nextMonth.setMonth(nextMonth.getMonth() + 1)
  return nextMonth.toLocaleDateString('ru-RU', { 
    month: 'long', 
    year: 'numeric' 
  })
})

const calendarDates = computed(() => {
  const year = currentDate.value.getFullYear()
  const month = currentDate.value.getMonth()
  
  const firstDay = new Date(year, month, 1)
  const startDate = new Date(firstDay)
  startDate.setDate(startDate.getDate() - firstDay.getDay() + (firstDay.getDay() === 0 ? -6 : 1))
  
  const dates = []
  const today = new Date()
  
  for (let i = 0; i < 42; i++) {
    const date = new Date(startDate)
    date.setDate(startDate.getDate() + i)
    
    const dateString = date.toISOString().split('T')[0]
    const daySlots = slotsCache.value.get(dateString) || []
    
    // Анализируем слоты для определения статуса дня
    const workSlots = daySlots.filter(slot => slot.slot_type === 'work')
    const availableSlots = workSlots.filter(slot => slot.is_available && !slot.booked)
    const bookedSlots = workSlots.filter(slot => slot.booked)
    const pendingSlots = workSlots.filter(slot => slot.booking && slot.booking.status === 'pending')
    
    // Определяем статус дня на основе слотов
    let loadLevel = 'non_working' // не рабочий день
    let dayStatus = 'non_working'
    
    if (workSlots.length > 0) {
      // Это рабочий день
      const totalSlots = workSlots.length
      const occupiedSlots = bookedSlots.length
      const occupancyRate = totalSlots > 0 ? occupiedSlots / totalSlots : 0
      
      if (occupancyRate === 0) {
        loadLevel = 'free'
        dayStatus = 'available'
      } else if (occupancyRate < 0.3) {
        loadLevel = 'light'
        dayStatus = 'available'
      } else if (occupancyRate < 0.7) {
        loadLevel = 'moderate'
        dayStatus = 'partial'
      } else if (occupancyRate < 1) {
        loadLevel = 'busy'
        dayStatus = 'partial'
      } else {
        loadLevel = 'full'
        dayStatus = 'busy'
      }
    }
    
    dates.push({
      key: date.toISOString(),
      day: date.getDate(),
      date: date,
      isCurrentMonth: date.getMonth() === month,
      isToday: date.toDateString() === today.toDateString(),
      isSelected: selectedDate.value && date.toDateString() === selectedDate.value.toDateString(),
      isPast: date < today,
      hasPendingBookings: pendingSlots.length > 0,
      totalSlots: workSlots.length,
      availableSlots: availableSlots.length,
      bookedSlots: bookedSlots.length,
      pendingSlots: pendingSlots.length,
      loadLevel: loadLevel,
      dayStatus: dayStatus,
      slots: daySlots
    })
  }
  
  return dates
})

const nextMonthDates = computed(() => {
  const year = currentDate.value.getFullYear()
  const month = currentDate.value.getMonth() + 1
  
  const firstDay = new Date(year, month, 1)
  const startDate = new Date(firstDay)
  startDate.setDate(startDate.getDate() - firstDay.getDay() + (firstDay.getDay() === 0 ? -6 : 1))
  
  const dates = []
  const today = new Date()
  
  for (let i = 0; i < 42; i++) {
    const date = new Date(startDate)
    date.setDate(startDate.getDate() + i)
    
    const dateString = date.toISOString().split('T')[0]
    const daySlots = slotsCache.value.get(dateString) || []
    
    // Анализируем слоты для определения статуса дня
    const workSlots = daySlots.filter(slot => slot.slot_type === 'work')
    const availableSlots = workSlots.filter(slot => slot.is_available && !slot.booked)
    const bookedSlots = workSlots.filter(slot => slot.booked)
    const pendingSlots = workSlots.filter(slot => slot.booking && slot.booking.status === 'pending')
    
    // Определяем статус дня на основе слотов
    let loadLevel = 'non_working' // не рабочий день
    let dayStatus = 'non_working'
    
    if (workSlots.length > 0) {
      // Это рабочий день
      const totalSlots = workSlots.length
      const occupiedSlots = bookedSlots.length
      const occupancyRate = totalSlots > 0 ? occupiedSlots / totalSlots : 0
      
      if (occupancyRate === 0) {
        loadLevel = 'free'
        dayStatus = 'available'
      } else if (occupancyRate < 0.3) {
        loadLevel = 'light'
        dayStatus = 'available'
      } else if (occupancyRate < 0.7) {
        loadLevel = 'moderate'
        dayStatus = 'partial'
      } else if (occupancyRate < 1) {
        loadLevel = 'busy'
        dayStatus = 'partial'
      } else {
        loadLevel = 'full'
        dayStatus = 'busy'
      }
    }
    
    dates.push({
      key: date.toISOString(),
      day: date.getDate(),
      date: date,
      isCurrentMonth: date.getMonth() === month - 1,
      isToday: date.toDateString() === today.toDateString(),
      isSelected: selectedDate.value && date.toDateString() === selectedDate.value.toDateString(),
      isPast: date < today,
      hasPendingBookings: pendingSlots.length > 0,
      totalSlots: workSlots.length,
      availableSlots: availableSlots.length,
      bookedSlots: bookedSlots.length,
      pendingSlots: pendingSlots.length,
      loadLevel: loadLevel,
      dayStatus: dayStatus,
      slots: daySlots
    })
  }
  
  return dates
})

onMounted(async () => {
  try {
    // Загружаем пользователя
    user.value = authStore.user
    
    // Загружаем данные параллельно
    await Promise.all([
      loadServices(),
      loadBookings(),
      loadWorkingSchedules(),
      loadSlotsForVisibleDates()
    ])
  } catch (error) {
    console.error('Error loading dashboard data:', error)
  }
})

const loadServices = async () => {
  try {
    // Загружаем услуги напрямую из API
    const response = await fetch('http://localhost:3000/api/v1/services')
    if (!response.ok) {
      throw new Error('Failed to fetch services')
    }
    const servicesData = await response.json()
    services.value = servicesData
  } catch (error) {
    console.error('Error loading services:', error)
    services.value = []
  }
}

const loadBookings = async () => {
  try {
    if (!authStore.token) {
      console.warn('No auth token available')
      recentBookings.value = []
      return
    }

    // Загружаем записи с авторизацией
    const response = await fetch('http://localhost:3000/api/v1/bookings', {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
      },
    })
    
    if (!response.ok) {
      throw new Error('Failed to fetch bookings')
    }
    
    const bookingsData = await response.json()
    recentBookings.value = bookingsData
  } catch (error) {
    console.error('Error loading bookings:', error)
    recentBookings.value = []
  }
}

const loadWorkingSchedules = async () => {
  try {
    if (!authStore.token) {
      console.warn('No auth token available')
      workingSchedules.value = []
      return
    }

    const response = await fetch('http://localhost:3000/api/v1/working_schedules', {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
      },
    })
    
    if (!response.ok) {
      throw new Error('Failed to fetch working schedules')
    }
    
    const schedulesData = await response.json()
    workingSchedules.value = schedulesData
  } catch (error) {
    console.error('Error loading working schedules:', error)
    workingSchedules.value = []
  }
}

const loadSlotsForDate = async (date) => {
  try {
    if (!authStore.token) {
      console.warn('No auth token available')
      return []
    }

    const dateString = date.toISOString().split('T')[0]
    
    // Проверяем кэш
    if (slotsCache.value.has(dateString)) {
      return slotsCache.value.get(dateString)
    }

    console.log('Loading slots for date:', dateString)

    const response = await fetch(`http://localhost:3000/api/v1/time_slots?date=${dateString}`, {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
      },
    })
    
    if (!response.ok) {
      console.error('Failed to fetch slots for', dateString, 'Status:', response.status)
      throw new Error('Failed to fetch time slots')
    }
    
    const slotsData = await response.json()
    console.log('Received slots for', dateString, ':', slotsData.slots.length)
    
    // Сохраняем в кэш
    slotsCache.value.set(dateString, slotsData.slots)
    
    return slotsData.slots
  } catch (error) {
    console.error('Error loading time slots for', date.toISOString().split('T')[0], ':', error)
    return []
  }
}

const loadSlotsForVisibleDates = async () => {
  try {
    const currentMonth = currentDate.value
    const nextMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1)
    
    // Загружаем слоты для текущего и следующего месяца
    const dates = []
    
    // Дни текущего месяца
    for (let i = 0; i < 42; i++) {
      const date = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1 - currentMonth.getDay() + i + 1)
      dates.push(date)
    }
    
    // Дни следующего месяца
    for (let i = 0; i < 42; i++) {
      const date = new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 1 - nextMonth.getDay() + i + 1)
      dates.push(date)
    }
    
    // Убираем дубликаты
    const uniqueDates = Array.from(new Set(dates.map(d => d.toISOString().split('T')[0])))
                             .map(dateStr => new Date(dateStr))
    
    // Загружаем слоты для всех дат параллельно
    await Promise.all(uniqueDates.map(date => loadSlotsForDate(date)))
    
    console.log('Loaded slots for dates:', uniqueDates.length)
  } catch (error) {
    console.error('Error loading slots for visible dates:', error)
  }
}

const editService = (service) => {
  // Заполняем форму данными для редактирования
  newService.value = {
    name: service.name,
    description: service.description,
    price: service.price.toString(),
    duration: service.duration.toString()
  }
  showModal.value = true
  
  // Сохраняем ID услуги для обновления
  editingServiceId.value = service.id
}

const addService = async () => {
  try {
    if (!authStore.token) {
      throw new Error('Не авторизован')
    }

    const serviceData = {
      name: newService.value.name,
      description: newService.value.description,
      price: parseInt(newService.value.price),
      duration: parseInt(newService.value.duration)
    }
    
    let url = 'http://localhost:3000/api/v1/services'
    let method = 'POST'
    
    // Если редактируем существующую услугу
    if (editingServiceId.value) {
      url = `http://localhost:3000/api/v1/services/${editingServiceId.value}`
      method = 'PUT'
    }
    
    // Добавляем услугу через API с авторизацией
    const response = await fetch(url, {
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authStore.token}`,
      },
      body: JSON.stringify({ service: serviceData }),
    })
    
    if (!response.ok) {
      const errorData = await response.json()
      throw new Error(errorData.errors ? errorData.errors.join(', ') : errorData.error || 'Failed to create service')
    }
    
    // Обновляем список услуг
    await loadServices()
    
    // Показываем сообщение (сохраняем состояние до очистки)
    const wasEditing = editingServiceId.value
    alert(wasEditing ? 'Услуга успешно обновлена!' : 'Услуга успешно добавлена!')
    
    // Закрываем модал и очищаем форму
    closeModal()
  } catch (error) {
    console.error('Error adding service:', error)
    alert('Ошибка при добавлении услуги: ' + error.message)
  }
}

const deleteService = async (serviceId) => {
  if (confirm('Вы уверены, что хотите удалить эту услугу?')) {
    try {
      if (!authStore.token) {
        throw new Error('Не авторизован')
      }

      const response = await fetch(`http://localhost:3000/api/v1/services/${serviceId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.token}`,
        },
      })
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to delete service')
      }
      
      await loadServices()
      alert('Услуга успешно удалена!')
    } catch (error) {
      console.error('Error deleting service:', error)
      alert('Ошибка при удалении услуги: ' + error.message)
    }
  }
}

const formatSelectedDate = () => {
  if (!selectedDate.value) return ''
  return selectedDate.value.toLocaleDateString('ru-RU', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
}

// Booking management functions
const showConfirmModal = (booking) => {
  selectedBooking.value = booking
  modalType.value = 'confirm'
  showConfirmationModal.value = true
}

const showCancelModal = (booking) => {
  selectedBooking.value = booking
  modalType.value = 'cancel'
  showConfirmationModal.value = true
}

const closeConfirmationModal = () => {
  showConfirmationModal.value = false
  selectedBooking.value = null
}

const handleModalConfirm = async (bookingId) => {
  try {
    if (!authStore.token) {
      throw new Error('Не авторизован')
    }

    const status = modalType.value === 'confirm' ? 'confirmed' : 'cancelled'
    const response = await fetch(`http://localhost:3000/api/v1/bookings/${bookingId}/update_status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authStore.token}`,
      },
      body: JSON.stringify({ status }),
    })
    
    if (!response.ok) {
      const errorData = await response.json()
      throw new Error(errorData.error || `Failed to ${modalType.value} booking`)
    }
    
    // Обновляем записи
    await loadBookings()
    if (selectedDate.value) {
      await loadBookingsForDate(selectedDate.value)
    }
    
    closeConfirmationModal()
  } catch (error) {
    console.error(`Error ${modalType.value}ing booking:`, error)
    alert(`Ошибка при ${modalType.value === 'confirm' ? 'подтверждении' : 'отмене'} записи: ` + error.message)
  }
}



const closeModal = () => {
  showModal.value = false
  newService.value = { name: '', description: '', price: '', duration: '' }
  editingServiceId.value = null
}

// Calendar functions
const previousMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() - 1, 1)
}

const nextMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() + 1, 1)
}

const selectDate = async (date) => {
  selectedDate.value = date.date
  await loadSlotsForSelectedDate(date.date)
}

const loadSlotsForSelectedDate = async (date) => {
  try {
    const slots = await loadSlotsForDate(date)
    selectedDateSlots.value = slots
    
    // Также загружаем записи для совместимости
    loadBookingsForDate(date)
  } catch (error) {
    console.error('Error loading slots for selected date:', error)
    selectedDateSlots.value = []
  }
}

const loadBookingsForDate = async (date) => {
  try {
    // Используем уже загруженные записи из recentBookings
    const startOfDay = new Date(date)
    startOfDay.setHours(0, 0, 0, 0)
    const endOfDay = new Date(date)
    endOfDay.setHours(23, 59, 59, 999)
    
    selectedDateBookings.value = recentBookings.value.filter(booking => {
      const bookingDate = new Date(booking.start_time)
      return bookingDate >= startOfDay && bookingDate <= endOfDay
    })
    
    // Check if there are any pending bookings for this date
    const hasPendingBookings = selectedDateBookings.value.some(booking => booking.status === 'pending');
    
    // Обновляем календарь для отображения точек
    const currentDateString = date.toDateString()
    const currentDateInCalendar = calendarDates.value.find(d => d.date.toDateString() === currentDateString)
    const nextDateInCalendar = nextMonthDates.value.find(d => d.date.toDateString() === currentDateString)
    
    if (currentDateInCalendar) {
      currentDateInCalendar.hasPendingBookings = hasPendingBookings
    }
    if (nextDateInCalendar) {
      nextDateInCalendar.hasPendingBookings = hasPendingBookings
    }
  } catch (error) {
    console.error('Error loading bookings for date:', error)
    selectedDateBookings.value = []
  }
}

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

const handleScrollToSection = (sectionId) => {
  const element = document.getElementById(sectionId);
  if (element) {
    element.scrollIntoView({ behavior: 'smooth' });
  }
};

const setBookingFilter = (filter) => {
  bookingFilter.value = filter;
};

const handleNotificationClick = () => {
  // Прокручиваем к блоку записей и устанавливаем фильтр на неподтвержденные
  handleScrollToSection('bookings')
  setBookingFilter('pending')
};

// Calendar styling methods
const getDateBgClass = (date) => {
  if (date.isPast) return 'bg-gray-50 border-gray-200'
  
  switch (date.loadLevel) {
    case 'non_working':
      return 'bg-gray-100 border-gray-300 cursor-not-allowed'
    case 'free':
      return 'bg-green-50 border-green-200 hover:bg-green-100'
    case 'light':
      return 'bg-lime-50 border-lime-200 hover:bg-lime-100'
    case 'moderate':
      return 'bg-yellow-50 border-yellow-200 hover:bg-yellow-100'
    case 'busy':
      return 'bg-orange-50 border-orange-200 hover:bg-orange-100'
    case 'full':
      return 'bg-red-50 border-red-200 hover:bg-red-100'
    default:
      return 'bg-white border-gray-200 hover:bg-gray-50'
  }
}

const getDateBorderClass = (date) => {
  if (date.isPast) return 'border-gray-200'
  
  switch (date.loadLevel) {
    case 'non_working':
      return 'border-gray-300'
    case 'free':
      return 'border-green-200'
    case 'light':
      return 'border-lime-200'
    case 'moderate':
      return 'border-yellow-200'
    case 'busy':
      return 'border-orange-200'
    case 'full':
      return 'border-red-200'
    default:
      return 'border-gray-200'
  }
}

const getBookingDotClass = (date) => {
  switch (date.loadLevel) {
    case 'non_working':
      return 'bg-gray-400'
    case 'light':
      return 'bg-lime-400'
    case 'moderate':
      return 'bg-yellow-400'
    case 'busy':
      return 'bg-orange-400'
    case 'full':
      return 'bg-red-400'
    default:
      return 'bg-gray-400'
  }
}

// Slot helper functions
const getSlotTypeText = (slotType) => {
  const texts = {
    'work': 'Рабочий слот',
    'lunch': 'Обеденный перерыв',
    'blocked': 'Заблокировано'
  }
  return texts[slotType] || slotType
}

const getSlotStatusClass = (slot) => {
  if (slot.slot_type === 'lunch') {
    return 'bg-gray-100 text-gray-800'
  }
  if (slot.slot_type === 'blocked') {
    return 'bg-red-100 text-red-800'
  }
  if (slot.booked) {
    return 'bg-blue-100 text-blue-800'
  }
  if (slot.is_available) {
    return 'bg-green-100 text-green-800'
  }
  return 'bg-gray-100 text-gray-800'
}

const getSlotStatusText = (slot) => {
  if (slot.slot_type === 'lunch') {
    return 'Обед'
  }
  if (slot.slot_type === 'blocked') {
    return 'Заблокировано'
  }
  if (slot.booked) {
    return 'Занято'
  }
  if (slot.is_available) {
    return 'Свободно'
  }
  return 'Недоступно'
}

// Navigation function
const goToScheduleSettings = () => {
  router.push('/master/schedule')
}
</script> 