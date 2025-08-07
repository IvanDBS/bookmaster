<template>
  <div class="mt-6 bg-gray-50 rounded-lg p-4">
    <h5 class="font-semibold text-gray-900 mb-3">Обозначения загруженности</h5>
    <div class="grid grid-cols-2 md:grid-cols-6 gap-3 text-sm">
      <div class="flex items-center space-x-2">
        <div class="w-4 h-4 bg-gray-100 border border-gray-300 rounded flex items-center justify-center">
          <span class="text-xs text-gray-400">⚫</span>
        </div>
        <span class="text-gray-700">Выходной</span>
      </div>
      <div class="flex items-center space-x-2">
        <div class="w-4 h-4 bg-green-50 border border-green-200 rounded flex items-center justify-center">
          <div class="w-1 h-1 bg-gray-400 rounded-full opacity-0"></div>
        </div>
        <span class="text-gray-700">Свободен</span>
      </div>
      <div class="flex items-center space-x-2">
        <div class="w-4 h-4 bg-lime-50 border border-lime-200 rounded flex items-center justify-center">
          <div class="w-1 h-1 bg-lime-400 rounded-full"></div>
        </div>
        <span class="text-gray-700">1 слот</span>
      </div>
      <div class="flex items-center space-x-2">
        <div class="w-4 h-4 bg-yellow-50 border border-yellow-200 rounded flex items-center justify-center">
          <div class="flex space-x-0.5">
            <div class="w-1 h-1 bg-yellow-400 rounded-full"></div>
            <div class="w-1 h-1 bg-yellow-400 rounded-full"></div>
          </div>
        </div>
        <span class="text-gray-700">2-3 слота</span>
      </div>
      <div class="flex items-center space-x-2">
        <div class="w-4 h-4 bg-orange-50 border border-orange-200 rounded flex items-center justify-center">
          <div class="flex space-x-0.5">
            <div class="w-1 h-1 bg-orange-400 rounded-full"></div>
            <div class="w-1 h-1 bg-orange-400 rounded-full"></div>
            <div class="w-1 h-1 bg-orange-400 rounded-full"></div>
          </div>
        </div>
        <span class="text-gray-700">4-5 слотов</span>
      </div>
      <div class="flex items-center space-x-2">
        <div class="w-4 h-4 bg-red-50 border border-red-200 rounded flex items-center justify-center">
          <div class="flex space-x-0.5">
            <div class="w-1 h-1 bg-red-400 rounded-full"></div>
            <div class="w-1 h-1 bg-red-400 rounded-full"></div>
            <div class="w-1 h-1 bg-red-400 rounded-full"></div>
            <div class="w-1 h-1 bg-red-400 rounded-full"></div>
          </div>
        </div>
        <span class="text-gray-700">6+ слотов</span>
      </div>
    </div>
  </div>
</template>

<script setup>
// Этот компонент не требует дополнительной логики
</script> 