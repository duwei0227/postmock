<script setup>
import { ref, computed, watch } from 'vue';
import { useCollectionsStore } from '@/stores/collections';
import { useRequestsStore } from '@/stores/requests';
import { useAppStateStore } from '@/stores/appState';
import { useHistoryStore } from '@/stores/history';
import { generateId } from '@/utils/id-generator';
import HttpRequestWrapper from './HttpRequestWrapper.vue';
import EnvironmentManager from './EnvironmentManager.vue';
import HistoryPanel from './HistoryPanel.vue';
import CollectionsPanel from './CollectionsPanel.vue';

const emit = defineEmits(['add-console-log']);

// Stores
const collectionsStore = useCollectionsStore();
const requestsStore = useRequestsStore();
const appStateStore = useAppStateStore();
const historyStore = useHistoryStore();

const activeTab = ref(1);
const searchQuery = ref('');
const toolbarMenu = ref();
const tabContextMenu = ref();
const selectedTabIndex = ref(-1);
const environmentManagerRef = ref(null);
const historyPanelRef = ref(null);
const collectionsPanelRef = ref(null);

// Use store state
const openRequests = computed(() => appStateStore.openRequests);
const activeRequestIndex = computed({
  get: () => appStateStore.activeRequestIndex,
  set: (value) => appStateStore.setActiveRequest(value)
});

const toolbarMenuModel = ref([
  {
    label: 'Close All Tabs',
    icon: 'pi pi-times',
    command: () => handleToolbarAction('closeAllTabs')
  }
]);

const tabContextMenuModel = ref([
  {
    label: 'Duplicate Tab',
    icon: 'pi pi-copy',
    command: () => handleTabAction('duplicate')
  },
  { separator: true },
  {
    label: 'Close',
    icon: 'pi pi-times',
    command: () => handleTabAction('close')
  },
  {
    label: 'Close Other Tabs',
    icon: 'pi pi-times-circle',
    command: () => handleTabAction('closeOthers')
  },
  {
    label: 'Close All Tabs',
    icon: 'pi pi-times',
    command: () => handleTabAction('closeAll')
  }
]);

const showToolbarMenu = (event) => {
  toolbarMenu.value.show(event);
};

const handleToolbarAction = (action) => {
  switch(action) {
    case 'closeAllTabs':
      appStateStore.updateOpenRequests([]);
      break;
  }
};

const showTabContextMenu = (event, index) => {
  event.preventDefault();
  selectedTabIndex.value = index;
  tabContextMenu.value.show(event);
};

const handleTabAction = async (action) => {
  const requests = [...openRequests.value];
  
  switch(action) {
    case 'duplicate':
      if (selectedTabIndex.value >= 0) {
        const originalRequestId = requests[selectedTabIndex.value];
        const originalRequest = await requestsStore.loadRequest(originalRequestId);
        
        if (originalRequest) {
          const duplicatedRequest = {
            ...originalRequest,
            id: generateId(),
            name: `${originalRequest.name} (Copy)`,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
          };
          
          await requestsStore.saveRequest(duplicatedRequest);
          requests.splice(selectedTabIndex.value + 1, 0, duplicatedRequest.id);
          appStateStore.updateOpenRequests(requests);
          appStateStore.setActiveRequest(selectedTabIndex.value + 1);
        }
      }
      break;
      
    case 'close':
      if (selectedTabIndex.value >= 0) {
        closeRequest(selectedTabIndex.value);
      }
      break;
      
    case 'closeOthers':
      if (selectedTabIndex.value >= 0) {
        const keepRequestId = requests[selectedTabIndex.value];
        appStateStore.updateOpenRequests([keepRequestId]);
      }
      break;
      
    case 'closeAll':
      appStateStore.updateOpenRequests([]);
      break;
  }
};

const createNewRequest = async () => {
  try {
    // Create new request without collection assignment
    const newRequest = {
      id: generateId(),
      name: 'Untitled Request',
      method: 'GET',
      url: '',
      params: [{ key: '', value: '', enabled: true }],
      headers: [{ key: '', value: '', enabled: true }],
      body: {
        type: 'none',
        raw: '',
        formData: [{ key: '', value: '', type: 'text', enabled: true }],
        urlencoded: [{ key: '', value: '', enabled: true }]
      },
      auth: {
        type: 'none',
        token: '',
        username: '',
        password: ''
      },
      tests: {
        statusCodeTests: [{ operator: 'equals', value: '200', enabled: true }],
        jsonFieldTests: [],
        globalVariables: []
      },
      collectionId: null,  // 不分配 collection
      folderId: null,      // 不分配 folder
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    // Save request (without adding to collection)
    await requestsStore.saveRequest(newRequest);
    
    // Open in tab
    appStateStore.addOpenRequest(newRequest.id);
  } catch (error) {
    console.error('Failed to create new request:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to create new request',
        life: 3000
      });
    }
  }
};

const closeRequest = (index) => {
  const requests = [...openRequests.value];
  requests.splice(index, 1);
  appStateStore.updateOpenRequests(requests);
};

const addToHistory = (log) => {
  historyPanelRef.value?.addToHistory(log);
};

const openFromHistory = async (historyItem) => {
  try {
    // Get or create default collection for history items
    let defaultCollection = collectionsStore.collections.find(c => c.name === 'My Requests');
    
    if (!defaultCollection) {
      defaultCollection = await collectionsStore.createCollection('My Requests', 'Default collection');
    }
    
    // Create request from history
    const newRequest = {
      id: generateId(),
      name: `${historyItem.method} ${new URL(historyItem.url).pathname}`,
      method: historyItem.requestData.method,
      url: historyItem.url,
      params: [{ key: '', value: '', enabled: true }],
      headers: [],
      body: {
        type: 'none',
        raw: '',
        formData: [{ key: '', value: '', type: 'text', enabled: true }],
        urlencoded: [{ key: '', value: '', enabled: true }]
      },
      auth: {
        type: 'none',
        token: '',
        username: '',
        password: ''
      },
      tests: {
        statusCodeTests: [{ operator: 'equals', value: '200', enabled: true }],
        jsonFieldTests: [],
        globalVariables: []
      },
      collectionId: defaultCollection.id,
      folderId: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    // Fill headers
    if (historyItem.requestData.headers) {
      newRequest.headers = Object.entries(historyItem.requestData.headers).map(([key, value]) => ({
        key,
        value,
        enabled: true
      }));
    }
    
    // Fill body
    if (historyItem.requestData.body) {
      try {
        JSON.parse(historyItem.requestData.body);
        newRequest.body.type = 'json';
        newRequest.body.raw = historyItem.requestData.body;
      } catch {
        if (historyItem.requestData.body.includes('=') && historyItem.requestData.body.includes('&')) {
          newRequest.body.type = 'x-www-form-urlencoded';
          const pairs = historyItem.requestData.body.split('&');
          newRequest.body.urlencoded = pairs.map(pair => {
            const [key, value] = pair.split('=');
            return {
              key: decodeURIComponent(key || ''),
              value: decodeURIComponent(value || ''),
              enabled: true
            };
          });
        }
      }
    }
    
    await requestsStore.saveRequest(newRequest);
    appStateStore.addOpenRequest(newRequest.id);
  } catch (error) {
    console.error('Failed to open from history:', error);
  }
};

const handleAddRequest = async (requestData) => {
  try {
    // 创建基本的请求对象（不包含临时属性）
    const newRequest = {
      id: generateId(),
      name: requestData.name || 'New Request',
      method: 'GET',
      url: '',
      params: [{ key: '', value: '', enabled: true }],
      headers: [{ key: '', value: '', enabled: true }],
      body: {
        type: 'none',
        raw: '',
        formData: [{ key: '', value: '', type: 'text', enabled: true }],
        urlencoded: [{ key: '', value: '', enabled: true }]
      },
      auth: {
        type: 'none',
        token: '',
        username: '',
        password: ''
      },
      tests: {
        statusCodeTests: [{ operator: 'equals', value: '200', enabled: true }],
        jsonFieldTests: [],
        globalVariables: []
      },
      collectionId: null,  // 不立即分配 collection
      folderId: null,      // 不立即分配 folder
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    // 保存请求数据到存储（不包含临时属性）
    await requestsStore.saveRequest(newRequest);
    
    // 创建带有临时属性的请求对象，用于传递给 HttpRequest 组件
    const requestWithTempProps = {
      ...newRequest,
      _initialCollection: requestData.collection,
      _initialFolder: requestData.folder,
      _showSaveDialog: requestData.showSaveDialog || false
    };
    
    // 将带有临时属性的对象存入内存缓存（不持久化）
    requestsStore.requests.set(newRequest.id, requestWithTempProps);
    
    // 打开 tab
    appStateStore.addOpenRequest(newRequest.id);
  } catch (error) {
    console.error('Failed to add request:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to create request',
        life: 3000
      });
    }
  }
};

const handleOpenRequest = (requestData) => {
  const { request } = requestData;
  appStateStore.addOpenRequest(request.id);
};

const handleRequestDeleted = (requestId) => {
  // 从打开的 tabs 中移除被删除的 request
  const requests = [...openRequests.value];
  const index = requests.indexOf(requestId);
  
  if (index !== -1) {
    requests.splice(index, 1);
    appStateStore.updateOpenRequests(requests);
  }
};

const handleSaveRequest = async (saveData) => {
  const { request, collection, folder } = saveData;
  
  try {
    // 获取请求的旧位置信息（从请求对象本身）
    const oldCollectionId = request.collectionId;
    const oldFolderId = request.folderId;
    
    // 检查是否需要移动（位置发生变化）
    const needsMove = oldCollectionId && (oldCollectionId !== collection.id || oldFolderId !== folder?.id);
    
    if (needsMove) {
      await collectionsStore.removeRequestReference(oldCollectionId, request.id);
    }
    
    // 更新请求的 collectionId 和 folderId
    request.collectionId = collection.id;
    request.folderId = folder?.id;
    
    // 保存请求数据
    await requestsStore.saveRequest(request);
    
    // 如果是首次保存或移动，添加到新位置
    if (!oldCollectionId || needsMove) {
      await collectionsStore.addRequestReference(
        collection.id,
        request.id,
        request.name,
        request.method,
        request.url,
        folder?.id
      );
    } else {
      // 只是更新内容，更新 collection 中的请求引用
      await collectionsStore.updateRequestReference(
        collection.id,
        request.id,
        request.name,
        request.method,
        request.url,
        folder?.id
      );
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

// 获取请求的显示名称
const getRequestName = (requestId) => {
  const request = requestsStore.requests.get(requestId);
  return request?.name || 'Untitled Request';
};

// 监听 activeRequestIndex 变化，同步 CollectionsPanel 的选中状态
watch(activeRequestIndex, async (newIndex) => {
  if (newIndex >= 0 && openRequests.value[newIndex]) {
    const requestId = openRequests.value[newIndex];
    const request = await requestsStore.loadRequest(requestId);
    
    if (request && request.collectionId && collectionsPanelRef.value) {
      collectionsPanelRef.value.selectRequestNode(
        request.id,
        request.collectionId,
        request.folderId
      );
    }
  }
}, { immediate: true });

defineExpose({
  createNewRequest
});
</script>

<template>
  <div class="main-content flex-1 flex overflow-hidden">
    <!-- Sidebar -->
    <aside class="w-80 bg-surface-0 dark:bg-surface-950 border-r border-surface-200 dark:border-surface-700 flex flex-col">
      <!-- Search Box -->
      <div class="p-3 border-b border-surface-200 dark:border-surface-700">
        <IconField iconPosition="left">
          <InputIcon class="pi pi-search" />
          <InputText 
            v-model="searchQuery"
            placeholder="搜索..." 
            class="w-full text-sm"
            size="small"
          />
        </IconField>
      </div>

      <!-- Tabs -->
      <TabView v-model:activeIndex="activeTab" class="sidebar-tabs">
        <TabPanel header="History">
          <HistoryPanel 
            ref="historyPanelRef"
            :searchQuery="searchQuery"
            @open-from-history="openFromHistory"
          />
        </TabPanel>

        <TabPanel header="Collections">
          <CollectionsPanel 
            ref="collectionsPanelRef"
            :searchQuery="searchQuery"
            @add-request="handleAddRequest"
            @open-request="handleOpenRequest"
            @request-deleted="handleRequestDeleted"
          />
        </TabPanel>
      </TabView>
    </aside>
    
    <!-- Request Editor -->
    <main class="flex-1 bg-surface-0 dark:bg-surface-950 flex flex-col overflow-hidden">
      <!-- Top Toolbar with Tabs -->
      <div class="flex items-center border-b border-surface-200 dark:border-surface-700 bg-surface-0 dark:bg-surface-950">
        <!-- Request Tabs -->
        <div class="flex-1 overflow-hidden">
          <Tabs 
            v-if="openRequests.length > 0"
            :value="activeRequestIndex"
            @update:value="activeRequestIndex = $event"
            scrollable
          >
            <TabList>
              <Tab 
                v-for="(requestId, index) in openRequests"
                :key="requestId"
                :value="index"
                @contextmenu="showTabContextMenu($event, index)"
              >
                <span class="text-xs">{{ getRequestName(requestId) }}</span>
                <i 
                  class="pi pi-times text-xs ml-2 hover:text-red-600 cursor-pointer"
                  @click.stop="closeRequest(index)"
                ></i>
              </Tab>
            </TabList>
          </Tabs>
        </div>

        <!-- Action Buttons -->
        <div class="flex items-center gap-1 px-2 border-l border-surface-200 dark:border-surface-700">
          <Button 
            icon="pi pi-plus"
            text
            rounded
            size="small"
            severity="secondary"
            title="新建"
            @click="createNewRequest"
          />
          <Button 
            icon="pi pi-ellipsis-v"
            text
            rounded
            size="small"
            severity="secondary"
            title="更多选项"
            @click="showToolbarMenu"
          />
          
          <EnvironmentManager ref="environmentManagerRef" />
        </div>
      </div>
      
      <!-- Content Area -->
      <div class="flex-1 overflow-hidden">
        <!-- Empty State -->
        <div v-if="openRequests.length === 0" class="h-full flex items-center justify-center">
          <div class="text-center">
            <div class="mb-4">
              <i class="pi pi-inbox text-6xl text-surface-300 dark:text-surface-600"></i>
            </div>
            <h3 class="text-lg font-medium text-surface-700 dark:text-surface-300 mb-2">
              暂无内容
            </h3>
            <p class="text-sm text-surface-500 dark:text-surface-400 mb-4">
              选择或创建一个请求开始使用
            </p>
            <div class="flex gap-2 justify-center">
              <Button label="新建请求" icon="pi pi-plus" size="small" @click="createNewRequest" />
            </div>
          </div>
        </div>

        <!-- Active Request -->
        <HttpRequestWrapper 
          v-else-if="activeRequestIndex >= 0 && openRequests[activeRequestIndex]"
          :key="openRequests[activeRequestIndex]"
          :requestId="openRequests[activeRequestIndex]"
          :environmentManager="environmentManagerRef"
          :collections="collectionsStore.collections"
          @close="closeRequest(activeRequestIndex)"
          @add-console-log="(log) => { emit('add-console-log', log); addToHistory(log); }"
          @save-request="handleSaveRequest"
        />
      </div>
    </main>

    <!-- Toolbar Menu -->
    <ContextMenu ref="toolbarMenu" :model="toolbarMenuModel" />
    
    <!-- Tab Context Menu -->
    <ContextMenu ref="tabContextMenu" :model="tabContextMenuModel" />
  </div>
</template>

<style scoped>
:deep(.sidebar-tabs) {
  display: flex;
  flex-direction: column;
  flex: 1;
  overflow: hidden;
}

:deep(.sidebar-tabs .p-tabview-nav-container) {
  border-bottom: 1px solid var(--surface-border);
}

:deep(.sidebar-tabs .p-tabview-nav) {
  background: transparent;
  border: none;
}

:deep(.sidebar-tabs .p-tabview-nav-link) {
  padding: 0.5rem 0.75rem;
  font-size: 0.75rem;
  font-weight: 500;
}

:deep(.sidebar-tabs .p-tabview-panels) {
  flex: 1;
  overflow-y: auto;
  padding: 0;
  background: transparent;
}

:deep(.sidebar-tabs .p-tabview-panel) {
  padding: 0;
}
</style>
