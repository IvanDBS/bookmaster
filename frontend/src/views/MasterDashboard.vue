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
                       'h-12 flex flex-col items-center justify-center text-sm cursor-pointer rounded-lg transition-all duration-200 border-2',
                       date.isCurrentMonth ? 'hover:shadow-md' : 'text-gray-400',
                       date.isSelected ? 'border-blue-500 text-gray-900 shadow-md' : 'border-transparent',
                       date.isToday && !date.isSelected ? 'bg-blue-50 border-blue-200 font-semibold' : '',
                       date.isPast ? 'text-gray-400 cursor-not-allowed' : '',
                       getDateBgClass(date),
                       getDateBorderClass(date)
                     ]">
                  <span class="text-xs font-medium">{{ date.day }}</span>
                  <!-- Индикатор нерабочего дня (приоритет выше загруженности) -->
                  <!-- <div v-if="date.loadLevel === 'non_working'" class="mt-0.5">
                    <span class="text-xs text-gray-400">⚫</span>
                  </div> -->
                  <!-- Индикатор загруженности на основе слотов -->
                  <!-- <div v-else-if="date.totalSlots > 0" class="flex items-center space-x-0.5 mt-0.5">
                    <div v-for="n in Math.min(date.bookedSlots, 4)" :key="n" 
                         :class="[
                           'w-1 h-1 rounded-full',
                           getBookingDotClass(date)
                         ]">
                    </div>
                    <span v-if="date.bookedSlots > 4" class="text-xs font-bold">+</span>
                  </div> -->
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
                       'h-12 flex flex-col items-center justify-center text-sm cursor-pointer rounded-lg transition-all duration-200 border-2',
                       date.isCurrentMonth ? 'hover:shadow-md' : 'text-gray-400',
                       date.isSelected ? 'border-blue-500 text-gray-900 shadow-md' : 'border-transparent',
                       date.isToday && !date.isSelected ? 'bg-blue-50 border-blue-200 font-semibold' : '',
                       date.isPast ? 'text-gray-400 cursor-not-allowed' : '',
                       getDateBgClass(date),
                       getDateBorderClass(date)
                     ]">
                  <span class="text-xs font-medium">{{ date.day }}</span>
                  <!-- Индикатор нерабочего дня (приоритет выше загруженности) -->
                  <!-- <div v-if="date.loadLevel === 'non_working'" class="mt-0.5">
                    <span class="text-xs text-gray-400">⚫</span>
                  </div> -->
                  <!-- Индикатор загруженности на основе слотов -->
                  <!-- <div v-else-if="date.totalSlots > 0" class="flex items-center space-x-0.5 mt-0.5">
                    <div v-for="n in Math.min(date.bookedSlots, 4)" :key="n" 
                         :class="[
                           'w-1 h-1 rounded-full',
                           getBookingDotClass(date)
                         ]">
                    </div>
                    <span v-if="date.bookedSlots > 4" class="text-xs font-bold">+</span>
                  </div> -->
                </div>
              </div>
            </div>
          </div>

          <!-- Calendar Legend -->
          <div class="mt-6 bg-gray-50 rounded-lg p-4">
            <h5 class="font-semibold text-gray-900 mb-3">Обозначения загруженности</h5>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
              <div class="flex items-center space-x-2">
                <div class="w-4 h-4 bg-gray-100 border border-gray-300 rounded"></div>
                <span class="text-gray-700">Выходной</span>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-4 h-4 bg-green-50 border border-green-300 rounded"></div>
                <span class="text-gray-700">Записей нет</span>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-4 h-4 bg-orange-100 border border-orange-300 rounded"></div>
                <span class="text-gray-700">Есть записи</span>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-4 h-4 bg-red-100 border border-red-300 rounded"></div>
                <span class="text-gray-700">Нет свободных мест</span>
              </div>
            </div>
          </div>

          <!-- Selected Date Slots -->
          <div v-if="selectedDate" class="mt-6">
            <div class="flex items-center justify-between mb-3">
              <h5 class="font-semibold text-gray-900">
                Временные слоты на {{ formatSelectedDate() }}
              </h5>
              
              <!-- Toggle Switch для управления статусом дня -->
              <div class="flex items-center space-x-3">
                <span class="text-sm text-gray-700">Рабочий день</span>
                <button
                  @click="toggleDayStatus"
                  :class="[
                    'relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
                    isDayWorking
                      ? 'bg-blue-600'
                      : 'bg-gray-200'
                  ]"
                  role="switch"
                  :aria-checked="isDayWorking"
                >
                  <span
                    :class="[
                      'inline-block h-4 w-4 transform rounded-full bg-white transition duration-200 ease-in-out',
                      isDayWorking
                        ? 'translate-x-6'
                        : 'translate-x-1'
                    ]"
                  />
                </button>
              </div>
            </div>
            
            <!-- Slots Grid (only show if there are slots) -->
            <div v-if="selectedDateSlots.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
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
                  <div class="flex items-center space-x-2 ml-2">
                    <!-- Переключатель перерыва для свободных слотов -->
                    <button
                      v-if="!slot.booked"
                      @click="onToggleSlotBreak(slot, !isBreak(slot))"
                      :class="[
                        'relative inline-flex h-5 w-10 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
                        isBreak(slot) ? 'bg-red-500' : 'bg-gray-200'
                      ]"
                      :title="isBreak(slot) ? 'Сделать свободным' : 'Отметить как перерыв'"
                    >
                      <span
                        :class="[
                          'inline-block h-3.5 w-3.5 transform rounded-full bg-white transition duration-200 ease-in-out',
                          isBreak(slot) ? 'translate-x-5' : 'translate-x-1'
                        ]"
                      />
                    </button>

                    <span :class="getSlotStatusClass(slot)" class="px-2 py-1 rounded-full text-xs font-semibold">
                      {{ getSlotStatusText(slot) }}
                    </span>

                    <!-- Кнопки принять/отменить для pending -->
                    <div v-if="slot.booking && slot.booking.status === 'pending'" class="flex space-x-1">
                      <button @click="showConfirmModal(slot.booking)" class="text-green-600 hover:text-green-700 text-xs font-medium" title="Принять">
                        ✓
                      </button>
                      <button @click="showCancelModal(slot.booking)" class="text-red-600 hover:text-red-700 text-xs font-medium" title="Отменить">
                        ✕
                      </button>
                    </div>
                    <!-- Кнопка удаления для confirmed -->
                    <div v-else-if="slot.booking && slot.booking.status === 'confirmed'" class="flex space-x-1">
                      <button @click="showDeleteModal(slot.booking)" class="text-red-600 hover:text-red-700 text-xs font-medium" title="Удалить запись">
                        🗑
                      </button>
                    </div>
                  </div>
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
            
            <!-- Кнопка добавления нового слота -->
            <div v-if="selectedDateSlots.length > 0" class="mt-6 flex justify-center">
              <button 
                @click="addNewSlot"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                :class="[
                  isAddingSlot 
                    ? 'bg-gray-400 text-white focus:ring-gray-500' 
                    : 'bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white focus:ring-blue-500'
                ]"
                :disabled="isAddingSlot"
              >
                <svg v-if="isAddingSlot" class="animate-spin -ml-1 mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                <svg v-else class="-ml-1 mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                </svg>
                <span>{{ isAddingSlot ? 'Добавляем...' : 'Добавить окно' }}</span>
              </button>
            </div>
          </div>

          <!-- Selected Date Bookings - СКРЫТО, записи показываются только в слотах -->
          <!-- <div v-if="selectedDateBookings.length > 0" class="mt-6">
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
                    <div v-else-if="booking.status === 'confirmed'" class="flex space-x-1 mt-1">
                      <button @click="showDeleteModal(booking)" class="text-red-600 hover:text-red-700 text-xs font-medium" title="Удалить запись">
                        🗑
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div> -->
          <div v-if="selectedDate && selectedDateSlots.length === 0" class="mt-6 text-center py-4">
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
              <label class="block text-sm font-medium text-gray-700 mb-2">Тип услуги</label>
              <select v-model="newService.service_type" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-lime-500 focus:border-lime-500">
                <option value="">Выберите тип услуги</option>
                <option v-for="serviceType in availableServiceTypes" :key="serviceType" :value="serviceType">
                  {{ serviceType.charAt(0).toUpperCase() + serviceType.slice(1) }}
                </option>
              </select>
            </div>
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
import { ref, onMounted, onActivated, computed, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import AppHeader from '../components/AppHeader.vue'
import ConfirmationModal from '../components/ConfirmationModal.vue'
import api from '../services/api'

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
  duration: '',
  service_type: ''
})
const availableServiceTypes = ref([])

// Calendar data
const currentDate = ref(new Date())
const selectedDate = ref(null)
const selectedDateBookings = ref([])
const selectedDateSlots = ref([])
const workingSchedules = ref([])
const slotsCache = ref(new Map()) // Кэш слотов по датам
const workingDayExceptions = ref([]) // Исключения по дням

// Modal data
const showConfirmationModal = ref(false)
const modalType = ref('confirm')
const selectedBooking = ref(null)
const isAddingSlot = ref(false)

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

// Computed для определения статуса выбранного дня (локальная дата, без ISO/UTC)
const isDayWorking = computed(() => {
  if (!selectedDate.value) return false

  const dateString = `${selectedDate.value.getFullYear()}-${String(selectedDate.value.getMonth()+1).padStart(2,'0')}-${String(selectedDate.value.getDate()).padStart(2,'0')}`
  const exception = workingDayExceptions.value.find(ex => ex.date === dateString)

  if (exception) {
    // Исключение имеет приоритет
    return !!exception.is_working
  }

  // Используем расписание
  const dayOfWeek = selectedDate.value.getDay()
  const schedule = workingSchedules.value.find(s => s.day_of_week === dayOfWeek)
  return !!(schedule && schedule.is_working)
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
  startDate.setDate(startDate.getDate() - (firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1))
  
    const dates = []
    const today = new Date()
  
  for (let i = 0; i < 42; i++) {
    const date = new Date(startDate)
    date.setDate(startDate.getDate() + i)
    
    // ВАЖНО: используем локальную дату как ключ, чтобы не было смещения дня при TZ
    const dateString = `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`
    const daySlots = slotsCache.value.get(dateString) || []
    
    // Анализируем слоты для определения статуса дня
    const workSlots = daySlots.filter(slot => slot.slot_type === 'work')
    const blockedSlots = daySlots.filter(slot => slot.slot_type === 'blocked')
    const availableSlots = workSlots.filter(slot => slot.is_available && !slot.booked)
    const bookedSlots = workSlots.filter(slot => slot.booked)
    const pendingSlots = workSlots.filter(slot => slot.booking && slot.booking.status === 'pending')
    
    // Общее количество слотов, которые могут быть забронированы (рабочие + заблокированные)
    const totalBookableSlots = workSlots.length + blockedSlots.length
    // Количество доступных слотов (только рабочие, которые доступны и не забронированы)
    const totalAvailableSlots = availableSlots.length
    
    // Определяем статус дня на основе расписания, исключений и слотов (CURRENT MONTH)
    const dayOfWeek = date.getDay(); // 0 for Sunday, 1 for Monday, etc.
    const scheduleForDay = workingSchedules.value.find(s => s.day_of_week === dayOfWeek);
    const exception = workingDayExceptions.value.find(ex => ex.date === dateString);

    let loadLevel = 'non_working'; // не рабочий день по умолчанию
    let dayStatus = 'non_working';
    
    // Определяем, является ли день рабочим (исключение имеет приоритет над расписанием)
    const isDayWorkingFinal = exception ? exception.is_working : (scheduleForDay?.is_working || false);

    if (isDayWorkingFinal) {
      // Если день явно помечен как рабочий в настройках
      if (workSlots.length === 0) {
        // Если рабочий день, но слоты не сгенерированы - считаем свободным
        loadLevel = 'free';
        dayStatus = 'available';
      } else {
        // Если есть рабочие слоты, определяем уровень загруженности
        const totalSlots = workSlots.length;
        const occupiedSlots = bookedSlots.length;
        const occupancyRate = totalSlots > 0 ? occupiedSlots / totalSlots : 0;

        if (occupancyRate === 0) {
          loadLevel = 'free';
          dayStatus = 'available';
        } else if (occupancyRate < 0.3) {
          loadLevel = 'light';
          dayStatus = 'available';
        } else if (occupancyRate < 0.7) {
          loadLevel = 'moderate';
          dayStatus = 'partial';
        } else if (occupancyRate < 1) {
          loadLevel = 'busy';
          dayStatus = 'partial';
        } else {
          loadLevel = 'full';
          dayStatus = 'busy';
        }
      }
    } else {
      // Если день не помечен как рабочий в настройках
      loadLevel = 'non_working';
      dayStatus = 'non_working';
    }
    
    // Отладка для 20 августа
    if (dateString === '2025-08-20') {
      console.log(`Debug August 20th:`, {
        daySlots: daySlots.length,
        workSlots: workSlots.length,
        blockedSlots: blockedSlots.length,
        availableSlots: availableSlots.length,
        bookedSlots: bookedSlots.length,
        totalSlots: workSlots.length + blockedSlots.length,
        availableSlots: totalAvailableSlots,
        loadLevel,
        dayStatus,
        allSlots: daySlots.map(s => ({
          id: s.id,
          start_time: s.start_time,
          slot_type: s.slot_type,
          is_available: s.is_available,
          booked: s.booked,
          booking: s.booking
        })),
        bookedSlotsDetails: bookedSlots.map(s => ({
          id: s.id,
          start_time: s.start_time,
          booking: s.booking
        }))
      })
    }
    
    // Отладка для вторника
    if (date.getDay() === 2) {
      console.log(`Debug Tuesday ${dateString}:`, {
        daySlots: daySlots.length,
        workSlots: workSlots.length,
        loadLevel,
        scheduleForDay: scheduleForDay?.is_working,
        allSlots: daySlots
      })
    }
    
    // Отладка для субботы (день недели 6)
    if (date.getDay() === 6) {
      console.log(`Debug Saturday ${dateString}:`, {
        daySlots: daySlots.length,
        workSlots: workSlots.length,
        loadLevel,
        dayStatus,
        scheduleForDay: scheduleForDay?.is_working,
        totalSlots: workSlots.length,
        isCurrentMonth: date.getMonth() === month,
        isSelected: selectedDate.value && date.toDateString() === selectedDate.value.toDateString()
      })
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
      totalSlots: workSlots.length + blockedSlots.length,
      availableSlots: totalAvailableSlots,
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
  startDate.setDate(startDate.getDate() - (firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1))
  
    const dates = []
    const today = new Date()
  
  for (let i = 0; i < 42; i++) {
    const date = new Date(startDate)
    date.setDate(startDate.getDate() + i)
    
    // ВАЖНО: используем локальную дату как ключ, чтобы не было смещения дня при TZ
    const dateString = `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`
    const daySlots = slotsCache.value.get(dateString) || []
    
    // Анализируем слоты для определения статуса дня
    const workSlots = daySlots.filter(slot => slot.slot_type === 'work')
    const blockedSlots = daySlots.filter(slot => slot.slot_type === 'blocked')
    const availableSlots = workSlots.filter(slot => slot.is_available && !slot.booked)
    const bookedSlots = workSlots.filter(slot => slot.booked)
    const pendingSlots = workSlots.filter(slot => slot.booking && slot.booking.status === 'pending')
    
    // Общее количество слотов, которые могут быть забронированы (рабочие + заблокированные)
    const totalBookableSlots = workSlots.length + blockedSlots.length
    // Количество доступных слотов (только рабочие, которые доступны и не забронированы)
    const totalAvailableSlots = availableSlots.length
    
    // Определяем статус дня на основе расписания, исключений и слотов (NEXT MONTH)
    const dayOfWeek = date.getDay(); // 0 for Sunday, 1 for Monday, etc.
    const scheduleForDay = workingSchedules.value.find(s => s.day_of_week === dayOfWeek);
    const exception = workingDayExceptions.value.find(ex => ex.date === dateString);

    let loadLevel = 'non_working'; // не рабочий день по умолчанию
    let dayStatus = 'non_working';
    
    // Определяем, является ли день рабочим (исключение имеет приоритет над расписанием)
    const isDayWorkingFinal = exception ? exception.is_working : (scheduleForDay?.is_working || false);

    if (isDayWorkingFinal) {
      // Если день явно помечен как рабочий в настройках
      if (workSlots.length === 0) {
        // Если рабочий день, но слоты не сгенерированы - считаем свободным
        loadLevel = 'free';
        dayStatus = 'available';
      } else {
        // Если есть рабочие слоты, определяем уровень загруженности
        const totalSlots = workSlots.length;
        const occupiedSlots = bookedSlots.length;
        const occupancyRate = totalSlots > 0 ? occupiedSlots / totalSlots : 0;

        if (occupancyRate === 0) {
          loadLevel = 'free';
          dayStatus = 'available';
        } else if (occupancyRate < 0.3) {
          loadLevel = 'light';
          dayStatus = 'available';
        } else if (occupancyRate < 0.7) {
          loadLevel = 'moderate';
          dayStatus = 'partial';
        } else if (occupancyRate < 1) {
          loadLevel = 'busy';
          dayStatus = 'partial';
        } else {
          loadLevel = 'full';
          dayStatus = 'busy';
        }
      }
    } else {
      // Если день не помечен как рабочий в настройках
      loadLevel = 'non_working';
      dayStatus = 'non_working';
    }
    
    // Отладка для вторника в следующем месяце
    if (date.getDay() === 2) {
      console.log(`Debug Next Month Tuesday ${dateString}:`, {
        daySlots: daySlots.length,
        workSlots: workSlots.length,
        loadLevel,
        scheduleForDay: scheduleForDay?.is_working,
        allSlots: daySlots
      })
    }
    
    // Отладка для субботы в следующем месяце (день недели 6)
    if (date.getDay() === 6) {
      console.log(`Debug Next Month Saturday ${dateString}:`, {
        daySlots: daySlots.length,
        workSlots: workSlots.length,
        loadLevel,
        dayStatus,
        scheduleForDay: scheduleForDay?.is_working,
        totalSlots: workSlots.length,
        isCurrentMonth: date.getMonth() === month - 1,
        isSelected: selectedDate.value && date.toDateString() === selectedDate.value.toDateString()
      })
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
      totalSlots: workSlots.length + blockedSlots.length,
      availableSlots: totalAvailableSlots,
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
  console.log('MasterDashboard mounted')
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
  slotsCache.value.clear()
  loadSlotsForVisibleDates()
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

const loadServiceTypes = async () => {
  try {
    const serviceTypesData = await api.getServiceTypes()
    availableServiceTypes.value = serviceTypesData.service_types || []
  } catch (error) {
    console.error('Error loading service types:', error)
    availableServiceTypes.value = ['маникюр', 'педикюр', 'массаж'] // fallback to default types
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
    
    // Отладочная информация
    console.log('Loaded working schedules:', workingSchedules.value)
  } catch (error) {
    console.error('Error loading working schedules:', error)
    workingSchedules.value = []
  }
}

// Методы для работы с исключениями дней
const loadWorkingDayExceptions = async () => {
  try {
    if (!authStore.token) {
      console.warn('No auth token available')
      workingDayExceptions.value = []
      return
    }

    const exceptionsData = await api.getWorkingDayExceptions(authStore.token)
    workingDayExceptions.value = exceptionsData
    
    console.log('Loaded working day exceptions:', workingDayExceptions.value.length)
  } catch (error) {
    console.error('Error loading working day exceptions:', error)
    workingDayExceptions.value = []
  }
}

const toggleDayStatus = async () => {
  try {
    if (!selectedDate.value || !authStore.token) {
      console.warn('No selected date or auth token')
      return
    }

    const dateString = `${selectedDate.value.getFullYear()}-${String(selectedDate.value.getMonth()+1).padStart(2,'0')}-${String(selectedDate.value.getDate()).padStart(2,'0')}`
    console.log('Toggling day status for:', dateString)
    
    // Оптимистичное обновление — мгновенная анимация переключателя
    const currentIsWorking = isDayWorking.value
    const idx = workingDayExceptions.value.findIndex(ex => ex.date === dateString)
    const prevException = idx !== -1 ? { ...workingDayExceptions.value[idx] } : null
    const optimistic = { id: prevException?.id, date: dateString, is_working: !currentIsWorking, reason: prevException?.reason || null }
    if (idx !== -1) {
      workingDayExceptions.value[idx] = optimistic
    } else {
      workingDayExceptions.value.push(optimistic)
    }
    slotsCache.value.delete(dateString)
    
    // Серверный вызов
    const updatedException = await api.toggleWorkingDay(dateString, authStore.token)
    
    // Приводим локальное состояние к серверному
    const existingIndex = workingDayExceptions.value.findIndex(ex => ex.date === dateString)
    if (existingIndex !== -1) {
      workingDayExceptions.value[existingIndex] = updatedException
    } else {
      workingDayExceptions.value.push(updatedException)
    }
    
    await loadSlotsForSelectedDate(selectedDate.value)
    console.log('Day status toggled successfully:', updatedException)
  } catch (error) {
    // Откат, если сервер вернул ошибку
    try {
      if (selectedDate.value) {
        const dateString = `${selectedDate.value.getFullYear()}-${String(selectedDate.value.getMonth()+1).padStart(2,'0')}-${String(selectedDate.value.getDate()).padStart(2,'0')}`
        const idx = workingDayExceptions.value.findIndex(ex => ex.date === dateString)
        if (idx !== -1) workingDayExceptions.value.splice(idx, 1)
        await loadSlotsForSelectedDate(selectedDate.value)
      }
    } catch (_) {}
    console.error('Error toggling day status:', error)
    alert('Ошибка при изменении статуса дня: ' + error.message)
  }
}

const loadSlotsForDate = async (date) => {
  try {
    if (!authStore.token) {
      console.warn('No auth token available')
      return []
    }

    const dateString = `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`
    
    // Проверяем кэш
    if (slotsCache.value.has(dateString)) {
      console.log(`Cache HIT for ${dateString}. Slots:`, slotsCache.value.get(dateString).length);
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
    console.log('Received slots for', dateString, ':', slotsData.slots.length, 'Slots data:', slotsData.slots);
    
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
      const firstDayOfMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1);
      const startCalendarDate = new Date(firstDayOfMonth);
      startCalendarDate.setDate(startCalendarDate.getDate() - (firstDayOfMonth.getDay() === 0 ? 6 : firstDayOfMonth.getDay() - 1));
      const date = new Date(startCalendarDate);
      date.setDate(startCalendarDate.getDate() + i);
      dates.push(date)
    }
    
    // Дни следующего месяца
    for (let i = 0; i < 42; i++) {
      const firstDayOfNextMonth = new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 1);
      const startCalendarDateNextMonth = new Date(firstDayOfNextMonth);
      startCalendarDateNextMonth.setDate(startCalendarDateNextMonth.getDate() - (firstDayOfNextMonth.getDay() === 0 ? 6 : firstDayOfNextMonth.getDay() - 1));
      const date = new Date(startCalendarDateNextMonth);
      date.setDate(startCalendarDateNextMonth.getDate() + i);
      dates.push(date)
    }
    
    // Убираем дубликаты
    const uniqueDates = Array.from(new Set(
      dates.map(d => `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`)
    )).map(dateStr => new Date(dateStr))
    
    // Загружаем слоты для всех дат параллельно
    await Promise.all(uniqueDates.map(date => loadSlotsForDate(date)))
    
    console.log('Loaded slots for dates:', uniqueDates.length)
  } catch (error) {
    console.error('Error loading slots for visible dates:', error)
  }
}

// Добавляем функцию для принудительного обновления календаря
const refreshCalendar = async () => {
  console.log('Forcing calendar refresh...')
  
  // Очищаем весь кэш слотов
  slotsCache.value.clear()
  
  // Перезагружаем слоты для видимых дат
  await loadSlotsForVisibleDates()
  
  // Если есть выбранная дата, перезагружаем её данные
  if (selectedDate.value) {
    await loadSlotsForSelectedDate(selectedDate.value)
    await loadBookingsForDate(selectedDate.value)
  }
  
  console.log('Calendar refresh completed')
}

const editService = (service) => {
  // Заполняем форму данными для редактирования
  newService.value = {
    name: service.name,
    description: service.description,
    price: service.price.toString(),
    duration: service.duration.toString(),
    service_type: service.service_type || ''
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
      duration: parseInt(newService.value.duration),
      service_type: newService.value.service_type
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

const showDeleteModal = (booking) => {
  selectedBooking.value = booking
  modalType.value = 'delete'
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

    let status
    if (modalType.value === 'confirm') {
      status = 'confirmed'
    } else if (modalType.value === 'cancel') {
      status = 'cancelled'
    } else if (modalType.value === 'delete') {
      // Для удаления используем DELETE запрос
      const response = await fetch(`http://localhost:3000/api/v1/bookings/${bookingId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.token}`,
        },
      })
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to delete booking')
      }
      
      // Обновляем записи
      await loadBookings()
      
      // Принудительно обновляем весь календарь
      await refreshCalendar()
      
      closeConfirmationModal()
      return
    } else {
      status = 'cancelled'
    }

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
    
    // Принудительно очищаем кеш для всех дат
    if (selectedDate.value) {
      // Очищаем кеш для выбранной даты
      const dateKey = `${selectedDate.value.getFullYear()}-${String(selectedDate.value.getMonth()+1).padStart(2,'0')}-${String(selectedDate.value.getDate()).padStart(2,'0')}`
      slotsCache.value.delete(dateKey)
      
      // Перезагружаем данные
      await loadSlotsForSelectedDate(selectedDate.value)
      await loadBookingsForDate(selectedDate.value)
    }
    
    // Обновляем календарь
    await loadSlotsForVisibleDates()
    
    closeConfirmationModal()
  } catch (error) {
    console.error(`Error ${modalType.value}ing booking:`, error)
    alert(`Ошибка при ${modalType.value === 'confirm' ? 'подтверждении' : modalType.value === 'cancel' ? 'отмене' : 'удалении'} записи: ` + error.message)
  }
}



const closeModal = () => {
  showModal.value = false
  newService.value = { name: '', description: '', price: '', duration: '', service_type: '' }
  editingServiceId.value = null
}

// Calendar functions
const previousMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() - 1, 1)
  loadSlotsForVisibleDates()
}

const nextMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() + 1, 1)
  loadSlotsForVisibleDates()
}

const selectDate = async (date) => {
  console.log(`Selecting date: ${date.date.toDateString()}`)
  selectedDate.value = date.date
  await loadSlotsForSelectedDate(date.date)
  
  // Принудительное обновление для корректного отображения индикаторов
  // Нужно для того чтобы isSelected правильно обновлялся для всех дат
  await nextTick()
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
  
  if (date.loadLevel === 'non_working') {
    return 'bg-gray-100 border-gray-300 cursor-not-allowed' // Серый - выходной
  }
  
  // Если есть слоты, но нет свободных (все слоты забронированы или заблокированы)
  if (date.totalSlots > 0 && date.availableSlots === 0) {
    return 'bg-red-100 border-red-300' // Красный - нет свободных слотов (приоритет над оранжевым)
  }
  
  // Если есть записи (bookedSlots > 0)
  if (date.bookedSlots > 0) {
    return 'bg-orange-100 border-orange-300' // Оранжевый - есть записи
  }
  
  // Если есть свободные слоты (рабочий день с доступными слотами)
  return 'bg-green-50 border-green-300' // Зеленый - рабочий день со свободными слотами
}

const getDateBorderClass = (date) => {
  if (date.isPast) return 'border-gray-200'
  
  if (date.loadLevel === 'non_working') {
    return 'border-gray-300' // Серый - выходной
  }
  
  // Если есть слоты, но нет свободных (все слоты забронированы или заблокированы)
  if (date.totalSlots > 0 && date.availableSlots === 0) {
    return 'border-red-300' // Красный - нет свободных слотов (приоритет над оранжевым)
  }
  
  // Если есть записи (bookedSlots > 0)
  if (date.bookedSlots > 0) {
    return 'border-orange-300' // Оранжевый - есть записи
  }
  
  // Если есть свободные слоты (рабочий день с доступными слотами)
  return 'border-green-300' // Зеленый - рабочий день со свободными слотами
}

const getBookingDotClass = (date) => {
  if (date.loadLevel === 'non_working') {
    return 'bg-gray-400' // Серые точки для выходного
  }
  
  // Если есть слоты, но нет свободных (все слоты забронированы или заблокированы)
  if (date.totalSlots > 0 && date.availableSlots === 0) {
    return 'bg-red-400' // Красные точки для дня без свободных слотов (приоритет над оранжевым)
  }
  
  // Если есть записи (bookedSlots > 0)
  if (date.bookedSlots > 0) {
    return 'bg-orange-400' // Оранжевые точки для дней с записями
  }
  
  // Если есть свободные слоты (рабочий день с доступными слотами)
  return 'bg-green-400' // Зеленые точки для свободных рабочих дней
}

// Slot helper functions
const getSlotTypeText = (slotType) => {
  const texts = {
    'work': 'Рабочий слот',
    'lunch': 'Перерыв',
    'blocked': 'Перерыв'
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
    return 'Перерыв'
  }
  if (slot.slot_type === 'blocked') {
    return 'Перерыв'
  }
  if (slot.booked) {
    return 'Занято'
  }
  if (slot.is_available) {
    return 'Свободно'
  }
  return 'Недоступно'
}

const isBreak = (slot) => slot.slot_type === 'blocked' || slot.slot_type === 'lunch'

const onToggleSlotBreak = async (slot, isBreakNext) => {
  // Оптимистичное обновление для мгновенной реакции UI
  const dateKey = selectedDate.value
    ? `${selectedDate.value.getFullYear()}-${String(selectedDate.value.getMonth()+1).padStart(2,'0')}-${String(selectedDate.value.getDate()).padStart(2,'0')}`
    : null

  const prevSlots = [...selectedDateSlots.value]
  const nextSlots = selectedDateSlots.value.map(s => {
    if (s.id !== slot.id) return s
    if (isBreakNext) {
      return { ...s, slot_type: 'blocked', is_available: false }
    }
    return { ...s, slot_type: 'work', is_available: true }
  })
  selectedDateSlots.value = nextSlots
  if (dateKey) slotsCache.value.set(dateKey, nextSlots)

  try {
    if (!authStore.token) throw new Error('Не авторизован')
    const response = await fetch(`http://localhost:3000/api/v1/time_slots/${slot.id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authStore.token}`
      },
      body: JSON.stringify({ is_break: isBreakNext })
    })
    const json = await response.json()
    if (!response.ok) {
      throw new Error(json.error || 'Не удалось обновить слот')
    }
    if (selectedDate.value) {
      slotsCache.value.delete(dateKey)
      await loadSlotsForSelectedDate(selectedDate.value)
    }
  } catch (e) {
    // Откат при ошибке
    selectedDateSlots.value = prevSlots
    if (dateKey) slotsCache.value.set(dateKey, prevSlots)
    console.error('Failed to toggle break for slot', slot.id, e)
    alert('Не удалось изменить статус слота: ' + e.message)
  }
}

const addNewSlot = async () => {
  if (!selectedDate.value || !authStore.token) {
    console.warn('No selected date or auth token')
    return
  }

  isAddingSlot.value = true
  
  try {
    const dateString = `${selectedDate.value.getFullYear()}-${String(selectedDate.value.getMonth()+1).padStart(2,'0')}-${String(selectedDate.value.getDate()).padStart(2,'0')}`
    
    const response = await fetch(`http://localhost:3000/api/v1/time_slots/add_slot`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authStore.token}`
      },
      body: JSON.stringify({ date: dateString })
    })
    
    const json = await response.json()
    
    if (!response.ok) {
      throw new Error(json.error || 'Не удалось добавить новый слот')
    }
    
    // Очищаем кэш и перезагружаем слоты
    slotsCache.value.delete(dateString)
    await loadSlotsForSelectedDate(selectedDate.value)
    
    console.log('New slot added successfully:', json)
  } catch (error) {
    console.error('Error adding new slot:', error)
    alert('Ошибка при добавлении нового слота: ' + error.message)
  } finally {
    isAddingSlot.value = false
  }
}

// Navigation function
const goToScheduleSettings = () => {
  router.push('/master/schedule')
}


</script> 