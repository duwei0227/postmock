<script setup>
import { ref, watch, onMounted } from 'vue';
import { useRequestsStore } from '@/stores/requests';
import { useEnvironmentsStore } from '@/stores/environments';
import { useCollectionsStore } from '@/stores/collections';
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
const collectionsStore = useCollectionsStore();

const request = ref(null);
const isLoading = ref(true);
const originalRequest = ref(null); // 保存原始请求用于比较
const httpRequestRef = ref(null); // HttpRequest 组件的引用

// Load request from store
onMounted(async () => {
  try {
    const loadedRequest = await requestsStore.loadRequest(props.requestId);
    if (loadedRequest) {
      // 立即清除所有临时属性（以 _ 开头的属性），防止被持久化
      const cleanedRequest = { ...loadedRequest };
      Object.keys(cleanedRequest).forEach(key => {
        if (key.startsWith('_')) {
          delete cleanedRequest[key];
        }
      });
      
      // 确保 params 和 headers 至少有一个空行
      // 确保 params 和 headers 至少有一个空行
      if (!cleanedRequest.params || cleanedRequest.params.length === 0) {
        cleanedRequest.params = [{ key: '', value: '', enabled: true }];
      } else {
        // 检查最后一行是否为空行
        const lastParam = cleanedRequest.params[cleanedRequest.params.length - 1];
        if (lastParam.key || lastParam.value) {
          cleanedRequest.params.push({ key: '', value: '', enabled: true });
        }
      }
      
      if (!cleanedRequest.headers || cleanedRequest.headers.length === 0) {
        cleanedRequest.headers = [{ key: '', value: '', enabled: true }];
      } else {
        // 检查最后一行是否为空行
        const lastHeader = cleanedRequest.headers[cleanedRequest.headers.length - 1];
        if (lastHeader.key || lastHeader.value) {
          cleanedRequest.headers.push({ key: '', value: '', enabled: true });
        }
      }
      
      // 确保 body 的 formData 和 urlencoded 也有空行
      if (cleanedRequest.body) {
        if (!cleanedRequest.body.formData || cleanedRequest.body.formData.length === 0) {
          cleanedRequest.body.formData = [{ key: '', value: '', type: 'text', enabled: true }];
        } else {
          const lastFormData = cleanedRequest.body.formData[cleanedRequest.body.formData.length - 1];
          if (lastFormData.key || lastFormData.value) {
            cleanedRequest.body.formData.push({ key: '', value: '', type: 'text', enabled: true });
          }
        }
        
        if (!cleanedRequest.body.urlencoded || cleanedRequest.body.urlencoded.length === 0) {
          cleanedRequest.body.urlencoded = [{ key: '', value: '', enabled: true }];
        } else {
          const lastUrlencoded = cleanedRequest.body.urlencoded[cleanedRequest.body.urlencoded.length - 1];
          if (lastUrlencoded.key || lastUrlencoded.value) {
            cleanedRequest.body.urlencoded.push({ key: '', value: '', enabled: true });
          }
        }
      }
      
      request.value = cleanedRequest;
      
      console.log('[HttpRequestWrapper] Request loaded from cache:');
      console.log('[HttpRequestWrapper] - ID:', cleanedRequest.id);
      console.log('[HttpRequestWrapper] - Name:', cleanedRequest.name);
      console.log('[HttpRequestWrapper] - Method:', cleanedRequest.method);
      console.log('[HttpRequestWrapper] - URL:', cleanedRequest.url);
      console.log('[HttpRequestWrapper] - CollectionId:', cleanedRequest.collectionId);
      
      // 如果请求有 collectionId，从 collection 中加载原始版本用于比较
      if (cleanedRequest.collectionId) {
        try {
          console.log('[HttpRequestWrapper] Request has collectionId:', cleanedRequest.collectionId);
          const collection = collectionsStore.collections.find(c => c.id === cleanedRequest.collectionId);
          console.log('[HttpRequestWrapper] Found collection:', collection ? collection.name : 'null');
          
          if (collection) {
            console.log('[HttpRequestWrapper] Collection requests:', collection.requests);
            console.log('[HttpRequestWrapper] Collection folders:', collection.folders);
            
            // 从 collection 中找到这个请求的引用
            const findRequestInCollection = (folders) => {
              for (const folder of folders) {
                // 在当前文件夹的请求中查找
                const found = folder.requests.find(r => r.id === cleanedRequest.id);
                if (found) return found;
                
                // 递归查找子文件夹
                if (folder.folders && folder.folders.length > 0) {
                  const foundInSubfolder = findRequestInCollection(folder.folders);
                  if (foundInSubfolder) return foundInSubfolder;
                }
              }
              return null;
            };
            
            // 先在 collection 的根级别请求中查找
            let requestRef = collection.requests.find(r => r.id === cleanedRequest.id);
            
            // 如果没找到，在文件夹中递归查找
            if (!requestRef && collection.folders && collection.folders.length > 0) {
              requestRef = findRequestInCollection(collection.folders);
            }
            
            console.log('[HttpRequestWrapper] Found request ref:', requestRef);
            
            // 如果在 collection 中找到了引用，说明这是已保存的版本
            // originalRequest 应该使用 collection 中的元数据（上次保存的版本）
            if (requestRef) {
              console.log('[HttpRequestWrapper] Found request in collection');
              console.log('[HttpRequestWrapper] Collection ref - name:', requestRef.name, 'method:', requestRef.method, 'url:', requestRef.url);
              console.log('[HttpRequestWrapper] Current - name:', cleanedRequest.name, 'method:', cleanedRequest.method, 'url:', cleanedRequest.url);
              
              // 创建原始版本：使用 collection 中的元数据（上次保存时的状态）
              // 其他字段使用缓存中的数据作为基础，但关键字段（name、method、url）使用 collection 中的
              originalRequest.value = {
                ...cleanedRequest,
                name: requestRef.name,
                method: requestRef.method,
                url: requestRef.url,
                params: cleanedRequest.params.filter(p => p.key || p.value),
                headers: cleanedRequest.headers.filter(h => h.key || h.value),
                body: {
                  ...cleanedRequest.body,
                  formData: cleanedRequest.body.formData.filter(f => f.key || f.value),
                  urlencoded: cleanedRequest.body.urlencoded.filter(u => u.key || u.value)
                }
              };
              
              // 注意：这里 cleanedRequest 保持不变，它包含了用户的所有修改
              // originalRequest 只是用于比较，判断是否有未保存的变化
            } else {
              // 没有在 collection 中找到，使用当前版本作为原始版本
              console.log('[HttpRequestWrapper] Request not found in collection, using current as original');
              originalRequest.value = JSON.parse(JSON.stringify(cleanedRequest));
              originalRequest.value.params = originalRequest.value.params.filter(p => p.key || p.value);
              originalRequest.value.headers = originalRequest.value.headers.filter(h => h.key || h.value);
              if (originalRequest.value.body) {
                originalRequest.value.body.formData = originalRequest.value.body.formData.filter(f => f.key || f.value);
                originalRequest.value.body.urlencoded = originalRequest.value.body.urlencoded.filter(u => u.key || u.value);
              }
            }
          } else {
            console.log('[HttpRequestWrapper] Collection not found, using current as original');
            originalRequest.value = JSON.parse(JSON.stringify(cleanedRequest));
            originalRequest.value.params = originalRequest.value.params.filter(p => p.key || p.value);
            originalRequest.value.headers = originalRequest.value.headers.filter(h => h.key || h.value);
            if (originalRequest.value.body) {
              originalRequest.value.body.formData = originalRequest.value.body.formData.filter(f => f.key || f.value);
              originalRequest.value.body.urlencoded = originalRequest.value.body.urlencoded.filter(u => u.key || u.value);
            }
          }
        } catch (error) {
          console.error('[HttpRequestWrapper] Failed to load collection for comparison:', error);
          // 如果加载失败，使用当前版本作为原始版本
          originalRequest.value = JSON.parse(JSON.stringify(cleanedRequest));
          originalRequest.value.params = originalRequest.value.params.filter(p => p.key || p.value);
          originalRequest.value.headers = originalRequest.value.headers.filter(h => h.key || h.value);
          if (originalRequest.value.body) {
            originalRequest.value.body.formData = originalRequest.value.body.formData.filter(f => f.key || f.value);
            originalRequest.value.body.urlencoded = originalRequest.value.body.urlencoded.filter(u => u.key || u.value);
          }
        }
      } else {
        // 没有 collectionId，使用当前版本作为原始版本
        originalRequest.value = JSON.parse(JSON.stringify(cleanedRequest));
        originalRequest.value.params = originalRequest.value.params.filter(p => p.key || p.value);
        originalRequest.value.headers = originalRequest.value.headers.filter(h => h.key || h.value);
        if (originalRequest.value.body) {
          originalRequest.value.body.formData = originalRequest.value.body.formData.filter(f => f.key || f.value);
          originalRequest.value.body.urlencoded = originalRequest.value.body.urlencoded.filter(u => u.key || u.value);
        }
      }
      
      // 检查是否有未保存的变化并通知父组件
      const hasChangesNow = hasChanges(cleanedRequest);
      console.log('[HttpRequestWrapper] Initial hasChanges check:', hasChangesNow);
      if (hasChangesNow) {
        emit('unsaved-changes', true);
      }
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
  if (!originalRequest.value) {
    console.log('[HttpRequestWrapper] No originalRequest, returning true');
    return true;
  }
  
  // 比较关键字段
  const original = originalRequest.value;
  
  console.log('[HttpRequestWrapper] Comparing requests:');
  console.log('[HttpRequestWrapper] Original URL:', original.url);
  console.log('[HttpRequestWrapper] Current URL:', newRequest.url);
  console.log('[HttpRequestWrapper] Original name:', original.name);
  console.log('[HttpRequestWrapper] Current name:', newRequest.name);
  console.log('[HttpRequestWrapper] Original method:', original.method);
  console.log('[HttpRequestWrapper] Current method:', newRequest.method);
  
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
  
  const hasChanges = (
    newRequest.name !== original.name ||
    newRequest.method !== original.method ||
    newRequest.url !== original.url ||
    JSON.stringify(newParams) !== JSON.stringify(originalParams) ||
    JSON.stringify(newHeaders) !== JSON.stringify(originalHeaders) ||
    JSON.stringify(newBody) !== JSON.stringify(originalBody) ||
    JSON.stringify(newRequest.auth) !== JSON.stringify(original.auth) ||
    JSON.stringify(newRequest.tests) !== JSON.stringify(original.tests)
  );
  
  console.log('[HttpRequestWrapper] Has changes:', hasChanges);
  
  return hasChanges;
};

// 暴露 hasChanges 方法供父组件使用
const hasUnsavedChanges = () => {
  return request.value ? hasChanges(request.value) : false;
};

// 恢复到原始版本（用于 Discard）
const restoreOriginalRequest = async () => {
  if (!originalRequest.value || !request.value) return;
  
  console.log('[HttpRequestWrapper] Restoring original request');
  
  // 使用原始版本恢复请求
  const restoredRequest = {
    ...originalRequest.value,
    id: request.value.id,
    collectionId: request.value.collectionId,
    folderId: request.value.folderId,
    // 确保有空行
    params: [...originalRequest.value.params, { key: '', value: '', enabled: true }],
    headers: [...originalRequest.value.headers, { key: '', value: '', enabled: true }],
    body: {
      ...originalRequest.value.body,
      formData: [...originalRequest.value.body.formData, { key: '', value: '', type: 'text', enabled: true }],
      urlencoded: [...originalRequest.value.body.urlencoded, { key: '', value: '', enabled: true }]
    },
    updatedAt: new Date().toISOString()
  };
  
  // 立即保存到缓存，覆盖任何修改
  await requestsStore.saveRequest(restoredRequest);
  
  // 更新本地状态
  request.value = restoredRequest;
  
  console.log('[HttpRequestWrapper] Request restored to original version');
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
  openSaveDialog,
  restoreOriginalRequest
});

// Debounced save function - 自动保存到缓存（不更新 collection）
const debouncedSaveToCache = debounce(async (updatedRequest) => {
  console.log('[HttpRequestWrapper] debouncedSaveToCache called');
  
  // 只有在有变化时才保存
  if (!hasChanges(updatedRequest)) {
    console.log('[HttpRequestWrapper] No changes detected, skipping cache save');
    return;
  }
  
  console.log('[HttpRequestWrapper] Changes detected, saving to cache...');
  
  try {
    // 保存到缓存（内存 + 存储），但不更新 collection 引用
    const requestToSave = {
      ...updatedRequest,
      params: updatedRequest.params.filter(p => p.key || p.value),
      headers: updatedRequest.headers.filter(h => h.key || h.value),
      body: {
        ...updatedRequest.body,
        formData: updatedRequest.body.formData.filter(f => f.key || f.value),
        urlencoded: updatedRequest.body.urlencoded.filter(u => u.key || u.value)
      },
      updatedAt: new Date().toISOString()
    };
    
    console.log('[HttpRequestWrapper] Saving request to cache:', requestToSave.id, 'URL:', requestToSave.url);
    // 使用立即保存，确保数据不会因为 debounce 而丢失
    await requestsStore.saveRequest(requestToSave, true);
    console.log('[HttpRequestWrapper] Request saved to cache successfully');
  } catch (error) {
    console.error('[HttpRequestWrapper] Failed to save request to cache:', error);
  }
}, 1000);

// Watch for changes and auto-save to cache
const handleRequestUpdate = (updatedRequest) => {
  console.log('[HttpRequestWrapper] handleRequestUpdate called, URL:', updatedRequest.url);
  request.value = updatedRequest;
  
  // 检查是否有变化并通知父组件
  const hasChangesNow = hasChanges(updatedRequest);
  console.log('[HttpRequestWrapper] Has changes:', hasChangesNow);
  emit('unsaved-changes', hasChangesNow);
  
  // 自动保存到缓存（不影响 collection）
  debouncedSaveToCache(updatedRequest);
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
