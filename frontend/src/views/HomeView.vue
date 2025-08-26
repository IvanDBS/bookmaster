<template>
  <div class="min-h-screen bg-white overflow-x-hidden">
    <!-- Header -->
    <header class="bg-white border-b border-gray-100 sticky top-0 z-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6">
        <div class="flex justify-between items-center h-16 sm:h-20">
          <!-- Logo -->
          <div class="flex items-center space-x-2 sm:space-x-3">
            <div class="flex space-x-1">
              <div class="w-2 h-2 sm:w-3 sm:h-3 bg-blue-500 rounded-full"></div>
              <div class="w-2 h-2 sm:w-3 sm:h-3 bg-yellow-500 rounded-full"></div>
              <div class="w-2 h-2 sm:w-3 sm:h-3 bg-red-500 rounded-full"></div>
            </div>
            <h1 class="text-lg sm:text-2xl font-bold text-gray-900">BookMaster</h1>
          </div>

          <!-- Navigation -->
          <nav class="hidden lg:flex items-center space-x-8">
            <a href="#" class="text-gray-600 hover:text-gray-900 font-medium transition-colors"
              >Услуги</a
            >
            <a href="#" class="text-gray-600 hover:text-gray-900 font-medium transition-colors"
              >Тарифы</a
            >
            <a href="#" class="text-gray-600 hover:text-gray-900 font-medium transition-colors"
              >Помощь</a
            >
            <a href="#" class="text-gray-600 hover:text-gray-900 font-medium transition-colors"
              >Отзывы</a
            >
          </nav>

          <!-- Actions -->
          <div class="flex items-center space-x-1 sm:space-x-3">
            <!-- Contact info - скрываем на мобильных и планшетах -->
            <div class="hidden lg:flex items-center space-x-4">
              <div class="w-5 h-5 text-gray-600">
                <svg fill="currentColor" viewBox="0 0 20 20">
                  <path
                    d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z"
                  />
                  <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" />
                </svg>
              </div>
              <span class="text-gray-600 font-medium">+373 699 9 999</span>
            </div>

            <template v-if="!authStore.isAuthenticated">
              <button @click="handleLogin" class="btn-outline text-xs sm:text-sm px-2 py-2">
                Войти
              </button>
              <button @click="handleRegister" class="btn-primary text-xs sm:text-sm px-2 py-2">
                Регистрация
              </button>
            </template>
            <template v-else>
              <button @click="handleDashboard" class="btn-primary text-xs sm:text-sm px-2 py-2">
                {{ getDashboardButtonText() }}
              </button>
              <button @click="handleLogout" class="btn-outline text-xs sm:text-sm px-2 py-2">
                Выйти
              </button>
            </template>
          </div>
        </div>
      </div>
    </header>

    <!-- Hero Section -->
    <section
      class="bg-gradient-to-r from-gray-900 via-gray-800 to-gray-900 relative overflow-hidden"
    >
      <div class="absolute inset-0 bg-black opacity-20"></div>
      <div class="relative max-w-7xl mx-auto px-6 py-20">
        <div class="flex items-center justify-between">
          <div class="max-w-2xl">
            <div
              class="inline-flex items-center px-4 py-2 rounded-full bg-lime-500 bg-opacity-20 text-lime-300 text-sm font-semibold mb-8"
            >
              <div class="w-2 h-2 bg-lime-400 rounded-full mr-2 animate-pulse"></div>
              Бесплатный сервис для мастеров и клиентов
            </div>
            <h2 class="text-5xl md:text-6xl font-bold text-white mb-8 leading-tight">
              Управление записями
              <span class="block text-lime-400">стало проще</span>
            </h2>
            <p class="text-xl text-gray-300 mb-12 leading-relaxed">
              Мастерам: полный контроль над расписанием и клиентской базой в одном месте.<br />
              Клиентам: быстрая и удобная запись к любимому мастеру в любое время.
            </p>
            <button
              v-if="!authStore.isAuthenticated"
              @click="handleStartFree"
              class="btn-primary px-8 py-4 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
            >
              Начать бесплатно
            </button>
            <button
              v-else
              @click="handleDashboard"
              class="btn-primary px-8 py-4 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
            >
              {{ getDashboardButtonText() }}
            </button>
          </div>
          <div class="hidden lg:block">
            <div class="relative">
              <div class="w-96 h-64 bg-white rounded-2xl shadow-2xl p-6">
                <div class="flex items-center justify-between mb-4">
                  <h3 class="text-lg font-bold text-gray-900">Расписание</h3>
                  <div class="flex space-x-2">
                    <div class="w-3 h-3 bg-lime-500 rounded-full"></div>
                    <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
                    <div class="w-3 h-3 bg-purple-500 rounded-full"></div>
                  </div>
                </div>
                <div class="grid grid-cols-7 gap-2">
                  <div class="text-xs text-gray-500 text-center">Пн</div>
                  <div class="text-xs text-gray-500 text-center">Вт</div>
                  <div class="text-xs text-gray-500 text-center">Ср</div>
                  <div class="text-xs text-gray-500 text-center">Чт</div>
                  <div class="text-xs text-gray-500 text-center">Пт</div>
                  <div class="text-xs text-gray-500 text-center">Сб</div>
                  <div class="text-xs text-gray-500 text-center">Вс</div>
                  <div class="h-8 bg-gray-100 rounded"></div>
                  <div class="h-8 bg-lime-100 rounded"></div>
                  <div class="h-8 bg-blue-100 rounded"></div>
                  <div class="h-8 bg-purple-100 rounded"></div>
                  <div class="h-8 bg-gray-100 rounded"></div>
                  <div class="h-8 bg-lime-100 rounded"></div>
                  <div class="h-8 bg-gray-100 rounded"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Main Content -->
    <section class="py-24 bg-white">
      <div class="max-w-7xl mx-auto px-6">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          <!-- Left Column -->
          <div>
            <h3 class="text-4xl font-bold text-gray-900 mb-6">Сервис для управления записями</h3>
            <p class="text-xl text-gray-600 mb-8">Построй эффективный бизнес с BookMaster!</p>
            <p class="text-lg text-gray-500 mb-8">
              Более 5 000 мастеров доверяют нам управление своими записями
            </p>
            <p class="text-gray-600 leading-relaxed">
              С помощью нашего сервиса вы сможете легко управлять вашими услугами, автоматизировать
              бронирования, контролировать расписание и поддерживать связь с клиентами и
              сотрудниками.
            </p>
          </div>

          <!-- Right Column -->
          <div class="relative">
            <div class="bg-white rounded-2xl shadow-2xl p-8 border border-gray-200">
              <div class="flex items-center justify-between mb-6">
                <h4 class="text-xl font-bold text-gray-900">Панель управления</h4>
                <div class="flex space-x-2">
                  <div class="w-3 h-3 bg-red-500 rounded-full"></div>
                  <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
                  <div class="w-3 h-3 bg-green-500 rounded-full"></div>
                </div>
              </div>

              <!-- Dashboard Mockup -->
              <div class="space-y-4">
                <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div class="flex items-center space-x-3">
                    <div
                      class="w-10 h-10 bg-lime-500 rounded-full flex items-center justify-center"
                    >
                      <UserCheck class="w-5 h-5 text-white" />
                    </div>
                    <div>
                      <div class="font-semibold text-gray-900">Новые записи</div>
                      <div class="text-sm text-gray-500">3 записи сегодня</div>
                    </div>
                  </div>
                  <div class="text-lime-600 font-bold">+12%</div>
                </div>

                <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div class="flex items-center space-x-3">
                    <div
                      class="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center"
                    >
                      <Calendar class="w-5 h-5 text-white" />
                    </div>
                    <div>
                      <div class="font-semibold text-gray-900">Расписание</div>
                      <div class="text-sm text-gray-500">85% заполнено</div>
                    </div>
                  </div>
                  <div class="text-blue-600 font-bold">85%</div>
                </div>

                <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div class="flex items-center space-x-3">
                    <div
                      class="w-10 h-10 bg-purple-500 rounded-full flex items-center justify-center"
                    >
                      <Sparkles class="w-5 h-5 text-white" />
                    </div>
                    <div>
                      <div class="font-semibold text-gray-900">Доход</div>
                      <div class="text-sm text-gray-500">За этот месяц</div>
                    </div>
                  </div>
                  <div class="text-purple-600 font-bold">45,200 MDL</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Features Section -->
    <section class="py-24 bg-gray-50">
      <div class="max-w-7xl mx-auto px-6">
        <div class="text-center mb-16">
          <h3 class="text-3xl font-bold text-gray-900 mb-4">Возможности платформы</h3>
          <p class="text-lg text-gray-600 max-w-2xl mx-auto">
            Все необходимые инструменты для эффективной работы
          </p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 relative">
          <!-- Connecting line -->
          <div
            class="hidden lg:block absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-16 h-0.5 bg-gradient-to-r from-lime-500 to-blue-500"
          ></div>

          <!-- For Masters -->
          <div
            class="group bg-white rounded-2xl p-8 border border-gray-200 hover:border-lime-200 transition-all duration-300 hover:shadow-xl hover:-translate-y-1 relative"
          >
            <div
              class="absolute inset-0 bg-gradient-to-br from-lime-50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-2xl"
            ></div>
            <div class="relative">
              <h4 class="text-2xl font-bold text-gray-900 mb-8">Для мастеров</h4>
              <ul class="text-gray-600 space-y-6">
                <li class="flex items-start group/item">
                  <div
                    class="w-12 h-12 bg-lime-100 rounded-xl flex items-center justify-center mr-4 group-hover/item:bg-lime-200 transition-colors"
                  >
                    <UserCheck
                      class="w-6 h-6 text-lime-600 group-hover/item:scale-110 transition-transform"
                    />
                  </div>
                  <div class="flex-1">
                    <div class="font-semibold text-gray-900 mb-1">Учет клиентов и записей</div>
                    <div class="text-sm text-gray-500">
                      Ведите базу клиентов и историю записей в удобном интерфейсе
                    </div>
                  </div>
                </li>
                <li class="flex items-start group/item">
                  <div
                    class="w-12 h-12 bg-lime-100 rounded-xl flex items-center justify-center mr-4 group-hover/item:bg-lime-200 transition-colors"
                  >
                    <Calendar
                      class="w-6 h-6 text-lime-600 group-hover/item:scale-110 transition-transform"
                    />
                  </div>
                  <div class="flex-1">
                    <div class="font-semibold text-gray-900 mb-1">Управление расписанием</div>
                    <div class="text-sm text-gray-500">
                      Планируйте время и контролируйте загрузку в реальном времени
                    </div>
                  </div>
                </li>
                <li class="flex items-start group/item">
                  <div
                    class="w-12 h-12 bg-lime-100 rounded-xl flex items-center justify-center mr-4 group-hover/item:bg-lime-200 transition-colors"
                  >
                    <Sparkles
                      class="w-6 h-6 text-lime-600 group-hover/item:scale-110 transition-transform"
                    />
                  </div>
                  <div class="flex-1">
                    <div class="font-semibold text-gray-900 mb-1">Уведомления о записях</div>
                    <div class="text-sm text-gray-500">
                      Получайте мгновенные уведомления о новых записях
                    </div>
                  </div>
                </li>
              </ul>
            </div>
          </div>

          <!-- For Clients -->
          <div
            class="group bg-white rounded-2xl p-8 border border-gray-200 hover:border-blue-200 transition-all duration-300 hover:shadow-xl hover:-translate-y-1 relative"
          >
            <div
              class="absolute inset-0 bg-gradient-to-br from-blue-50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-2xl"
            ></div>
            <div class="relative">
              <h4 class="text-2xl font-bold text-gray-900 mb-8">Для клиентов</h4>
              <ul class="text-gray-600 space-y-6">
                <li class="flex items-start group/item">
                  <div
                    class="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center mr-4 group-hover/item:bg-blue-200 transition-colors"
                  >
                    <Calendar
                      class="w-6 h-6 text-blue-600 group-hover/item:scale-110 transition-transform"
                    />
                  </div>
                  <div class="flex-1">
                    <div class="font-semibold text-gray-900 mb-1">Запись к мастеру</div>
                    <div class="text-sm text-gray-500">
                      Быстрая и удобная запись к любимому мастеру в любое время
                    </div>
                  </div>
                </li>
                <li class="flex items-start group/item">
                  <div
                    class="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center mr-4 group-hover/item:bg-blue-200 transition-colors"
                  >
                    <Footprints
                      class="w-6 h-6 text-blue-600 group-hover/item:scale-110 transition-transform"
                    />
                  </div>
                  <div class="flex-1">
                    <div class="font-semibold text-gray-900 mb-1">История записей</div>
                    <div class="text-sm text-gray-500">
                      Просматривайте все свои записи и отслеживайте прогресс
                    </div>
                  </div>
                </li>
                <li class="flex items-start group/item">
                  <div
                    class="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center mr-4 group-hover/item:bg-blue-200 transition-colors"
                  >
                    <Heart
                      class="w-6 h-6 text-blue-600 group-hover/item:scale-110 transition-transform"
                    />
                  </div>
                  <div class="flex-1">
                    <div class="font-semibold text-gray-900 mb-1">Напоминания</div>
                    <div class="text-sm text-gray-500">
                      Не пропустите важные записи благодаря умным напоминаниям
                    </div>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Services Section -->
    <section class="py-24 bg-white">
      <div class="max-w-7xl mx-auto px-6">
        <div class="text-center mb-16">
          <h3 class="text-3xl font-bold text-gray-900 mb-4">Поддерживаемые услуги</h3>
          <p class="text-lg text-gray-600">Маникюр, педикюр, массаж и многое другое</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <!-- Service 1 -->
          <div
            class="group bg-white rounded-2xl p-8 border border-gray-200 hover:border-pink-200 transition-all duration-300 hover:shadow-lg"
          >
            <div class="text-center">
              <div
                class="w-16 h-16 bg-gradient-to-br from-pink-500 to-pink-600 rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-lg"
              >
                <Sparkles class="w-8 h-8 text-white" />
              </div>
              <h4 class="text-xl font-bold text-gray-900 mb-3">Маникюр</h4>
              <p class="text-gray-600 mb-6">Профессиональный маникюр и уход за руками</p>
              <div
                class="inline-flex items-center text-pink-600 font-semibold group-hover:text-pink-700 transition-colors"
              >
                <span>Подробнее</span>
                <ArrowRight class="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" />
              </div>
            </div>
          </div>

          <!-- Service 2 -->
          <div
            class="group bg-white rounded-2xl p-8 border border-gray-200 hover:border-purple-200 transition-all duration-300 hover:shadow-lg"
          >
            <div class="text-center">
              <div
                class="w-16 h-16 bg-gradient-to-br from-purple-500 to-purple-600 rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-lg"
              >
                <Footprints class="w-8 h-8 text-white" />
              </div>
              <h4 class="text-xl font-bold text-gray-900 mb-3">Педикюр</h4>
              <p class="text-gray-600 mb-6">Уход за ногами и профессиональный педикюр</p>
              <div
                class="inline-flex items-center text-purple-600 font-semibold group-hover:text-purple-700 transition-colors"
              >
                <span>Подробнее</span>
                <ArrowRight class="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" />
              </div>
            </div>
          </div>

          <!-- Service 3 -->
          <div
            class="group bg-white rounded-2xl p-8 border border-gray-200 hover:border-orange-200 transition-all duration-300 hover:shadow-lg"
          >
            <div class="text-center">
              <div
                class="w-16 h-16 bg-gradient-to-br from-orange-500 to-orange-600 rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-lg"
              >
                <Heart class="w-8 h-8 text-white" />
              </div>
              <h4 class="text-xl font-bold text-gray-900 mb-3">Массаж</h4>
              <p class="text-gray-600 mb-6">Расслабляющий и лечебный массаж</p>
              <div
                class="inline-flex items-center text-orange-600 font-semibold group-hover:text-orange-700 transition-colors"
              >
                <span>Подробнее</span>
                <ArrowRight class="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA Section -->
    <section class="py-24 bg-gray-900">
      <div class="max-w-4xl mx-auto px-6 text-center">
        <h3 class="text-3xl font-bold text-white mb-6">Готовы начать?</h3>
        <p class="text-xl text-gray-300 mb-8">
          Присоединяйтесь к тысячам мастеров и клиентов, которые уже используют BookMaster
        </p>
        <div class="flex flex-col sm:flex-row gap-4 justify-center">
          <button
            v-if="!authStore.isAuthenticated"
            @click="handleCreateAccount"
            class="btn-primary px-8 py-4 shadow-lg hover:shadow-xl transform hover:-translate-y-1"
          >
            Создать аккаунт
          </button>
          <button
            v-else
            @click="handleDashboard"
            class="btn-primary px-8 py-4 shadow-lg hover:shadow-xl transform hover:-translate-y-1"
          >
            {{ getDashboardButtonText() }}
          </button>
          <button
            @click="handleContactUs"
            class="btn-outline text-white border-gray-600 hover:border-gray-500 px-8 py-4"
          >
            Связаться с нами
          </button>
        </div>
      </div>
    </section>

    <AppFooter outerClass="py-16" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { UserCheck, Calendar, Sparkles, Footprints, Heart, ArrowRight } from 'lucide-vue-next'
import { useServicesStore } from '../stores/services'
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'
import AppFooter from '../components/AppFooter.vue'

const servicesStore = useServicesStore()
const authStore = useAuthStore()
const router = useRouter()
const loading = ref(false)

onMounted(async () => {
  try {
    loading.value = true

    // Проверяем аутентификацию и перенаправляем на соответствующий дашборд
    if (authStore.token && !authStore.user) {
      try {
        await authStore.getCurrentUser()
      } catch {
        // Если не удалось получить пользователя, очищаем токен
        authStore.logout()
      }
    }

    if (authStore.isAuthenticated && authStore.user) {
      // Перенаправляем на соответствующий дашборд
      if (authStore.user.role === 'master') {
        router.push('/master/dashboard')
        return
      } else if (authStore.user.role === 'client') {
        router.push('/client/dashboard')
        return
      } else if (authStore.user.role === 'admin') {
        router.push('/admin')
        return
      }
    }

    await servicesStore.fetchServices()
  } catch (error) {
    console.error('Failed to load services:', error)
  } finally {
    loading.value = false
  }
})

// Простые функции для кнопок
const handleLogin = () => {
  router.push('/login')
}

const handleRegister = () => {
  router.push('/register')
}

const handleStartFree = () => {
  router.push('/register')
}

const handleCreateAccount = () => {
  router.push('/register')
}

const handleContactUs = () => {
  import('../composables/useToast').then(({ useToast }) =>
    useToast().show('Свяжитесь с нами: +373 699 9 999'),
  )
}

// Функции для аутентифицированных пользователей
const handleDashboard = () => {
  if (authStore.user?.role === 'master') {
    router.push('/master/dashboard')
  } else if (authStore.user?.role === 'client') {
    router.push('/client/dashboard')
  } else if (authStore.user?.role === 'admin') {
    router.push('/admin')
  }
}

const handleLogout = async () => {
  await authStore.logout()
  router.push('/')
}

const getDashboardButtonText = () => {
  if (authStore.user?.role === 'master') {
    return 'Кабинет мастера'
  } else if (authStore.user?.role === 'client') {
    return 'Мои записи'
  } else if (authStore.user?.role === 'admin') {
    return 'Админ панель'
  }
  return 'Личный кабинет'
}
</script>

<style scoped>
.bg-grid-pattern {
  background-image:
    linear-gradient(rgba(0, 0, 0, 0.1) 1px, transparent 1px),
    linear-gradient(90deg, rgba(0, 0, 0, 0.1) 1px, transparent 1px);
  background-size: 20px 20px;
}
</style>
