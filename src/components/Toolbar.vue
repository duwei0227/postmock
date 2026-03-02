<script setup>
const emit = defineEmits(['new-request']);

const handleNewRequest = () => {
  emit('new-request');
};
</script>

<template>
  <div class="toolbar bg-surface-100 dark:bg-surface-800 text-surface-900 dark:text-surface-50 px-4 py-2 border-b border-surface-200 dark:border-surface-700 flex items-center gap-2">
    <button 
      @click="handleNewRequest"
      class="px-3 py-1.5 text-sm bg-primary hover:bg-primary-600 text-primary-contrast rounded transition"
    >
      + New Request
    </button>
  </div>
</template>

<style scoped>
</style>
