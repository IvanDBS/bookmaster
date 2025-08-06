import { createRouter, createWebHistory } from 'vue-router'
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
      component: LoginView
    },
    {
      path: '/register',
      name: 'register',
      component: RegisterView
    },
    {
      path: '/client/dashboard',
      name: 'client-dashboard',
      component: ClientDashboard
    },
    {
      path: '/master/dashboard',
      name: 'master-dashboard',
      component: MasterDashboard
    }
  ]
})

export default router
