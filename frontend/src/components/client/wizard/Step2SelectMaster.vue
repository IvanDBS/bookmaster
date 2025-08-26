<template>
  <div class="space-y-5">
    <h4 class="text-sm font-semibold text-gray-900">
      Выберите мастера для услуги "{{ selectedServiceType }}"
    </h4>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <button
        v-for="master in masters"
        :key="master.id"
        @click="$emit('select', master)"
        :class="[
          'rounded-xl border-2 p-5 text-left transition-all duration-300 transform hover:scale-105',
          selectedMasterId === master.id
            ? 'border-lime-500 bg-gradient-to-br from-lime-50 to-lime-100 shadow-lg'
            : 'border-gray-200 hover:border-lime-300 hover:shadow-md',
        ]"
      >
        <div class="flex items-center space-x-4">
          <div
            class="w-12 h-12 rounded-full bg-gradient-to-br from-lime-400 to-lime-600 flex items-center justify-center text-white font-bold shadow-md"
          >
            {{ master.user.first_name[0] }}
          </div>
          <div class="flex-1">
            <div class="font-bold text-gray-900 text-lg">
              {{ master.user.first_name }} {{ master.user.last_name }}
            </div>
            <div class="text-sm text-gray-500">{{ master.services.length }} услуг</div>
          </div>
          <div class="text-right">
            <div class="text-sm font-bold text-lime-600">
              от {{ minPrice(master.services) }} MDL
            </div>
          </div>
        </div>
      </button>
    </div>
  </div>
</template>

<script setup>
defineProps({ masters: Array, selectedServiceType: String, selectedMasterId: Number })
defineEmits(['select'])
const minPrice = (services) => Math.min(...services.map((s) => s.price))
</script>
