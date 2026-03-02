<script setup>
import { ref, watch, onMounted } from 'vue';
import { useRequestsStore } from '@/stores/requests';
import { useEnvironmentsStore } from '@/stores/environments';
import { debounce } from '@/utils/debounce';
import HttpRequest from './HttpRequest.vue';

const props = defineProps({
  requestId: {
    type: String,
    required: true
  },
  environmentManager: {
    type: Object,
    default: null
  },
  collections: {
    type: Array,
    default: () => []
  }
});

const emit = defineEmits(['close', 'add-console-log', 'save-request']);

const requestsStore = useRequestsStore();
const environmentsStore = useEnvironmentsStore();

const request = ref(null);
const isLoading = ref(true);
const originalRequest = ref(null); // 保存原始请求用于比较

// Load request from store
onMounted(async () => {
  try {
    const loadedRequest = await requestsStore.loadRequest(props.requestId);
    if (loadedRequest) {
      request.value = loadedRequest;
      // 深拷贝保存原始状态
      originalRequest.value = JSON.parse(JSON.stringify(loadedRequest));
    } else {
      console.error('Request not found:', props.requestId);
      if (window.$toast) {
        window.$toast.add({
          severity: 'error',
          summary: 'Error',
          detail: 'Request not found',
          life: 3000
        });
      }
    }
  } catch (error) {
    console.error('Failed to load request:', error);
  } finally {
    isLoading.value = false;
  }
});

// 检查请求是否有变化
const hasChanges = (newRequest) => {
  if (!originalRequest.value) return true;
  
  // 比较关键字段
  const original = originalRequest.value;
  
  return (
    newRequest.name !== original.name ||
    newRequest.method !== original.method ||
    newRequest.url !== original.url ||
    JSON.stringify(newRequest.params) !== JSON.stringify(original.params) ||
    JSON.stringify(newRequest.headers) !== JSON.stringify(original.headers) ||
    JSON.stringify(newRequest.body) !== JSON.stringify(original.body) ||
    JSON.stringify(newRequest.auth) !== JSON.stringify(original.auth) ||
    JSON.stringify(newRequest.tests) !== JSON.stringify(original.tests)
  );
};

// Debounced save function
const debouncedSave = debounce(async (updatedRequest) => {
  // 只有在有变化时才保存
  if (!hasChanges(updatedRequest)) {
    console.log('[HttpRequestWrapper] No changes detected, skipping save');
    return;
  }
  
  try {
    await requestsStore.saveRequest(updatedRequest);
    // 更新原始请求状态
    originalRequest.value = JSON.parse(JSON.stringify(updatedRequest));
    console.log('[HttpRequestWrapper] Request saved successfully');
  } catch (error) {
    console.error('Failed to save request:', error);
  }
}, 1000);

// Watch for changes and auto-save
const handleRequestUpdate = (updatedRequest) => {
  request.value = updatedRequest;
  debouncedSave(updatedRequest);
};

const handleClose = () => {
  emit('close');
};

const handleAddConsoleLog = (log) => {
  emit('add-console-log', log);
};

const handleSaveRequest = (saveData) => {
  emit('save-request', saveData);
};
</script>

<template>
  <div v-if="isLoading" class="flex items-center justify-center h-full">
    <div class="text-center">
      <i class="pi pi-spin pi-spinner text-4xl text-surface-400 mb-2"></i>
      <p class="text-sm text-surface-500">Loading request...</p>
    </div>
  </div>
  
  <HttpRequest
    v-else-if="request"
    :request="request"
    :environmentManager="environmentManager"
    :collections="collections"
    @update:request="handleRequestUpdate"
    @close="handleClose"
    @add-console-log="handleAddConsoleLog"
    @save-request="handleSaveRequest"
  />
  
  <div v-else class="flex items-center justify-center h-full">
    <div class="text-center">
      <i class="pi pi-exclamation-triangle text-4xl text-red-400 mb-2"></i>
      <p class="text-sm text-surface-500">Request not found</p>
    </div>
  </div>
</template>
