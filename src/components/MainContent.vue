<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick } from 'vue';
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
const requestWrapperRefs = ref({});

// Sidebar resize state
const INITIAL_SIDEBAR_WIDTH = 320; // 初始宽度 (w-80 = 320px)
const COLLAPSE_THRESHOLD = INITIAL_SIDEBAR_WIDTH * 0.4; // 收起阈值：初始宽度的40%（缩小60%）= 128px
const MIN_SIDEBAR_WIDTH = Math.max(COLLAPSE_THRESHOLD - 50, 100); // 最小宽度设置为收起阈值以下，确保能触发收起
const sidebarWidth = ref(INITIAL_SIDEBAR_WIDTH);
const sidebarCollapsed = ref(false);
const isResizing = ref(false);
const maxSidebarWidth = ref(800); // 默认最大宽度，会在 mounted 时计算

// Calculate max sidebar width (40% of window width)
const updateMaxSidebarWidth = () => {
  maxSidebarWidth.value = Math.floor(window.innerWidth * 0.4);
};

// Handle sidebar resize
const startResize = (event) => {
  if (sidebarCollapsed.value) return;
  isResizing.value = true;
  document.body.style.cursor = 'col-resize';
  document.body.style.userSelect = 'none';
};

const handleResize = (event) => {
  if (!isResizing.value) return;
  
  const newWidth = event.clientX;
  
  // 限制宽度范围
  if (newWidth >= MIN_SIDEBAR_WIDTH && newWidth <= maxSidebarWidth.value) {
    sidebarWidth.value = newWidth;
    
    // 检查是否需要自动收起
    if (newWidth < COLLAPSE_THRESHOLD) {
      sidebarCollapsed.value = true;
      isResizing.value = false;
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
    }
  }
};

const stopResize = () => {
  isResizing.value = false;
  document.body.style.cursor = '';
  document.body.style.userSelect = '';
};

// Toggle sidebar collapse
const toggleSidebar = () => {
  sidebarCollapsed.value = !sidebarCollapsed.value;
  if (!sidebarCollapsed.value) {
    // 展开时恢复到初始宽度
    sidebarWidth.value = INITIAL_SIDEBAR_WIDTH;
  }
};

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

const handleToolbarAction = async (action) => {
  switch(action) {
    case 'closeAllTabs':
      await closeAllTabs();
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
        await closeRequest(selectedTabIndex.value);
      }
      break;
      
    case 'closeOthers':
      if (selectedTabIndex.value >= 0) {
        await closeOtherTabs(selectedTabIndex.value);
      }
      break;
      
    case 'closeAll':
      await closeAllTabs();
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

const closeRequest = async (index) => {
  // 检查是否有未保存的变化
  const requestId = openRequests.value[index];
  const hasChanges = hasRequestUnsavedChanges(requestId);
  
  if (hasChanges) {
    // 检查请求是否已保存过（是否有 collectionId）
    const request = await requestsStore.loadRequest(requestId);
    const hasCollection = request && request.collectionId;
    
    // 显示确认对话框
    return new Promise((resolve) => {
      if (window.$confirm) {
        window.$confirm.require({
          message: 'You have unsaved changes. What would you like to do?',
          header: 'Unsaved Changes',
          icon: 'pi pi-exclamation-triangle',
          acceptLabel: 'Save',
          rejectLabel: 'Discard',
          acceptClass: 'p-button-success',
          rejectClass: 'p-button-danger',
          accept: async () => {
            const wrapperRef = requestWrapperRefs.value[requestId];
            
            if (!hasCollection) {
              // 请求未保存过，打开保存对话框让用户选择位置
              if (wrapperRef && typeof wrapperRef.openSaveDialog === 'function') {
                wrapperRef.openSaveDialog();
              }
              // 不关闭 tab，让用户完成保存后手动关闭
              resolve(false);
            } else {
              // 请求已保存过，直接保存并关闭
              if (wrapperRef && typeof wrapperRef.saveCurrentRequest === 'function') {
                await wrapperRef.saveCurrentRequest();
              }
              
              // 关闭 tab
              performCloseRequest(index);
              resolve(true);
            }
          },
          reject: async () => {
            // 丢弃修改：恢复到原始版本
            const wrapperRef = requestWrapperRefs.value[requestId];
            if (wrapperRef && typeof wrapperRef.restoreOriginalRequest === 'function') {
              console.log('[MainContent] Discarding changes, restoring original request...');
              await wrapperRef.restoreOriginalRequest();
            }
            // 关闭 tab
            performCloseRequest(index);
            resolve(true);
          },
          onHide: () => {
            // 取消，不关闭
            resolve(false);
          }
        });
      } else {
        // 如果没有 confirm 服务，直接关闭
        performCloseRequest(index);
        resolve(true);
      }
    });
  }
  
  // 没有变化，直接关闭
  performCloseRequest(index);
};

const performCloseRequest = (index) => {
  const requests = [...openRequests.value];
  const requestId = requests[index];
  
  // 清除未保存状态
  if (requestId) {
    delete unsavedChangesMap.value[requestId];
  }
  
  requests.splice(index, 1);
  
  // 更新打开的请求列表
  appStateStore.updateOpenRequests(requests);
  
  // 调整 activeRequestIndex
  let newActiveIndex = -1;
  if (requests.length === 0) {
    // 如果没有打开的 tab 了，重置为 -1（显示默认页面）
    newActiveIndex = -1;
  } else if (index <= activeRequestIndex.value) {
    // 如果关闭的是当前选中的 tab 或之前的 tab
    if (index === activeRequestIndex.value) {
      // 关闭的是当前选中的 tab
      // 如果关闭的是最后一个 tab，选中前一个；否则保持当前索引（会自动选中下一个）
      newActiveIndex = index >= requests.length ? requests.length - 1 : index;
    } else {
      // 关闭的是当前选中 tab 之前的 tab，索引需要前移
      newActiveIndex = activeRequestIndex.value - 1;
    }
  } else {
    // 如果关闭的是当前选中 tab 之后的 tab，activeRequestIndex 不需要改变
    newActiveIndex = activeRequestIndex.value;
  }
  
  appStateStore.setActiveRequest(newActiveIndex);
  
  // 同步更新 CollectionsPanel 的选中状态
  if (newActiveIndex >= 0 && requests[newActiveIndex]) {
    syncCollectionsPanelSelection(requests[newActiveIndex]);
  } else {
    // 清除 CollectionsPanel 的选中状态（最后一个 Tab 关闭）
    if (collectionsPanelRef.value && typeof collectionsPanelRef.value.clearSelection === 'function') {
      collectionsPanelRef.value.clearSelection();
    }
  }
};

// 关闭其他 tabs
const closeOtherTabs = async (keepIndex) => {
  const requests = [...openRequests.value];
  const keepRequestId = requests[keepIndex];
  
  // 检查其他 tabs 是否有未保存的变化
  const unsavedRequests = [];
  for (let i = 0; i < requests.length; i++) {
    if (i !== keepIndex && hasRequestUnsavedChanges(requests[i])) {
      unsavedRequests.push(requests[i]);
    }
  }
  
  if (unsavedRequests.length > 0) {
    // 有未保存的变化，显示确认对话框
    return new Promise((resolve) => {
      if (window.$confirm) {
        window.$confirm.require({
          message: `You have ${unsavedRequests.length} tab(s) with unsaved changes. Do you want to discard the changes and close them?`,
          header: 'Unsaved Changes',
          icon: 'pi pi-exclamation-triangle',
          acceptLabel: 'Discard & Close',
          rejectLabel: 'Cancel',
          acceptClass: 'p-button-danger',
          accept: async () => {
            // 还原所有有未保存变化的请求
            for (const requestId of unsavedRequests) {
              const wrapperRef = requestWrapperRefs.value[requestId];
              if (wrapperRef && typeof wrapperRef.restoreOriginalRequest === 'function') {
                console.log('[MainContent] Discarding changes for request:', requestId);
                await wrapperRef.restoreOriginalRequest();
              }
              delete unsavedChangesMap.value[requestId];
            }
            
            // 只保留指定的 tab
            appStateStore.updateOpenRequests([keepRequestId]);
            appStateStore.setActiveRequest(0);
            
            // 同步 CollectionsPanel 选中状态
            syncCollectionsPanelSelection(keepRequestId);
            
            resolve(true);
          },
          reject: () => {
            resolve(false);
          }
        });
      } else {
        // 没有 confirm 服务，直接关闭
        appStateStore.updateOpenRequests([keepRequestId]);
        appStateStore.setActiveRequest(0);
        syncCollectionsPanelSelection(keepRequestId);
        resolve(true);
      }
    });
  }
  
  // 没有未保存的变化，直接关闭
  appStateStore.updateOpenRequests([keepRequestId]);
  appStateStore.setActiveRequest(0);
  syncCollectionsPanelSelection(keepRequestId);
};

// 关闭所有 tabs
const closeAllTabs = async () => {
  const requests = [...openRequests.value];
  
  // 检查是否有未保存的变化
  const unsavedRequests = requests.filter(requestId => hasRequestUnsavedChanges(requestId));
  
  if (unsavedRequests.length > 0) {
    // 有未保存的变化，显示确认对话框
    return new Promise((resolve) => {
      if (window.$confirm) {
        window.$confirm.require({
          message: `You have ${unsavedRequests.length} tab(s) with unsaved changes. Do you want to discard the changes and close them?`,
          header: 'Unsaved Changes',
          icon: 'pi pi-exclamation-triangle',
          acceptLabel: 'Discard & Close All',
          rejectLabel: 'Cancel',
          acceptClass: 'p-button-danger',
          accept: async () => {
            // 还原所有有未保存变化的请求
            for (const requestId of unsavedRequests) {
              const wrapperRef = requestWrapperRefs.value[requestId];
              if (wrapperRef && typeof wrapperRef.restoreOriginalRequest === 'function') {
                console.log('[MainContent] Discarding changes for request:', requestId);
                await wrapperRef.restoreOriginalRequest();
              }
            }
            
            // 清除所有未保存状态
            unsavedChangesMap.value = {};
            
            // 关闭所有 tabs
            appStateStore.updateOpenRequests([]);
            appStateStore.setActiveRequest(-1);
            
            // 清除 CollectionsPanel 选中状态
            if (collectionsPanelRef.value && typeof collectionsPanelRef.value.clearSelection === 'function') {
              collectionsPanelRef.value.clearSelection();
            }
            
            resolve(true);
          },
          reject: () => {
            resolve(false);
          }
        });
      } else {
        // 没有 confirm 服务，直接关闭
        unsavedChangesMap.value = {};
        appStateStore.updateOpenRequests([]);
        appStateStore.setActiveRequest(-1);
        
        if (collectionsPanelRef.value && typeof collectionsPanelRef.value.clearSelection === 'function') {
          collectionsPanelRef.value.clearSelection();
        }
        
        resolve(true);
      }
    });
  }
  
  // 没有未保存的变化，直接关闭
  appStateStore.updateOpenRequests([]);
  appStateStore.setActiveRequest(-1);
  
  if (collectionsPanelRef.value && typeof collectionsPanelRef.value.clearSelection === 'function') {
    collectionsPanelRef.value.clearSelection();
  }
};

// 同步 CollectionsPanel 的选中状态
const syncCollectionsPanelSelection = async (requestId) => {
  try {
    const request = await requestsStore.loadRequest(requestId);
    if (request && request.collectionId && collectionsPanelRef.value) {
      collectionsPanelRef.value.selectRequestNode(
        request.id,
        request.collectionId,
        request.folderId
      );
    }
  } catch (error) {
    console.error('Failed to sync collections panel selection:', error);
  }
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
    // 创建基本的请求对象
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
      collectionId: requestData.collection?.id || null,
      folderId: requestData.folder?.id || null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    // 保存请求数据到存储
    await requestsStore.saveRequest(newRequest);
    
    // 如果有 collection，添加引用
    if (requestData.collection) {
      await collectionsStore.addRequestReference(
        requestData.collection.id,
        newRequest.id,
        newRequest.name,
        newRequest.method,
        newRequest.url,
        requestData.folder?.id
      );
    }
    
    // 打开 tab
    appStateStore.addOpenRequest(newRequest.id);
    
    // 触发名称更新
    requestNamesVersion.value++;
    
    // 自动选中新创建的 request
    if (requestData.collection && collectionsPanelRef.value) {
      collectionsPanelRef.value.selectRequestNode(
        newRequest.id,
        requestData.collection.id,
        requestData.folder?.id
      );
    }
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
  // 触发名称更新
  requestNamesVersion.value++;
};

const handleRequestDeleted = (requestId) => {
  // 从打开的 tabs 中移除被删除的 request
  const requests = [...openRequests.value];
  const deletedIndex = requests.indexOf(requestId);
  
  if (deletedIndex !== -1) {
    requests.splice(deletedIndex, 1);
    
    // 更新打开的请求列表
    appStateStore.updateOpenRequests(requests);
    
    // 调整 activeRequestIndex
    if (requests.length === 0) {
      // 如果没有打开的 tab 了，重置为 -1（显示默认页面）
      appStateStore.setActiveRequest(-1);
    } else if (deletedIndex <= activeRequestIndex.value) {
      // 如果删除的是当前选中的 tab 或之前的 tab
      if (deletedIndex === activeRequestIndex.value) {
        // 删除的是当前选中的 tab
        // 如果删除的是最后一个 tab，选中前一个；否则保持当前索引（会自动选中下一个）
        const newIndex = deletedIndex >= requests.length ? requests.length - 1 : deletedIndex;
        appStateStore.setActiveRequest(newIndex);
      } else {
        // 删除的是当前选中 tab 之前的 tab，索引需要前移
        appStateStore.setActiveRequest(activeRequestIndex.value - 1);
      }
    }
    // 如果删除的是当前选中 tab 之后的 tab，activeRequestIndex 不需要改变
  }
};

const handleRequestDuplicated = (requestId) => {
  // 打开新创建的 duplicated request
  appStateStore.addOpenRequest(requestId);
  // 触发名称更新
  requestNamesVersion.value++;
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
    
    // 清除未保存状态
    updateUnsavedStatus(request.id, false);
    
    // 触发名称更新
    requestNamesVersion.value++;
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

// 处理未保存变化状态更新
const handleUnsavedChanges = (requestId, hasChanges) => {
  console.log('[MainContent] handleUnsavedChanges called, requestId:', requestId, 'hasChanges:', hasChanges);
  updateUnsavedStatus(requestId, hasChanges);
  // 同时触发名称更新（因为名称可能也变了）
  requestNamesVersion.value++;
};

// 获取请求的显示名称
const getRequestName = (requestId) => {
  const request = requestsStore.requests.get(requestId);
  return request?.name || 'Untitled Request';
};

// 用于触发名称更新的响应式变量
const requestNamesVersion = ref(0);

// 创建一个 computed 来追踪所有打开请求的名称（确保响应式）
const openRequestNames = computed(() => {
  // 依赖 requestNamesVersion 和 openRequests 来触发重新计算
  console.log('[MainContent] Computing openRequestNames, version:', requestNamesVersion.value);
  
  const names = {};
  for (const requestId of openRequests.value) {
    const request = requestsStore.requests.get(requestId);
    const name = request?.name || 'Untitled Request';
    console.log('[MainContent] Request', requestId, 'name:', name);
    names[requestId] = name;
  }
  console.log('[MainContent] Computed names:', names);
  return names;
});

// 监听 openRequests 变化，触发名称更新
watch(openRequests, (newRequests, oldRequests) => {
  console.log('[MainContent] openRequests changed, old:', oldRequests, 'new:', newRequests);
  requestNamesVersion.value++;
  
  // 如果从空变为非空，加载请求
  if (oldRequests && oldRequests.length === 0 && newRequests && newRequests.length > 0) {
    console.log('[MainContent] openRequests changed from empty to non-empty, loading requests...');
    loadOpenRequests();
  }
}, { deep: true });

// 存储每个请求的未保存状态
const unsavedChangesMap = ref({});

// 检查请求是否有未保存的变化
const hasRequestUnsavedChanges = (requestId) => {
  return unsavedChangesMap.value[requestId] || false;
};

// 更新请求的未保存状态
const updateUnsavedStatus = (requestId, hasChanges) => {
  console.log('[MainContent] updateUnsavedStatus, requestId:', requestId, 'hasChanges:', hasChanges);
  console.log('[MainContent] Before update, unsavedChangesMap:', unsavedChangesMap.value);
  unsavedChangesMap.value[requestId] = hasChanges;
  console.log('[MainContent] After update, unsavedChangesMap:', unsavedChangesMap.value);
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

// 组件挂载时预加载所有打开的请求到缓存
onMounted(async () => {
  console.log('[MainContent] Component mounted, waiting for appState to load...');
  
  // 计算最大侧边栏宽度
  updateMaxSidebarWidth();
  
  // 监听窗口大小变化
  window.addEventListener('resize', updateMaxSidebarWidth);
  window.addEventListener('mousemove', handleResize);
  window.addEventListener('mouseup', stopResize);
  
  // 等待 appState 加载完成
  if (appStateStore.isLoading) {
    console.log('[MainContent] AppState is still loading, waiting...');
    // 使用 watch 等待加载完成
    const unwatch = watch(
      () => appStateStore.isLoading,
      async (isLoading) => {
        if (!isLoading) {
          console.log('[MainContent] AppState loaded, now loading requests...');
          unwatch(); // 停止监听
          // 使用 nextTick 确保 openRequests 已经更新
          await nextTick();
          await loadOpenRequests();
        }
      }
    );
  } else {
    // appState 已经加载完成
    console.log('[MainContent] AppState already loaded, loading requests...');
    // 使用 nextTick 确保 openRequests 已经更新
    await nextTick();
    await loadOpenRequests();
  }
});

// 清理事件监听器
onBeforeUnmount(() => {
  window.removeEventListener('resize', updateMaxSidebarWidth);
  window.removeEventListener('mousemove', handleResize);
  window.removeEventListener('mouseup', stopResize);
});

// 加载打开的请求
const loadOpenRequests = async () => {
  // 获取所有打开的请求 ID
  const openRequestIds = openRequests.value;
  
  if (openRequestIds.length > 0) {
    console.log('[MainContent] Found open requests:', openRequestIds);
    
    try {
      // 预加载所有打开的请求到缓存
      await requestsStore.loadMultipleRequests(openRequestIds);
      console.log('[MainContent] Successfully loaded all open requests to cache');
      console.log('[MainContent] Requests in store:', Array.from(requestsStore.requests.keys()));
      
      // 检查所有请求是否有未保存的变化
      for (const requestId of openRequestIds) {
        const request = await requestsStore.loadRequest(requestId);
        if (request && request.collectionId) {
          // 从 collection 中获取原始版本
          const collection = collectionsStore.collections.find(c => c.id === request.collectionId);
          if (collection) {
            // 查找请求引用
            const findRequestInCollection = (folders) => {
              for (const folder of folders) {
                const found = folder.requests.find(r => r.id === requestId);
                if (found) return found;
                if (folder.folders && folder.folders.length > 0) {
                  const foundInSubfolder = findRequestInCollection(folder.folders);
                  if (foundInSubfolder) return foundInSubfolder;
                }
              }
              return null;
            };
            
            let requestRef = collection.requests.find(r => r.id === requestId);
            if (!requestRef && collection.folders && collection.folders.length > 0) {
              requestRef = findRequestInCollection(collection.folders);
            }
            
            if (requestRef) {
              // 比较缓存版本和 collection 版本
              const hasChanges = (
                request.name !== requestRef.name ||
                request.method !== requestRef.method ||
                request.url !== requestRef.url
              );
              
              console.log('[MainContent] Checking request', requestId, 'hasChanges:', hasChanges);
              if (hasChanges) {
                updateUnsavedStatus(requestId, true);
              }
            }
          }
        }
      }
      
      // 触发名称更新
      console.log('[MainContent] Triggering name update, old version:', requestNamesVersion.value);
      requestNamesVersion.value++;
      console.log('[MainContent] New version:', requestNamesVersion.value);
    } catch (error) {
      console.error('[MainContent] Failed to load open requests:', error);
    }
  } else {
    console.log('[MainContent] No open requests to load');
  }
};

defineExpose({
  createNewRequest,
  collectionsPanelRef,
  environmentManagerRef
});
</script>

<template>
  <div class="main-content flex-1 flex overflow-hidden">
    <!-- Collapsed Sidebar Button -->
    <div 
      v-if="sidebarCollapsed"
      class="collapsed-sidebar-button bg-surface-0 dark:bg-surface-950 border-r border-surface-200 dark:border-surface-700 flex flex-col items-center py-3 gap-2"
    >
      <Button
        icon="pi pi-angle-right"
        text
        rounded
        size="small"
        severity="secondary"
        title="展开侧边栏"
        @click="toggleSidebar"
      />
      <Button
        icon="pi pi-history"
        text
        rounded
        size="small"
        severity="secondary"
        title="History"
        :class="{ 'bg-primary-50 dark:bg-primary-900/20': activeTab === 0 }"
        @click="activeTab = 0; toggleSidebar()"
      />
      <Button
        icon="pi pi-folder"
        text
        rounded
        size="small"
        severity="secondary"
        title="Collections"
        :class="{ 'bg-primary-50 dark:bg-primary-900/20': activeTab === 1 }"
        @click="activeTab = 1; toggleSidebar()"
      />
    </div>

    <!-- Sidebar -->
    <aside 
      v-if="!sidebarCollapsed"
      class="sidebar bg-surface-0 dark:bg-surface-950 border-r border-surface-200 dark:border-surface-700 flex flex-col relative"
      :style="{ width: sidebarWidth + 'px' }"
    >
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
            @request-duplicated="handleRequestDuplicated"
          />
        </TabPanel>
      </TabView>

      <!-- Resize Handle -->
      <div 
        class="resize-handle"
        @mousedown="startResize"
      ></div>
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
                <span 
                  class="text-xs"
                  :class="{ 'text-orange-600 dark:text-orange-400': hasRequestUnsavedChanges(requestId) }"
                >
                  {{ openRequestNames[requestId] }}
                </span>
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
          :ref="el => { if (el) requestWrapperRefs[openRequests[activeRequestIndex]] = el }"
          :requestId="openRequests[activeRequestIndex]"
          :environmentManager="environmentManagerRef"
          :collections="collectionsStore.collections"
          @close="closeRequest(activeRequestIndex)"
          @add-console-log="(log) => { emit('add-console-log', log); addToHistory(log); }"
          @save-request="handleSaveRequest"
          @unsaved-changes="(hasChanges) => handleUnsavedChanges(openRequests[activeRequestIndex], hasChanges)"
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

/* Sidebar resize handle */
.sidebar {
  position: relative;
}

.resize-handle {
  position: absolute;
  top: 0;
  right: 0;
  width: 4px;
  height: 100%;
  cursor: col-resize;
  background: transparent;
  transition: background-color 0.2s;
  z-index: 10;
}

.resize-handle:hover {
  background: var(--primary-color);
}

.resize-handle:active {
  background: var(--primary-color);
}

/* Collapsed sidebar button */
.collapsed-sidebar-button {
  width: 48px;
  flex-shrink: 0;
}

/* Prevent text selection during resize */
body.resizing {
  user-select: none;
  cursor: col-resize;
}
</style>
