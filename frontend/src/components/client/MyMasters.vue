<template>
  <div id="masters" class="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
    <div class="px-6 py-4 border-b border-gray-200">
      <h3 class="text-lg font-semibold text-gray-900">Мои мастера</h3>
    </div>
    <div class="p-6">
      <div v-if="masters.length === 0" class="text-center py-8">
        <p class="text-gray-500">У вас пока нет мастеров</p>
      </div>
      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="master in masters"
          :key="master.id"
          class="group bg-white rounded-xl shadow-sm hover:shadow-lg transition-all duration-300 border border-gray-100 p-6"
        >
          <div class="flex items-center space-x-4 mb-5">
            <div
              class="w-14 h-14 bg-gray-100 rounded-xl flex items-center justify-center border border-gray-200 group-hover:border-gray-300 transition-colors duration-300"
            >
              <span class="text-gray-600 font-semibold text-lg"
                >{{ master.first_name[0] }}{{ master.last_name[0] }}</span
              >
            </div>
            <div class="flex-1">
              <h4 class="font-semibold text-gray-900 text-lg mb-1">
                {{ master.first_name }} {{ master.last_name }}
              </h4>
              <p class="text-gray-500 text-sm">Мастер</p>
            </div>
          </div>

          <button
            @click="$emit('select-master', master)"
            class="w-full bg-green-50 hover:bg-green-100 text-green-700 hover:text-green-800 font-medium px-4 py-3 rounded-lg transition-all duration-300 text-sm border-2 border-green-200 hover:border-green-300 hover:shadow-sm"
          >
            Записаться
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({ masters: { type: Array, default: () => [] } })
defineEmits(['select-master'])
</script>
