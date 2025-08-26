<template>
  <div class="mt-6 bg-gray-50 rounded-lg p-4">
    <h5 class="font-semibold text-gray-900 mb-3">Обозначения загруженности</h5>
    <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
      <div class="flex items-center space-x-2">
        <div class="w-4 h-4 bg-gray-100 border border-gray-300 rounded"></div>
        <span class="text-gray-700">Выходной</span>
      </div>
      <div class="flex items-center space-x-2">
        <div class="w-4 h-4 bg-green-50 border border-green-300 rounded"></div>
        <span class="text-gray-700">Свободный день</span>
      </div>
      <div class="flex items-center space-x-2">
        <div class="w-4 h-4 bg-orange-100 border border-orange-300 rounded"></div>
        <span class="text-gray-700">Есть записи</span>
      </div>
      <div class="flex items-center space-x-2">
        <div class="w-4 h-4 bg-red-100 border border-red-300 rounded"></div>
        <span class="text-gray-700">Мест нет</span>
      </div>
    </div>
  </div>
</template>

<script setup>
// Этот компонент не требует дополнительной логики
</script>
