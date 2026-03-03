<script setup>
import { ref, computed } from 'vue';

const props = defineProps({
  searchQuery: {
    type: String,
    default: ''
  }
});

const emit = defineEmits(['open-from-history']);

const historyItems = ref([]);

const filteredHistoryItems = computed(() => {
  if (!props.searchQuery) return historyItems.value;
  
  const query = props.searchQuery.toLowerCase();
  return historyItems.value.filter(item => 
    item.url.toLowerCase().includes(query) ||
    item.method.toLowerCase().includes(query)
  );
});

const getMethodColor = (method) => {
  const colors = {
    'GET': 'text-green-600 dark:text-green-400',
    'POST': 'text-blue-600 dark:text-blue-400',
    'PUT': 'text-yellow-600 dark:text-yellow-400',
    'DELETE': 'text-red-600 dark:text-red-400',
    'PATCH': 'text-purple-600 dark:text-purple-400',
  };
  return colors[method] || 'text-surface-600';
};

const getStatusColor = (status) => {
  if (status >= 200 && status < 300) return 'text-green-600 dark:text-green-400';
  if (status >= 400) return 'text-red-600 dark:text-red-400';
  return 'text-yellow-600 dark:text-yellow-400';
};

const addToHistory = (log) => {
  const historyItem = {
    id: log.id,
    method: log.method,
    url: log.url,
    status: log.status,
    time: new Date(log.endTime).toLocaleString('zh-CN'),
    requestData: {
      method: log.method,
      url: log.url,
      headers: log.requestHeaders || {},
      body: log.requestBody || null
    }
  };
  
  historyItems.value.unshift(historyItem);
  if (historyItems.value.length > 50) {
    historyItems.value.pop();
  }
};

const openFromHistory = (historyItem) => {
  emit('open-from-history', historyItem);
};

const clearHistory = () => {
  historyItems.value = [];
};

defineExpose({
  addToHistory,
  clearHistory
});
</script>

<template>
  <div class="p-2">
    <div v-if="filteredHistoryItems.length === 0" class="text-surface-500 dark:text-surface-400 text-xs text-center py-4">
      {{ searchQuery ? '未找到匹配的历史记录' : '暂无历史记录' }}
    </div>
    <div 
      v-for="item in filteredHistoryItems" 
      :key="item.id"
      @dblclick="openFromHistory(item)"
      class="p-2 mb-1 rounded hover:bg-surface-100 dark:hover:bg-surface-800 cursor-pointer transition"
    >
      <div class="flex items-center gap-2 mb-1">
        <span :class="['text-xs font-semibold', getMethodColor(item.method)]">
          {{ item.method }}
        </span>
        <span :class="['text-xs', getStatusColor(item.status)]">
          {{ item.status }}
        </span>
      </div>
      <div class="text-xs text-surface-700 dark:text-surface-300 truncate mb-1">
        {{ item.url }}
      </div>
      <div class="text-xs text-surface-500 dark:text-surface-400">
        {{ item.time }}
      </div>
    </div>
  </div>
</template>