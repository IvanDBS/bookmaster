<template>
  <div id="services" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
    <div class="px-6 py-4 border-b border-gray-200">
      <div class="flex justify-between items-center">
        <h3 class="text-lg font-semibold text-gray-900">Мои услуги</h3>
        <button
          @click="showModal = true"
          class="px-3 py-1.5 text-green-600 border border-green-500 hover:bg-green-50 rounded-lg transition-colors text-sm font-medium"
        >
          Добавить услугу
        </button>
      </div>
    </div>
    <div class="p-6">
      <div v-if="services.length === 0" class="text-center py-8">
        <p class="text-gray-500">У вас пока нет услуг</p>
      </div>
      <div v-else class="space-y-4">
        <ServiceCard
          v-for="service in services"
          :key="service.id"
          :service="service"
          @edit-service="editService"
          @delete-service="deleteService"
        />
      </div>
    </div>

    <!-- Service Modal -->
    <ServiceModal
      v-if="showModal"
      :show-modal="showModal"
      :editing-service-id="editingServiceId"
      :new-service="newService"
      :available-service-types="availableServiceTypes"
      @close-modal="closeModal"
      @add-service="addService($event)"
    />
  </div>
</template>

<script setup>
import { useServices } from '../../../composables/useServices'
import ServiceCard from './ServiceCard.vue'
import ServiceModal from './ServiceModal.vue'

// Используем composable
const {
  // State
  services,
  showModal,
  editingServiceId,
  newService,
  availableServiceTypes,

  // Functions
  editService,
  deleteService,
  closeModal,
  addService,
} = useServices()
</script>
