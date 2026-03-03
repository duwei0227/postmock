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

const emit = defineEmits(['close', 'add-console-log', 'save-request', 'unsaved-changes']);

const requestsStore = useRequestsStore();
const environmentsStore = useEnvironmentsStore();

const request = ref(null);
const isLoading = ref(true);
const originalRequest = ref(null); // 保存原始请求用于比较
const httpRequestRef = ref(null); // HttpRequest 组件的引用

// Load request from store
onMounted(async () => {
  try {
    const loadedRequest = await requestsStore.loadRequest(props.requestId);
    if (loadedRequest) {
      // 确保 params 和 headers 至少有一个空行
      if (!loadedRequest.params || loadedRequest.params.length === 0) {
        loadedRequest.params = [{ key: '', value: '', enabled: true }];
      } else {
        // 检查最后一行是否为空行
        const lastParam = loadedRequest.params[loadedRequest.params.length - 1];
        if (lastParam.key || lastParam.value) {
          loadedRequest.params.push({ key: '', value: '', enabled: true });
        }
      }
      
      if (!loadedRequest.headers || loadedRequest.headers.length === 0) {
        loadedRequest.headers = [{ key: '', value: '', enabled: true }];
      } else {
        // 检查最后一行是否为空行
        const lastHeader = loadedRequest.headers[loadedRequest.headers.length - 1];
        if (lastHeader.key || lastHeader.value) {
          loadedRequest.headers.push({ key: '', value: '', enabled: true });
        }
      }
      
      // 确保 body 的 formData 和 urlencoded 也有空行
      if (loadedRequest.body) {
        if (!loadedRequest.body.formData || loadedRequest.body.formData.length === 0) {
          loadedRequest.body.formData = [{ key: '', value: '', type: 'text', enabled: true }];
        } else {
          const lastFormData = loadedRequest.body.formData[loadedRequest.body.formData.length - 1];
          if (lastFormData.key || lastFormData.value) {
            loadedRequest.body.formData.push({ key: '', value: '', type: 'text', enabled: true });
          }
        }
        
        if (!loadedRequest.body.urlencoded || loadedRequest.body.urlencoded.length === 0) {
          loadedRequest.body.urlencoded = [{ key: '', value: '', enabled: true }];
        } else {
          const lastUrlencoded = loadedRequest.body.urlencoded[loadedRequest.body.urlencoded.length - 1];
          if (lastUrlencoded.key || lastUrlencoded.value) {
            loadedRequest.body.urlencoded.push({ key: '', value: '', enabled: true });
          }
        }
      }
      
      request.value = loadedRequest;
      // 深拷贝保存原始状态（不包括空行，用于变化检测）
      const originalData = JSON.parse(JSON.stringify(loadedRequest));
      originalData.params = originalData.params.filter(p => p.key || p.value);
      originalData.headers = originalData.headers.filter(h => h.key || h.value);
      if (originalData.body) {
        originalData.body.formData = originalData.body.formData.filter(f => f.key || f.value);
        originalData.body.urlencoded = originalData.body.urlencoded.filter(u => u.key || u.value);
      }
      originalRequest.value = originalData;
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

// 监听 store 中的 request 变化（例如从 CollectionsPanel rename）
watch(
  () => requestsStore.requests.get(props.requestId),
  (newRequest) => {
    if (newRequest && request.value) {
      // 只更新名称，不影响其他正在编辑的内容
      if (newRequest.name !== request.value.name) {
        console.log('[HttpRequestWrapper] Request name changed in store, updating:', newRequest.name);
        request.value.name = newRequest.name;
        originalRequest.value.name = newRequest.name;
      }
    }
  },
  { deep: true }
);

// 检查请求是否有变化
const hasChanges = (newRequest) => {
  if (!originalRequest.value) return true;
  
  // 比较关键字段
  const original = originalRequest.value;
  
  // 过滤掉空行后再比较
  const newParams = newRequest.params.filter(p => p.key || p.value);
  const newHeaders = newRequest.headers.filter(h => h.key || h.value);
  const originalParams = original.params.filter(p => p.key || p.value);
  const originalHeaders = original.headers.filter(h => h.key || h.value);
  
  let newBody = { ...newRequest.body };
  let originalBody = { ...original.body };
  
  if (newBody.formData) {
    newBody = { ...newBody, formData: newBody.formData.filter(f => f.key || f.value) };
  }
  if (newBody.urlencoded) {
    newBody = { ...newBody, urlencoded: newBody.urlencoded.filter(u => u.key || u.value) };
  }
  if (originalBody.formData) {
    originalBody = { ...originalBody, formData: originalBody.formData.filter(f => f.key || f.value) };
  }
  if (originalBody.urlencoded) {
    originalBody = { ...originalBody, urlencoded: originalBody.urlencoded.filter(u => u.key || u.value) };
  }
  
  return (
    newRequest.name !== original.name ||
    newRequest.method !== original.method ||
    newRequest.url !== original.url ||
    JSON.stringify(newParams) !== JSON.stringify(originalParams) ||
    JSON.stringify(newHeaders) !== JSON.stringify(originalHeaders) ||
    JSON.stringify(newBody) !== JSON.stringify(originalBody) ||
    JSON.stringify(newRequest.auth) !== JSON.stringify(original.auth) ||
    JSON.stringify(newRequest.tests) !== JSON.stringify(original.tests)
  );
};

// 暴露 hasChanges 方法供父组件使用
const hasUnsavedChanges = () => {
  return request.value ? hasChanges(request.value) : false;
};

// 暴露保存方法供父组件调用
const saveCurrentRequest = async () => {
  if (!request.value) return;
  
  try {
    // 如果请求有 collectionId，直接保存
    if (request.value.collectionId) {
      const requestToSave = {
        ...request.value,
        params: request.value.params.filter(p => p.key || p.value),
        headers: request.value.headers.filter(h => h.key || h.value),
        body: {
          ...request.value.body,
          formData: request.value.body.formData.filter(f => f.key || f.value),
          urlencoded: request.value.body.urlencoded.filter(u => u.key || u.value)
        },
        updatedAt: new Date().toISOString()
      };
      
      await requestsStore.saveRequest(requestToSave);
      
      // 更新原始请求状态
      originalRequest.value = JSON.parse(JSON.stringify(request.value));
      if (originalRequest.value.params) {
        originalRequest.value.params = originalRequest.value.params.filter(p => p.key || p.value);
      }
      if (originalRequest.value.headers) {
        originalRequest.value.headers = originalRequest.value.headers.filter(h => h.key || h.value);
      }
      if (originalRequest.value.body) {
        if (originalRequest.value.body.formData) {
          originalRequest.value.body.formData = originalRequest.value.body.formData.filter(f => f.key || f.value);
        }
        if (originalRequest.value.body.urlencoded) {
          originalRequest.value.body.urlencoded = originalRequest.value.body.urlencoded.filter(u => u.key || u.value);
        }
      }
      
      // 通知父组件变化已保存
      emit('unsaved-changes', false);
      
      if (window.$toast) {
        window.$toast.add({
          severity: 'success',
          summary: 'Saved',
          detail: 'Request saved successfully',
          life: 2000
        });
      }
    } else {
      // 没有 collectionId，需要用户选择保存位置
      if (window.$toast) {
        window.$toast.add({
          severity: 'warn',
          summary: 'Cannot Save',
          detail: 'Please assign this request to a collection first',
          life: 3000
        });
      }
    }
  } catch (error) {
    console.error('Failed to save request:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to save request',
        life: 3000
      });
    }
  }
};

// 打开保存对话框供父组件调用
const openSaveDialog = () => {
  if (httpRequestRef.value && typeof httpRequestRef.value.openSaveDialog === 'function') {
    httpRequestRef.value.openSaveDialog();
  }
};

defineExpose({
  hasUnsavedChanges,
  saveCurrentRequest,
  openSaveDialog
});

// Debounced save function - 移除自动保存，只在用户明确保存时才持久化
// const debouncedSave = debounce(async (updatedRequest) => {
//   // 只有在有变化时才保存
//   if (!hasChanges(updatedRequest)) {
//     console.log('[HttpRequestWrapper] No changes detected, skipping save');
//     return;
//   }
//   
//   try {
//     await requestsStore.saveRequest(updatedRequest);
//     // 更新原始请求状态
//     originalRequest.value = JSON.parse(JSON.stringify(updatedRequest));
//     // 过滤掉空行
//     if (originalRequest.value.params) {
//       originalRequest.value.params = originalRequest.value.params.filter(p => p.key || p.value);
//     }
//     if (originalRequest.value.headers) {
//       originalRequest.value.headers = originalRequest.value.headers.filter(h => h.key || h.value);
//     }
//     if (originalRequest.value.body) {
//       if (originalRequest.value.body.formData) {
//         originalRequest.value.body.formData = originalRequest.value.body.formData.filter(f => f.key || f.value);
//       }
//       if (originalRequest.value.body.urlencoded) {
//         originalRequest.value.body.urlencoded = originalRequest.value.body.urlencoded.filter(u => u.key || u.value);
//       }
//     }
//     
//     console.log('[HttpRequestWrapper] Request saved successfully');
//     
//     // 通知父组件变化已保存
//     emit('unsaved-changes', false);
//   } catch (error) {
//     console.error('Failed to save request:', error);
//   }
// }, 1000);

// Watch for changes and auto-save
const handleRequestUpdate = (updatedRequest) => {
  request.value = updatedRequest;
  
  // 检查是否有变化并通知父组件
  const hasChangesNow = hasChanges(updatedRequest);
  emit('unsaved-changes', hasChangesNow);
  
  // 不再自动保存，只更新缓存
  // debouncedSave(updatedRequest);
};

const handleClose = () => {
  emit('close');
};

const handleAddConsoleLog = (log) => {
  emit('add-console-log', log);
};

const handleSaveRequest = (saveData) => {
  emit('save-request', saveData);
  // 保存后更新原始请求状态
  if (request.value) {
    originalRequest.value = JSON.parse(JSON.stringify(request.value));
    // 过滤掉空行用于比较
    if (originalRequest.value.params) {
      originalRequest.value.params = originalRequest.value.params.filter(p => p.key || p.value);
    }
    if (originalRequest.value.headers) {
      originalRequest.value.headers = originalRequest.value.headers.filter(h => h.key || h.value);
    }
    if (originalRequest.value.body) {
      if (originalRequest.value.body.formData) {
        originalRequest.value.body.formData = originalRequest.value.body.formData.filter(f => f.key || f.value);
      }
      if (originalRequest.value.body.urlencoded) {
        originalRequest.value.body.urlencoded = originalRequest.value.body.urlencoded.filter(u => u.key || u.value);
      }
    }
  }
  // 保存后清除未保存状态
  emit('unsaved-changes', false);
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
    ref="httpRequestRef"
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
