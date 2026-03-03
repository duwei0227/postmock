<script setup>
import { ref, computed } from 'vue';

const props = defineProps({
  openRequests: {
    type: Array,
    default: () => []
  },
  consoleLogs: {
    type: Array,
    default: () => []
  }
});

const emit = defineEmits(['open-request', 'clear-console']);

const activeTab = ref(0); // 0: Find, 1: Console
const searchQuery = ref('');
const selectedLog = ref(null);
const isCollapsed = ref(true); // 默认隐藏
const footerHeight = ref(200);
const isResizing = ref(false);

const filteredRequests = computed(() => {
  if (!searchQuery.value) return props.openRequests;
  
  const query = searchQuery.value.toLowerCase();
  return props.openRequests.filter(req => 
    req.name.toLowerCase().includes(query) || 
    req.url.toLowerCase().includes(query)
  );
});

const openRequest = (request) => {
  emit('open-request', request);
};

const clearConsole = () => {
  emit('clear-console');
};

const selectLog = (log) => {
  selectedLog.value = selectedLog.value?.id === log.id ? null : log;
};

const toggleCollapse = () => {
  isCollapsed.value = !isCollapsed.value;
};

const switchTab = (tabIndex) => {
  // 如果点击的是当前已激活的标签
  if (activeTab.value === tabIndex && !isCollapsed.value) {
    // 收起面板
    isCollapsed.value = true;
  } else {
    // 切换到新标签或展开面板
    activeTab.value = tabIndex;
    
    // 如果当前是收起状态，自动展开到30%高度
    if (isCollapsed.value) {
      isCollapsed.value = false;
      const windowHeight = window.innerHeight;
      footerHeight.value = Math.floor(windowHeight * 0.3);
    }
  }
};

const startResize = (event) => {
  event.preventDefault();
  
  isResizing.value = true;
  const windowHeight = window.innerHeight;
  const wasCollapsed = isCollapsed.value;
  
  // 如果是收起状态，先展开到鼠标位置
  if (wasCollapsed) {
    isCollapsed.value = false;
    const initialHeight = windowHeight - event.clientY;
    footerHeight.value = Math.max(50, Math.min(Math.floor(windowHeight * 0.8), initialHeight));
  }
  
  const startY = event.clientY;
  const startHeight = footerHeight.value;
  let hasMoved = false;

  const onMouseMove = (e) => {
    // 检测是否真正移动了（超过3px才算移动）
    const moveDistance = Math.abs(e.clientY - startY);
    if (!hasMoved && moveDistance <= 3) {
      return;
    }
    
    hasMoved = true;
    
    // 计算高度变化
    const deltaY = startY - e.clientY;
    let newHeight = startHeight + deltaY;
    
    // 限制高度范围
    const maxHeight = Math.floor(windowHeight * 0.8);
    newHeight = Math.max(50, Math.min(maxHeight, newHeight));
    
    footerHeight.value = newHeight;
    
    // 检查自动收起条件：
    // 1. 当前是展开状态（!isCollapsed.value）
    // 2. 高度低于窗口高度的15%
    const collapseThreshold = windowHeight * 0.15;
    if (!isCollapsed.value && newHeight < collapseThreshold) {
      isCollapsed.value = true;
      isResizing.value = false;
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
    }
  };

  const onMouseUp = () => {
    isResizing.value = false;
    
    // 如果从收起状态点击但没有移动，则展开到30%高度
    if (wasCollapsed && !hasMoved) {
      footerHeight.value = Math.floor(windowHeight * 0.3);
    }
    
    document.removeEventListener('mousemove', onMouseMove);
    document.removeEventListener('mouseup', onMouseUp);
  };

  document.addEventListener('mousemove', onMouseMove);
  document.addEventListener('mouseup', onMouseUp);
};

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

const formatTime = (timestamp) => {
  const date = new Date(timestamp);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
};
</script>

<template>
  <footer 
    class="footer bg-surface-0 dark:bg-surface-950 border-t border-surface-200 dark:border-surface-700 flex flex-col absolute bottom-0 left-0 right-0 z-10" 
    :style="{ height: isCollapsed ? 'auto' : `${footerHeight}px` }"
  >
    <!-- Resize Handle (always visible) -->
    <div 
      @mousedown="startResize"
      class="h-1 bg-surface-200 dark:bg-surface-700 hover:bg-primary cursor-ns-resize transition"
      :class="{ 'bg-primary': isResizing }"
    ></div>

    <!-- Tab Headers -->
    <div class="flex border-b border-surface-200 dark:border-surface-700">
      <button 
        @click="switchTab(0)"
        :class="[
          'px-4 py-2 text-xs font-medium transition',
          activeTab === 0 
            ? 'text-primary border-b-2 border-primary bg-surface-0 dark:bg-surface-950' 
            : 'text-surface-600 dark:text-surface-400 hover:text-surface-900 dark:hover:text-surface-50'
        ]"
      >
        Find
      </button>
      <button 
        @click="switchTab(1)"
        :class="[
          'px-4 py-2 text-xs font-medium transition',
          activeTab === 1 
            ? 'text-primary border-b-2 border-primary bg-surface-0 dark:bg-surface-950' 
            : 'text-surface-600 dark:text-surface-400 hover:text-surface-900 dark:hover:text-surface-50'
        ]"
      >
        Console
        <span v-if="consoleLogs.length > 0" class="ml-1 px-1.5 py-0.5 bg-primary text-primary-contrast rounded-full text-xs">
          {{ consoleLogs.length }}
        </span>
      </button>
      <div class="flex-1"></div>
      <button 
        @click="toggleCollapse"
        class="px-4 py-2 text-xs text-surface-600 dark:text-surface-400 hover:text-surface-900 dark:hover:text-surface-50 transition"
      >
        <i :class="['pi', isCollapsed ? 'pi-chevron-up' : 'pi-chevron-down']"></i>
      </button>
    </div>

    <!-- Tab Content (only when expanded) -->
    <div v-if="!isCollapsed" class="flex-1 overflow-hidden">
      <!-- Find Tab -->
      <div v-if="activeTab === 0" class="h-full flex">
        <!-- Search Box (30%) -->
        <div class="w-[30%] border-r border-surface-200 dark:border-surface-700 p-2">
          <IconField iconPosition="left">
            <InputIcon class="pi pi-search" />
            <InputText 
              v-model="searchQuery"
              placeholder="Search by name or URL..." 
              class="w-full text-xs"
              size="small"
            />
          </IconField>
        </div>
        
        <!-- Results (70%) -->
        <div class="flex-1 overflow-y-auto p-2">
          <div v-if="filteredRequests.length === 0" class="text-center text-surface-400 dark:text-surface-500 text-xs py-4">
            {{ searchQuery ? 'No matching requests found' : 'No open requests' }}
          </div>
          <div 
            v-for="request in filteredRequests"
            :key="request.id"
            @click="openRequest(request)"
            class="p-2 mb-1 rounded hover:bg-surface-100 dark:hover:bg-surface-800 cursor-pointer transition"
          >
            <div class="flex items-center gap-2 mb-1">
              <span :class="['text-xs font-semibold', getMethodColor(request.method)]">
                {{ request.method }}
              </span>
              <span class="text-xs text-surface-700 dark:text-surface-300 font-medium">
                {{ request.name }}
              </span>
            </div>
            <div class="text-xs text-surface-500 dark:text-surface-400 truncate">
              {{ request.url || 'No URL specified' }}
            </div>
          </div>
        </div>
      </div>

      <!-- Console Tab -->
      <div v-else class="h-full flex flex-col">
        <div class="p-2 border-b border-surface-200 dark:border-surface-700 flex justify-between items-center">
          <span class="text-xs text-surface-600 dark:text-surface-400">
            {{ consoleLogs.length }} request(s)
          </span>
          <Button 
            label="Clear"
            icon="pi pi-trash"
            size="small"
            text
            @click="clearConsole"
          />
        </div>
        <div class="flex-1 overflow-y-auto">
          <div v-if="consoleLogs.length === 0" class="text-center text-surface-400 dark:text-surface-500 text-xs py-4">
            No console logs yet
          </div>
          <div v-for="log in consoleLogs" :key="log.id" class="border-b border-surface-100 dark:border-surface-800">
            <!-- Log Summary -->
            <div 
              @click="selectLog(log)"
              class="p-2 hover:bg-surface-100 dark:hover:bg-surface-800 cursor-pointer transition"
            >
              <div class="flex items-center gap-2 text-xs">
                <span class="text-surface-400">{{ formatTime(log.startTime) }}</span>
                <span :class="['font-semibold', getMethodColor(log.method)]">
                  {{ log.method }}
                </span>
                <span class="flex-1 truncate text-surface-700 dark:text-surface-300">
                  {{ log.url }}
                </span>
                <span :class="['font-semibold', getStatusColor(log.status)]">
                  {{ log.status }}
                </span>
                <span class="text-surface-500">{{ log.duration }}</span>
                <i :class="['pi text-xs', selectedLog?.id === log.id ? 'pi-chevron-down' : 'pi-chevron-right']"></i>
              </div>
            </div>

            <!-- Log Details (Expanded) -->
            <div v-if="selectedLog?.id === log.id" class="bg-surface-0 dark:bg-surface-950 p-3 text-xs">
              <div class="grid grid-cols-2 gap-4">
                <!-- Request Info -->
                <div>
                  <h4 class="font-semibold text-surface-700 dark:text-surface-300 mb-2">Request</h4>
                  <div class="space-y-2">
                    <div>
                      <span class="text-surface-500">Start Time:</span>
                      <span class="ml-2 text-surface-700 dark:text-surface-300">{{ new Date(log.startTime).toLocaleString('zh-CN') }}</span>
                    </div>
                    <div>
                      <span class="text-surface-500">Method:</span>
                      <span :class="['ml-2 font-semibold', getMethodColor(log.method)]">{{ log.method }}</span>
                    </div>
                    <div>
                      <span class="text-surface-500">URL:</span>
                      <span class="ml-2 text-surface-700 dark:text-surface-300 break-all">{{ log.url }}</span>
                    </div>
                    <div v-if="log.requestHeaders && Object.keys(log.requestHeaders).length > 0">
                      <span class="text-surface-500 font-semibold">Headers:</span>
                      <pre class="mt-1 p-2 bg-surface-100 dark:bg-surface-900 rounded text-xs overflow-x-auto">{{ JSON.stringify(log.requestHeaders, null, 2) }}</pre>
                    </div>
                    <div v-if="log.requestBody">
                      <span class="text-surface-500 font-semibold">Body:</span>
                      <pre class="mt-1 p-2 bg-surface-100 dark:bg-surface-900 rounded text-xs overflow-x-auto max-h-32">{{ log.requestBody }}</pre>
                    </div>
                  </div>
                </div>

                <!-- Response Info -->
                <div>
                  <h4 class="font-semibold text-surface-700 dark:text-surface-300 mb-2">Response</h4>
                  <div class="space-y-2">
                    <div>
                      <span class="text-surface-500">End Time:</span>
                      <span class="ml-2 text-surface-700 dark:text-surface-300">{{ new Date(log.endTime).toLocaleString('zh-CN') }}</span>
                    </div>
                    <div>
                      <span class="text-surface-500">Status:</span>
                      <span :class="['ml-2 font-semibold', getStatusColor(log.status)]">{{ log.status }} {{ log.statusText }}</span>
                    </div>
                    <div>
                      <span class="text-surface-500">Duration:</span>
                      <span class="ml-2 text-surface-700 dark:text-surface-300">{{ log.duration }}</span>
                    </div>
                    <div v-if="log.responseHeaders && Object.keys(log.responseHeaders).length > 0">
                      <span class="text-surface-500 font-semibold">Headers:</span>
                      <pre class="mt-1 p-2 bg-surface-100 dark:bg-surface-900 rounded text-xs overflow-x-auto">{{ JSON.stringify(log.responseHeaders, null, 2) }}</pre>
                    </div>
                    <div v-if="log.responseBody">
                      <span class="text-surface-500 font-semibold">Body:</span>
                      <pre class="mt-1 p-2 bg-surface-100 dark:bg-surface-900 rounded text-xs overflow-x-auto max-h-32">{{ log.responseBody }}</pre>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </footer>
</template>

<style scoped>
</style>
