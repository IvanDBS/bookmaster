import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import HomeView from '../views/HomeView.vue'
import LoginView from '../views/LoginView.vue'
import RegisterView from '../views/RegisterView.vue'
import ClientDashboard from '../views/ClientDashboard.vue'
import MasterDashboard from '../views/MasterDashboard.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
      meta: { requiresGuest: true }
    },
    {
      path: '/register',
      name: 'register',
      component: RegisterView,
      meta: { requiresGuest: true }
    },
    {
      path: '/client/dashboard',
      name: 'client-dashboard',
      component: ClientDashboard,
      meta: { requiresAuth: true, role: 'client' }
    },
    {
      path: '/master/dashboard',
      name: 'master-dashboard',
      component: MasterDashboard,
      meta: { requiresAuth: true, role: 'master' }
    }
  ]
})

// Navigation Guards
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  
  // Проверка для страниц, требующих аутентификации
  if (to.meta.requiresAuth) {
    if (!authStore.isAuthenticated) {
      next('/login')
      return
    }
    
    // Проверка роли пользователя
    if (to.meta.role && authStore.user?.role !== to.meta.role) {
      // Перенаправляем на правильный дашборд в зависимости от роли
      if (authStore.user?.role === 'master') {
        next('/master/dashboard')
      } else if (authStore.user?.role === 'client') {
        next('/client/dashboard')
      } else {
        next('/login')
      }
      return
    }
  }
  
  // Проверка для страниц, доступных только неавторизованным пользователям
  if (to.meta.requiresGuest && authStore.isAuthenticated) {
    // Перенаправляем на дашборд в зависимости от роли
    if (authStore.user?.role === 'master') {
      next('/master/dashboard')
    } else if (authStore.user?.role === 'client') {
      next('/client/dashboard')
    } else {
      next('/')
    }
    return
  }
  
  next()
})

export default router
