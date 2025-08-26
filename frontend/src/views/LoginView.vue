<template>
  <div class="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="flex justify-center">
        <div class="flex space-x-1">
          <div class="w-3 h-3 rounded-full" style="background-color: var(--brand-blue)"></div>
          <div class="w-3 h-3 rounded-full" style="background-color: var(--brand-yellow)"></div>
          <div class="w-3 h-3 rounded-full" style="background-color: var(--brand-red)"></div>
        </div>
      </div>
      <h2 class="mt-6 text-center text-3xl font-bold text-gray-900">Войти в аккаунт</h2>
      <p class="mt-2 text-center text-sm text-gray-600">
        Или
        <router-link to="/register" class="font-medium text-lime-600 hover:text-lime-500">
          создайте новый аккаунт
        </router-link>
      </p>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
        <form class="space-y-6" @submit.prevent="handleSubmit">
          <div>
            <label for="email" class="block text-sm font-medium text-gray-700"> Email </label>
            <div class="mt-1">
              <input
                id="email"
                v-model="form.email"
                name="email"
                type="email"
                autocomplete="email"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-lime-500 focus:border-lime-500"
                placeholder="your@email.com"
              />
            </div>
          </div>

          <div>
            <label for="password" class="block text-sm font-medium text-gray-700"> Пароль </label>
            <div class="mt-1">
              <input
                id="password"
                v-model="form.password"
                name="password"
                type="password"
                autocomplete="current-password"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-lime-500 focus:border-lime-500"
                placeholder="••••••••"
              />
            </div>
          </div>

          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <input
                id="remember-me"
                name="remember-me"
                type="checkbox"
                v-model="form.rememberMe"
                class="h-4 w-4 text-lime-600 focus:ring-lime-500 border-gray-300 rounded"
              />
              <label for="remember-me" class="ml-2 block text-sm text-gray-900">
                Запомнить меня
              </label>
            </div>

            <div class="text-sm">
              <a href="#" class="font-medium text-lime-600 hover:text-lime-500"> Забыли пароль? </a>
            </div>
          </div>

          <div>
            <button
              type="submit"
              :disabled="loading"
              class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-lime-600 hover:bg-lime-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-lime-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span v-if="loading">Вход...</span>
              <span v-else>Войти</span>
            </button>
          </div>

          <div class="relative">
            <div class="my-4 flex items-center">
              <div class="flex-grow border-t border-gray-200"></div>
              <span class="mx-4 text-gray-400 text-xs">или</span>
              <div class="flex-grow border-t border-gray-200"></div>
            </div>

            <!-- Custom Google button -->
            <button
              type="button"
              @click="handleGoogleLogin"
              :disabled="loadingGoogle"
              class="w-full flex justify-center items-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-lime-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg class="w-5 h-5 mr-2" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                />
                <path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
              <span v-if="loadingGoogle">Вход через Google...</span>
              <span v-else>Войти через Google</span>
            </button>
          </div>

          <div v-if="info" class="bg-green-50 border border-green-200 rounded-md p-4 mb-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg class="h-5 w-5 text-green-500" viewBox="0 0 20 20" fill="currentColor">
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414L9 13.414l4.707-4.707z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-green-800">{{ info }}</h3>
              </div>
            </div>
          </div>

          <div v-if="error" class="bg-red-50 border border-red-200 rounded-md p-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-red-800">Ошибка входа</h3>
                <div class="mt-2 text-sm text-red-700">
                  {{ error }}
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'
import api from '../services/api'

const authStore = useAuthStore()
const router = useRouter()
const loading = ref(false)
const error = ref('')
const loadingGoogle = ref(false)
const info = ref('')

const form = reactive({
  email: '',
  password: '',
  rememberMe: false,
})

const handleSubmit = async () => {
  loading.value = true
  error.value = ''

  try {
    const response = await authStore.login(form.email, form.password)

    // Перенаправляем в зависимости от роли
    if (response.user.role === 'admin') {
      router.push('/admin')
    } else if (response.user.role === 'master') {
      router.push('/master/dashboard')
    } else {
      router.push('/client/dashboard')
    }
  } catch (err) {
    error.value = err.message || 'Ошибка входа. Проверьте email и пароль.'
  } finally {
    loading.value = false
  }
}



const handleGoogleLogin = async () => {
  try {
    loadingGoogle.value = true
    error.value = ''
    
    // Используем прямую OAuth ссылку вместо Google SDK
    const CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID
    if (!CLIENT_ID) {
      throw new Error('VITE_GOOGLE_CLIENT_ID не настроен в переменных окружения')
    }
    
    const redirectUri = encodeURIComponent('http://localhost:3000/api/v1/auth/google_callback')
    const scope = encodeURIComponent('email profile')
    const oauthUrl = `https://accounts.google.com/o/oauth2/auth?client_id=${CLIENT_ID}&redirect_uri=${redirectUri}&scope=${scope}&response_type=code&prompt=select_account`
    
    // Открываем OAuth в новом окне
    const popup = window.open(oauthUrl, 'google_oauth', 'width=500,height=600,scrollbars=yes,resizable=yes')
    
    if (!popup) {
      throw new Error('Браузер заблокировал всплывающее окно. Разрешите всплывающие окна для этого сайта.')
    }
    
    // Слушаем сообщения от popup
    window.addEventListener('message', (event) => {
      if (event.origin !== 'http://localhost:3000') return
      
              if (event.data.type === 'GOOGLE_OAUTH_SUCCESS') {
          popup.close()
          // Обрабатываем успешную авторизацию
          authStore.user = event.data.user
          authStore.token = event.data.token
          // Сохраняем токен в localStorage для API запросов
          localStorage.setItem('token', event.data.token)
        
        if (event.data.user.role === 'admin') {
          router.push('/admin')
        } else if (event.data.user.role === 'master') {
          router.push('/master/dashboard')
        } else {
          router.push('/client/dashboard')
        }
      } else if (event.data.type === 'GOOGLE_OAUTH_ERROR') {
        popup.close()
        error.value = event.data.error || 'Ошибка входа через Google'
      }
    })
    
  } catch (err) {
    error.value = err.message || 'Ошибка входа через Google'
  } finally {
    loadingGoogle.value = false
  }
}

const loadGoogleScript = () =>
  new Promise((resolve, reject) => {
    if (window.google && window.google.accounts && window.google.accounts.id) return resolve()
    const script = document.createElement('script')
    script.src = 'https://accounts.google.com/gsi/client'
    script.async = true
    script.defer = true
    script.onload = () => resolve()
    script.onerror = () => reject(new Error('Не удалось загрузить Google SDK'))
    document.head.appendChild(script)
  })

const initGoogleButton = async () => {
  try {
    loadingGoogle.value = true
    await loadGoogleScript()
    const CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID
    if (!CLIENT_ID) {
      throw new Error('VITE_GOOGLE_CLIENT_ID не настроен в переменных окружения')
    }
    console.log('Using Google Client ID from env:', CLIENT_ID)
    window.google.accounts.id.initialize({
      client_id: CLIENT_ID,
      auto_select: false,
      itp_support: false,
      use_fedcm_for_prompt: false,
      use_fedcm_for_button: false,
      disable_fedcm: true,
      auto_prompt: false,
      callback: async (resp) => {
        try {
          error.value = ''
          const result = await api.loginWithGoogle(resp.credential)
          if (!result || !result.user || !result.user.role) {
            throw new Error('Некорректный ответ сервера: отсутствует роль пользователя')
          }
          authStore.user = result.user
          authStore.token = result.token
          localStorage.setItem('token', result.token)
          if (result.user.role === 'admin') {
            router.push('/admin')
          } else if (result.user.role === 'master') {
            router.push('/master/dashboard')
          } else {
            router.push('/client/dashboard')
          }
        } catch (e) {
          error.value = e.message || 'Ошибка входа через Google'
        }
      },
    })
    // Не рендерим кнопку, так как используем кастомную
    // const container = document.getElementById('gsi-button')
    // if (container) {
    //   window.google.accounts.id.renderButton(container, {
    //     theme: 'outline',
    //     size: 'large',
    //     shape: 'rectangular',
    //     text: 'continue_with',
    //     width: 320,
    //   })
    // }
  } catch (e) {
    if (!error.value) error.value = e.message || 'Не удалось инициализировать Google'
  } finally {
    loadingGoogle.value = false
  }
}

// Инициализируем кнопку при загрузке страницы
initGoogleButton()

// Если на странице есть confirmation_token в query — подтверждаем аккаунт
onMounted(async () => {
  try {
    const params = new URLSearchParams(window.location.search)
    const token = params.get('confirmation_token')
    const registered = params.get('registered')
    const email = params.get('email')
    if (token) {
      loading.value = true
      await api.confirmEmail(token)
      // Очистим query-параметры и покажем уведомление
      const url = new URL(window.location.href)
      url.searchParams.delete('confirmation_token')
      window.history.replaceState({}, '', url.toString())
      info.value = 'Email подтвержден. Теперь войдите.'
    } else if (registered === '1') {
      info.value = email
        ? `Мы отправили письмо с подтверждением на ${email}`
        : 'Мы отправили письмо с подтверждением на ваш email'
    }
  } catch (e) {
    error.value = e.message || 'Не удалось подтвердить email'
  } finally {
    loading.value = false
  }
})
</script>
