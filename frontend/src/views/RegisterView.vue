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
      <h2 class="mt-6 text-center text-3xl font-bold text-gray-900">Создать аккаунт</h2>
      <p class="mt-2 text-center text-sm text-gray-600">
        Или
        <router-link to="/login" class="font-medium text-lime-600 hover:text-lime-500">
          войдите в существующий аккаунт
        </router-link>
      </p>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
        <form class="space-y-6" @submit.prevent="handleSubmit">
          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div>
              <label for="first_name" class="block text-sm font-medium text-gray-700"> Имя </label>
              <div class="mt-1">
                <input
                  id="first_name"
                  v-model="form.first_name"
                  name="first_name"
                  type="text"
                  autocomplete="given-name"
                  required
                  class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-lime-500 focus:border-lime-500"
                  placeholder="Иван"
                />
              </div>
            </div>

            <div>
              <label for="last_name" class="block text-sm font-medium text-gray-700">
                Фамилия
              </label>
              <div class="mt-1">
                <input
                  id="last_name"
                  v-model="form.last_name"
                  name="last_name"
                  type="text"
                  autocomplete="family-name"
                  required
                  class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-lime-500 focus:border-lime-500"
                  placeholder="Иванов"
                />
              </div>
            </div>
          </div>

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
            <label for="phone" class="block text-sm font-medium text-gray-700"> Телефон </label>
            <div class="mt-1">
              <input
                id="phone"
                v-model="form.phone"
                name="phone"
                type="tel"
                autocomplete="tel"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-lime-500 focus:border-lime-500"
                placeholder="+7 (999) 123-45-67"
              />
            </div>
          </div>

          <div>
            <label for="role" class="block text-sm font-medium text-gray-700"> Роль </label>
            <div class="mt-1">
              <select
                id="role"
                v-model="form.role"
                name="role"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-lime-500 focus:border-lime-500"
              >
                <option value="">Выберите роль</option>
                <option value="master">Мастер</option>
                <option value="client">Клиент</option>
              </select>
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
                autocomplete="new-password"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-lime-500 focus:border-lime-500"
                placeholder="••••••••"
              />
            </div>
          </div>

          <div>
            <label for="password_confirmation" class="block text-sm font-medium text-gray-700">
              Подтвердите пароль
            </label>
            <div class="mt-1">
              <input
                id="password_confirmation"
                v-model="form.password_confirmation"
                name="password_confirmation"
                type="password"
                autocomplete="new-password"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-lime-500 focus:border-lime-500"
                placeholder="••••••••"
              />
            </div>
          </div>

          <div class="flex items-center">
            <input
              id="terms"
              name="terms"
              type="checkbox"
              v-model="form.terms"
              required
              class="h-4 w-4 text-lime-600 focus:ring-lime-500 border-gray-300 rounded"
            />
            <label for="terms" class="ml-2 block text-sm text-gray-900">
              Я согласен с
              <a href="#" class="font-medium text-lime-600 hover:text-lime-500">
                условиями использования
              </a>
            </label>
          </div>

          <div>
            <button
              type="submit"
              :disabled="loading || !form.terms || form.password !== form.password_confirmation"
              class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-lime-600 hover:bg-lime-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-lime-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span v-if="loading">Регистрация...</span>
              <span v-else>Создать аккаунт</span>
            </button>
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
                <h3 class="text-sm font-medium text-red-800">Ошибка регистрации</h3>
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
import { ref, reactive, computed } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()
const loading = ref(false)
const error = ref('')

const form = reactive({
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  role: '',
  password: '',
  password_confirmation: '',
  terms: false,
})

const isFormValid = computed(() => {
  return (
    form.first_name &&
    form.last_name &&
    form.email &&
    form.phone &&
    form.role &&
    form.password &&
    form.password_confirmation &&
    form.terms &&
    form.password === form.password_confirmation
  )
})

const handleSubmit = async () => {
  if (!isFormValid.value) {
    error.value = 'Пожалуйста, заполните все поля и подтвердите пароль'
    return
  }

  loading.value = true
  error.value = ''

  try {
    await authStore.register(form)
    // Сообщаем о необходимости подтвердить email и ведем на login с подсказкой
    router.push({ path: '/login', query: { registered: '1', email: form.email } })
  } catch (err) {
    error.value = err.message || 'Ошибка регистрации. Попробуйте еще раз.'
  } finally {
    loading.value = false
  }
}
</script>
