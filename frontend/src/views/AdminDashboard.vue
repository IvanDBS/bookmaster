<template>
  <div class="min-h-screen bg-gray-50">
    <div class="max-w-7xl mx-auto p-6">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
        <button
          @click="handleLogout"
          class="px-4 py-2 bg-gray-800 hover:bg-gray-900 text-white text-sm rounded-md"
        >
          Выйти
        </button>
      </div>

      <div class="grid grid-cols-1 gap-6">
        <!-- Users Management -->
        <section class="bg-white rounded-lg shadow-sm border border-gray-200">
          <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h2 class="text-lg font-semibold text-gray-900">Пользователи</h2>
            <div class="flex items-center space-x-2">
              <input
                v-model="query"
                @keyup.enter="loadUsers(1)"
                type="text"
                placeholder="Поиск email/имени"
                class="px-3 py-2 border rounded-md text-sm"
              />
              <button
                @click="loadUsers(1)"
                class="px-3 py-2 bg-lime-600 hover:bg-lime-700 text-white text-sm rounded-md"
              >
                Найти
              </button>
            </div>
          </div>
          <div class="p-6">
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead>
                  <tr
                    class="bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    <th class="px-4 py-3">ID</th>
                    <th class="px-4 py-3">Email</th>
                    <th class="px-4 py-3">Имя</th>
                    <th class="px-4 py-3">Телефон</th>
                    <th class="px-4 py-3">Роль</th>
                    <th class="px-4 py-3">Действия</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200 bg-white">
                  <tr v-for="u in users" :key="u.id">
                    <td class="px-4 py-2 text-sm text-gray-700">{{ u.id }}</td>
                    <td class="px-4 py-2 text-sm text-gray-700">{{ u.email }}</td>
                    <td class="px-4 py-2 text-sm text-gray-700">
                      <div class="flex space-x-2">
                        <input
                          v-model="u.first_name"
                          class="border rounded px-2 py-1 text-sm w-28"
                          placeholder="Имя"
                        />
                        <input
                          v-model="u.last_name"
                          class="border rounded px-2 py-1 text-sm w-32"
                          placeholder="Фамилия"
                        />
                      </div>
                    </td>
                    <td class="px-4 py-2 text-sm text-gray-700">
                      <input
                        v-model="u.phone"
                        class="border rounded px-2 py-1 text-sm w-40"
                        placeholder="Телефон"
                      />
                    </td>
                    <td class="px-4 py-2 text-sm text-gray-700">
                      <select v-model="u.role" class="border rounded px-2 py-1 text-sm">
                        <option value="client">client</option>
                        <option value="master">master</option>
                        <option value="admin">admin</option>
                      </select>
                    </td>
                    <td class="px-4 py-2 text-sm">
                      <button
                        @click="saveUser(u)"
                        class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded mr-2"
                      >
                        Сохранить
                      </button>
                      <button
                        @click="removeUser(u)"
                        class="px-3 py-1 bg-red-600 hover:bg-red-700 text-white rounded"
                      >
                        Удалить
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div class="mt-4 flex items-center justify-between">
              <div class="text-sm text-gray-500">Всего: {{ meta.total }}</div>
              <div class="space-x-2">
                <button
                  :disabled="page <= 1"
                  @click="loadUsers(page - 1)"
                  class="px-3 py-1 border rounded"
                >
                  Назад
                </button>
                <button
                  :disabled="page * perPage >= meta.total"
                  @click="loadUsers(page + 1)"
                  class="px-3 py-1 border rounded"
                >
                  Вперед
                </button>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../services/api'
import { useToast } from '../composables/useToast'
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'

const auth = useAuthStore()
const router = useRouter()
const users = ref([])
const meta = ref({ total: 0 })
const page = ref(1)
const perPage = ref(20)
const query = ref('')
const { show: toast } = useToast()

const loadUsers = async (p = 1) => {
  page.value = p
  const data = await api.adminListUsers(
    { page: page.value, per_page: perPage.value, query: query.value },
    auth.token,
  )
  users.value = data.users
  meta.value = data.meta
}

const saveUser = async (u) => {
  try {
    await api.adminUpdateUser(
      u.id,
      { role: u.role, first_name: u.first_name, last_name: u.last_name, phone: u.phone },
      auth.token,
    )
    toast('Изменения сохранены')
  } catch (e) {
    toast(e.message || 'Ошибка сохранения', 'red')
  }
}

const removeUser = async (u) => {
  try {
    if (!confirm(`Удалить пользователя ${u.email}?`)) return
    await api.adminDeleteUser(u.id, auth.token)
    users.value = users.value.filter((x) => x.id !== u.id)
    meta.value.total = Math.max(0, meta.value.total - 1)
    toast('Пользователь удален')
  } catch (e) {
    toast(e.message || 'Ошибка удаления', 'red')
  }
}

onMounted(() => loadUsers())

const handleLogout = async () => {
  await auth.logout()
  router.push('/login')
}
</script>
