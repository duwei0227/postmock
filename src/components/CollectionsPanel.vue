<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useConfirm } from 'primevue/useconfirm';
import { useCollectionsStore } from '@/stores/collections';
import { useRequestsStore } from '@/stores/requests';
import { importExportService } from '@/services/import-export';

const confirm = useConfirm();
const collectionsStore = useCollectionsStore();
const requestsStore = useRequestsStore();

const props = defineProps({
  searchQuery: {
    type: String,
    default: ''
  }
});

const emit = defineEmits(['add-request', 'open-request', 'request-added']);

// Use store collections
const collections = computed(() => collectionsStore.collections);

const expandedKeys = ref({});
const selectedKeys = ref({});
const showCreateDialog = ref(false);
const dialogMode = ref('collection'); // 'collection' or 'folder'
const newItemName = ref('');
const newItemDescription = ref('');
const selectedCollection = ref(null);
const selectedFolder = ref(null);
const selectedRequest = ref(null);
const showRenameDialog = ref(false);
const renameItemName = ref('');
const renamingItem = ref(null);
const contextMenu = ref(null);

// Context Menu 菜单项
const menuItems = computed(() => {
  const baseItems = [];
  
  if (selectedRequest.value) {
    baseItems.push(
      {
        label: 'Open Request',
        icon: 'pi pi-external-link',
        command: () => handleMenuAction('openRequest')
      },
      { separator: true },
      {
        label: 'Duplicate',
        icon: 'pi pi-copy',
        command: () => handleMenuAction('duplicate')
      },
      {
        label: 'Rename',
        icon: 'pi pi-pencil',
        command: () => handleMenuAction('rename')
      },
      { separator: true },
      {
        label: 'Delete',
        icon: 'pi pi-trash',
        class: 'text-red-600 dark:text-red-400',
        command: () => handleMenuAction('delete')
      }
    );
  } else {
    baseItems.push(
      {
        label: 'Add Request',
        icon: 'pi pi-plus',
        command: () => handleMenuAction('addRequest')
      },
      {
        label: 'Add Folder',
        icon: 'pi pi-folder-plus',
        command: () => handleMenuAction('addFolder')
      },
      { separator: true },
      {
        label: 'Duplicate',
        icon: 'pi pi-copy',
        command: () => handleMenuAction('duplicate')
      },
      {
        label: 'Rename',
        icon: 'pi pi-pencil',
        command: () => handleMenuAction('rename')
      }
    );

    if (selectedCollection.value && !selectedFolder.value) {
      baseItems.push(
        {
          label: 'Share Collection',
          icon: 'pi pi-share-alt',
          command: () => handleMenuAction('share')
        }
      );
    }

    baseItems.push(
      { separator: true },
      {
        label: 'Export',
        icon: 'pi pi-download',
        command: () => handleMenuAction('export')
      },
      {
        label: 'Delete',
        icon: 'pi pi-trash',
        class: 'text-red-600 dark:text-red-400',
        command: () => handleMenuAction('delete')
      }
    );
  }

  return baseItems;
});

// 将 collections 数据转换为 Tree 组件需要的格式
const treeNodes = computed(() => {
  const convertToTreeNode = (item, type = 'collection', parentKey = '') => {
    // 使用 '/' 作为分隔符，因为 ID 中可能包含 '-'
    const key = parentKey ? `${parentKey}/${item.id}` : `${type}/${item.id}`;
    
    const node = {
      key,
      label: item.name,
      data: { ...item, type },
      icon: getNodeIcon(type),
      children: []
    };

    // 添加requests作为子节点
    if (item.requests && item.requests.length > 0) {
      const requestNodes = item.requests.map(request => ({
        key: `${key}/request/${request.id}`,
        label: request.name,
        data: { ...request, type: 'request' },
        icon: '',
        children: []
      }));
      node.children.push(...requestNodes);
    }

    // 添加folders作为子节点
    if (item.folders && item.folders.length > 0) {
      const folderNodes = item.folders.map(folder => 
        convertToTreeNode(folder, 'folder', key)
      );
      node.children.push(...folderNodes);
    }

    return node;
  };

  if (!props.searchQuery) {
    return collections.value.map(collection => convertToTreeNode(collection));
  }

  // 搜索过滤
  const query = props.searchQuery.toLowerCase();
  return collections.value
    .filter(collection => collection.name.toLowerCase().includes(query))
    .map(collection => convertToTreeNode(collection));
});

const getNodeIcon = (type) => {
  switch(type) {
    case 'collection':
      return 'pi pi-folder';
    case 'folder':
      return 'pi pi-folder-open';
    default:
      return 'pi pi-folder';
  }
};

const getMethodColor = (method) => {
  const methodColors = {
    'GET': 'text-green-600 dark:text-green-400',
    'POST': 'text-blue-600 dark:text-blue-400',
    'PUT': 'text-yellow-600 dark:text-yellow-400',
    'DELETE': 'text-red-600 dark:text-red-400',
    'PATCH': 'text-purple-600 dark:text-purple-400'
  };
  return methodColors[method] || 'text-surface-600';
};

const getTotalRequestCount = (item) => {
  if (item.type === 'request') return 0;
  
  let count = 0;
  
  if (item.requests && Array.isArray(item.requests)) {
    count += item.requests.length;
  }
  
  if (item.folders && Array.isArray(item.folders)) {
    for (const folder of item.folders) {
      count += getTotalRequestCount(folder);
    }
  }
  
  return count;
};

watch(() => props.searchQuery, (newQuery) => {
  if (newQuery) {
    const newExpandedKeys = {};
    const expandMatchingNodes = (nodes) => {
      nodes.forEach(node => {
        if (node.label.toLowerCase().includes(newQuery.toLowerCase())) {
          newExpandedKeys[node.key] = true;
        }
        if (node.children && node.children.length > 0) {
          expandMatchingNodes(node.children);
        }
      });
    };
    expandMatchingNodes(treeNodes.value);
    expandedKeys.value = newExpandedKeys;
  }
});

const onNodeContextMenu = (event) => {
  // Prevent default context menu
  if (event.originalEvent) {
    event.originalEvent.preventDefault();
    event.originalEvent.stopPropagation();
  }
  
  const node = event.node;
  const nodeData = node.data;
  
  selectedCollection.value = null;
  selectedFolder.value = null;
  selectedRequest.value = null;
  
  if (nodeData.type === 'collection') {
    selectedCollection.value = nodeData;
  } else if (nodeData.type === 'folder') {
    const keyParts = node.key.split('/');
    const collectionId = keyParts[1];
    const parentCollection = collections.value.find(c => c.id === collectionId);
    
    selectedCollection.value = parentCollection;
    selectedFolder.value = nodeData;
  } else if (nodeData.type === 'request') {
    const keyParts = node.key.split('/');
    const collectionId = keyParts[1];
    selectedCollection.value = collections.value.find(c => c.id === collectionId);
    
    selectedRequest.value = { ...nodeData };
    
    const requestIndex = keyParts.findIndex(part => part === 'request');
    if (requestIndex > 2) {
      const folderIds = keyParts.slice(2, requestIndex);
      const parentFolder = findFolderByPath(selectedCollection.value?.folders || [], folderIds);
      if (parentFolder) {
        selectedRequest.value.parentFolder = parentFolder;
      }
    }
  }
  
  if (contextMenu.value && event.originalEvent) {
    contextMenu.value.show(event.originalEvent);
  }
};

const findFolderByPath = (folders, folderIds) => {
  if (!folderIds || folderIds.length === 0) return null;
  
  const currentFolderId = folderIds[0];
  const folder = folders.find(f => f.id === currentFolderId);
  
  if (!folder) return null;
  
  // 如果这是最后一个 ID，返回这个 folder
  if (folderIds.length === 1) {
    return folder;
  }
  
  // 否则继续在子文件夹中查找
  return findFolderByPath(folder.folders || [], folderIds.slice(1));
};

const findFolderById = (collection, folderId) => {
  const searchInFolders = (folders) => {
    for (const folder of folders) {
      if (folder.id === folderId) {
        return folder;
      }
      if (folder.folders && folder.folders.length > 0) {
        const found = searchInFolders(folder.folders);
        if (found) return found;
      }
    }
    return null;
  };
  
  return collection ? searchInFolders(collection.folders || []) : null;
};

const openCreateDialog = (mode = 'collection', collection = null, folder = null) => {
  dialogMode.value = mode;
  selectedCollection.value = collection;
  selectedFolder.value = folder;
  showCreateDialog.value = true;
  newItemName.value = '';
  newItemDescription.value = '';
};

const createItem = async () => {
  if (!newItemName.value.trim()) return;
  
  try {
    if (dialogMode.value === 'collection') {
      const collection = await collectionsStore.createCollection(
        newItemName.value.trim(),
        newItemDescription.value.trim()
      );
      
      expandedKeys.value = {
        ...expandedKeys.value,
        [`collection-${collection.id}`]: true
      };
    } else if (dialogMode.value === 'folder') {
      const folder = await collectionsStore.addFolder(
        selectedCollection.value.id,
        newItemName.value.trim(),
        selectedFolder.value?.id
      );
      
      const expandKeys = {
        ...expandedKeys.value,
        [`collection-${selectedCollection.value.id}`]: true
      };
      
      if (selectedFolder.value) {
        const folderKey = findNodeKeyByData(selectedFolder.value, 'folder');
        if (folderKey) {
          expandKeys[folderKey] = true;
        }
      }
      
      expandedKeys.value = expandKeys;
    }
    
    showCreateDialog.value = false;
    newItemName.value = '';
    newItemDescription.value = '';
  } catch (error) {
    console.error('Failed to create item:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to create item',
        life: 3000
      });
    }
  }
};

const findNodeKeyByData = (data, type) => {
  const searchInNodes = (nodes, targetData, targetType) => {
    for (const node of nodes) {
      if (node.data.id === targetData.id && node.data.type === targetType) {
        return node.key;
      }
      if (node.children && node.children.length > 0) {
        const found = searchInNodes(node.children, targetData, targetType);
        if (found) return found;
      }
    }
    return null;
  };
  
  return searchInNodes(treeNodes.value, data, type);
};

const duplicateCollection = async (collection) => {
  // TODO: Implement full duplication with requests
  try {
    const newCollection = await collectionsStore.createCollection(
      `${collection.name} (Copy)`,
      collection.description
    );
    
    expandedKeys.value = {
      ...expandedKeys.value,
      [`collection-${newCollection.id}`]: true
    };
  } catch (error) {
    console.error('Failed to duplicate collection:', error);
  }
};

const openRenameDialog = (type, item) => {
  renamingItem.value = { type, item };
  renameItemName.value = item.name;
  showRenameDialog.value = true;
};

const renameItem = async () => {
  if (!renameItemName.value.trim() || !renamingItem.value) return;
  
  const { type, item } = renamingItem.value;
  const newName = renameItemName.value.trim();
  
  try {
    if (type === 'collection') {
      await collectionsStore.updateCollection(item.id, { name: newName });
    } else if (type === 'folder') {
      const collection = collections.value.find(c => 
        findFolderById(c, item.id) !== null
      );
      if (collection) {
        await collectionsStore.updateFolder(collection.id, item.id, { name: newName });
      }
    }
    
    showRenameDialog.value = false;
    renamingItem.value = null;
    renameItemName.value = '';
  } catch (error) {
    console.error('Failed to rename item:', error);
  }
};

const addRequestToCollection = async (requestData) => {
  const { collection, folder, request } = requestData;
  
  try {
    await collectionsStore.addRequestReference(
      collection.id,
      request.id,
      request.name,
      request.method || 'GET',
      request.url || '',
      folder?.id
    );
    
    const expandKeys = {
      ...expandedKeys.value,
      [`collection-${collection.id}`]: true
    };
    
    if (folder) {
      const folderKey = findNodeKeyByData(folder, 'folder');
      if (folderKey) {
        expandKeys[folderKey] = true;
      }
    }
    
    expandedKeys.value = expandKeys;
  } catch (error) {
    console.error('Failed to add request to collection:', error);
  }
};

const handleMenuAction = async (action) => {
  const collection = selectedCollection.value;
  const folder = selectedFolder.value;
  const request = selectedRequest.value;
  const requestParentFolder = request?.parentFolder || folder;
  
  switch(action) {
    case 'addRequest':
      const requestData = {
        collection: collection,
        folder: folder,
        name: `New Request in ${folder?.name || collection?.name}`
      };
      emit('add-request', requestData);
      break;
      
    case 'openRequest':
      if (request) {
        emit('open-request', {
          request: request,
          collection: collection,
          folder: requestParentFolder
        });
      }
      break;
      
    case 'addFolder':
      if (request) {
        openCreateDialog('folder', collection, requestParentFolder);
      } else {
        openCreateDialog('folder', collection, folder);
      }
      break;
      
    case 'duplicate':
      if (collection && !folder && !request) {
        duplicateCollection(collection);
      }
      break;
      
    case 'rename':
      if (request) {
        openRenameDialog('request', request);
      } else if (folder) {
        openRenameDialog('folder', folder);
      } else if (collection) {
        openRenameDialog('collection', collection);
      }
      break;
      
    case 'delete':
      if (request) {
        confirm.require({
          message: `确定要删除请求 "${request.name}" 吗？`,
          header: '确认删除',
          icon: 'pi pi-exclamation-triangle',
          acceptLabel: '删除',
          rejectLabel: '取消',
          acceptClass: 'p-button-danger',
          accept: async () => {
            try {
              await collectionsStore.removeRequestReference(collection.id, request.id);
              await requestsStore.deleteRequest(request.id);
            } catch (error) {
              console.error('Failed to delete request:', error);
            }
          }
        });
      } else if (folder) {
        confirm.require({
          message: `确定要删除文件夹 "${folder.name}" 吗？此操作将同时删除其中的所有内容。`,
          header: '确认删除',
          icon: 'pi pi-exclamation-triangle',
          acceptLabel: '删除',
          rejectLabel: '取消',
          acceptClass: 'p-button-danger',
          accept: async () => {
            try {
              await collectionsStore.deleteFolder(collection.id, folder.id);
            } catch (error) {
              console.error('Failed to delete folder:', error);
            }
          }
        });
      } else if (collection) {
        confirm.require({
          message: `确定要删除集合 "${collection.name}" 吗？此操作将删除集合中的所有文件夹和请求。`,
          header: '确认删除',
          icon: 'pi pi-exclamation-triangle',
          acceptLabel: '删除',
          rejectLabel: '取消',
          acceptClass: 'p-button-danger',
          accept: async () => {
            try {
              await collectionsStore.deleteCollection(collection.id);
              const newExpandedKeys = { ...expandedKeys.value };
              delete newExpandedKeys[`collection-${collection.id}`];
              expandedKeys.value = newExpandedKeys;
            } catch (error) {
              console.error('Failed to delete collection:', error);
            }
          }
        });
      }
      break;
      
    case 'export':
      if (collection && !folder && !request) {
        await handleExportCollection(collection);
      }
      break;
      
    case 'import':
      await handleImportCollection();
      break;
  }
};

const handleExportCollection = async (collection) => {
  try {
    // Load all requests in the collection
    const requestIds = collectAllRequestIds(collection);
    const requests = await requestsStore.loadMultipleRequests(requestIds);
    
    // Export
    await importExportService.exportCollection(collection, requests);
    
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Success',
        detail: `Collection "${collection.name}" exported successfully`,
        life: 3000
      });
    }
  } catch (error) {
    console.error('Failed to export collection:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to export collection',
        life: 3000
      });
    }
  }
};

const handleImportCollection = async () => {
  try {
    const result = await importExportService.importCollection();
    
    if (!result) {
      return; // User cancelled
    }
    
    const { collection, requests } = result;
    
    // Save collection
    await collectionsStore.createCollection(collection.name, collection.description);
    const savedCollection = collectionsStore.collections.find(c => c.name === collection.name);
    
    if (!savedCollection) {
      throw new Error('Failed to create collection');
    }
    
    // Update collection with imported structure
    await collectionsStore.updateCollection(savedCollection.id, {
      folders: collection.folders,
      requests: collection.requests
    });
    
    // Save all requests
    for (const request of requests) {
      request.collectionId = savedCollection.id;
      await requestsStore.saveRequest(request);
    }
    
    // Expand the imported collection
    expandedKeys.value = {
      ...expandedKeys.value,
      [`collection-${savedCollection.id}`]: true
    };
    
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Success',
        detail: `Collection "${collection.name}" imported successfully`,
        life: 3000
      });
    }
  } catch (error) {
    console.error('Failed to import collection:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to import collection',
        life: 3000
      });
    }
  }
};

const collectAllRequestIds = (item) => {
  const ids = [];
  
  // Collect request IDs from current level
  if (item.requests && Array.isArray(item.requests)) {
    ids.push(...item.requests.map(r => r.id));
  }
  
  // Recursively collect from folders
  if (item.folders && Array.isArray(item.folders)) {
    for (const folder of item.folders) {
      ids.push(...collectAllRequestIds(folder));
    }
  }
  
  return ids;
};

const getDialogTitle = () => {
  return dialogMode.value === 'collection' ? '新建 Collection' : '新建 Folder';
};

const getDialogLabel = () => {
  return dialogMode.value === 'collection' ? 'Collection 名称' : 'Folder 名称';
};

const getDialogPlaceholder = () => {
  return dialogMode.value === 'collection' ? '输入 Collection 名称' : '输入 Folder 名称';
};

// Get currently selected collection/folder context
const getSelectedContext = () => {
  // Check if there's a selection
  if (!selectedKeys.value || Object.keys(selectedKeys.value).length === 0) {
    console.log('[getSelectedContext] No selection');
    return null;
  }
  
  const selectedKey = Object.keys(selectedKeys.value)[0];
  console.log('[getSelectedContext] Selected key:', selectedKey);
  
  // 使用 '/' 分割 key（与 buildTreeNode 保持一致）
  const keyParts = selectedKey.split('/');
  console.log('[getSelectedContext] Key parts:', keyParts);
  
  // keyParts[0] = 'collection' or 'folder'
  // keyParts[1] = collection ID
  // keyParts[2+] = folder IDs (可能有多层)
  
  // Find the collection
  const collectionId = keyParts[1];
  const collection = collections.value.find(c => String(c.id) === collectionId);
  
  if (!collection) {
    console.log('[getSelectedContext] Collection not found:', collectionId);
    return null;
  }
  
  console.log('[getSelectedContext] Found collection:', collection.name);
  
  // Check if it's a top-level collection (format: collection/{id})
  if (keyParts[0] === 'collection' && keyParts.length === 2) {
    console.log('[getSelectedContext] Top-level collection selected');
    return { collection, folder: null };
  }
  
  // Check if it's a folder (format: collection/{collectionId}/{folderId}/...)
  if (keyParts.length > 2) {
    // 递归查找文件夹对象
    const findFolderByPath = (folders, pathParts, startIndex) => {
      if (startIndex >= pathParts.length) {
        return null;
      }
      
      const currentFolderId = pathParts[startIndex];
      const folder = folders.find(f => String(f.id) === currentFolderId);
      
      if (!folder) {
        return null;
      }
      
      // 如果这是最后一个 ID，返回这个 folder
      if (startIndex === pathParts.length - 1) {
        return folder;
      }
      
      // 否则继续在子文件夹中查找
      if (folder.folders && folder.folders.length > 0) {
        return findFolderByPath(folder.folders, pathParts, startIndex + 1);
      }
      
      return null;
    };
    
    // 从 keyParts[2] 开始是 folder IDs
    const folderPath = keyParts.slice(2);
    const folder = findFolderByPath(collection.folders || [], folderPath, 0);
    
    if (folder) {
      console.log('[getSelectedContext] Folder selected:', folder.name);
      return { collection, folder };
    }
  }
  
  // Default to collection level
  console.log('[getSelectedContext] Default to collection level');
  return { collection, folder: null };
};

// 选中指定的请求节点
const selectRequestNode = (requestId, collectionId, folderId) => {
  if (!requestId || !collectionId) {
    return;
  }
  
  const collection = collections.value.find(c => c.id === collectionId);
  if (!collection) {
    return;
  }
  
  // 检查请求是否在 collection 中
  const requestExists = (target) => {
    if (target.requests && target.requests.some(r => r.id === requestId)) {
      return true;
    }
    if (target.folders) {
      for (const folder of target.folders) {
        if (requestExists(folder)) {
          return true;
        }
      }
    }
    return false;
  };
  
  if (!requestExists(collection)) {
    selectedKeys.value = {};
    return;
  }
  
  // 构建请求节点的 key
  let requestKey = `collection/${collectionId}`;
  
  if (folderId) {
    const folderPath = findFolderPath(collection.folders || [], folderId);
    if (folderPath) {
      requestKey += `/${folderPath.join('/')}`;
    } else {
      return;
    }
  }
  
  requestKey += `/request/${requestId}`;
  
  // 展开所有父节点
  const parts = requestKey.split('/');
  const newExpandedKeys = { ...expandedKeys.value };
  
  newExpandedKeys[`collection/${parts[1]}`] = true;
  
  for (let i = 2; i < parts.length - 2; i++) {
    const parentKey = parts.slice(0, i + 1).join('/');
    newExpandedKeys[parentKey] = true;
  }
  
  expandedKeys.value = newExpandedKeys;
  selectedKeys.value = { [requestKey]: true };
};

// 查找 folder 的完整路径（返回 folder ID 数组）
const findFolderPath = (folders, targetFolderId, currentPath = []) => {
  for (const folder of folders) {
    const newPath = [...currentPath, folder.id];
    
    if (folder.id === targetFolderId) {
      return newPath;
    }
    
    if (folder.folders && folder.folders.length > 0) {
      const found = findFolderPath(folder.folders, targetFolderId, newPath);
      if (found) {
        return found;
      }
    }
  }
  return null;
};

defineExpose({
  handleMenuAction,
  openCreateDialog,
  addRequestToCollection,
  collections,
  getSelectedContext,
  selectRequestNode
});
</script>

<template>
  <div class="p-2">
    <div class="mb-2 flex gap-2">
      <Button 
        @click="openCreateDialog('collection')"
        label="新建 Collection"
        icon="pi pi-plus"
        size="small"
        class="flex-1"
      />
      <Button 
        @click="handleImportCollection"
        icon="pi pi-upload"
        size="small"
        severity="secondary"
        title="导入 Collection"
      />
    </div>
    
    <div 
      v-if="treeNodes.length === 0" 
      class="text-surface-500 dark:text-surface-400 text-xs text-center py-4"
    >
      {{ searchQuery ? '未找到匹配的 Collection' : '暂无 Collection' }}
    </div>
    
    <div 
      v-else
      class="tree-container"
    >
      <Tree 
        :value="treeNodes"
        v-model:expandedKeys="expandedKeys"
        v-model:selectionKeys="selectedKeys"
        selectionMode="single"
        class="w-full"
        @node-contextmenu="onNodeContextMenu"
      >
        <template #default="slotProps">
          <div class="flex items-center gap-2 flex-1 min-w-0">
            <span 
              v-if="slotProps.node.data.type === 'request'" 
              class="method-badge"
              :class="getMethodColor(slotProps.node.data.method)"
            >
              {{ (slotProps.node.data.method || 'get').toLowerCase() }}
            </span>
            <span class="node-label flex-1 overflow-hidden text-ellipsis whitespace-nowrap">
              {{ slotProps.node.label }}
            </span>
            <span 
              v-if="slotProps.node.data.type !== 'request' && getTotalRequestCount(slotProps.node.data) > 0" 
              class="text-surface-500 dark:text-surface-400 text-xs"
            >
              ({{ getTotalRequestCount(slotProps.node.data) }})
            </span>
          </div>
        </template>
      </Tree>
    </div>

    <ContextMenu ref="contextMenu" :model="menuItems" />

    <Dialog 
      v-model:visible="showCreateDialog"
      :header="getDialogTitle()"
      :modal="true"
      :style="{ width: '25rem' }"
    >
      <div class="flex flex-col gap-4">
        <div>
          <label for="itemName" class="block text-sm font-medium mb-2">
            {{ getDialogLabel() }}
          </label>
          <InputText 
            id="itemName"
            v-model="newItemName"
            :placeholder="getDialogPlaceholder()"
            class="w-full"
            @keyup.enter="createItem"
            autofocus
          />
        </div>
        <div v-if="dialogMode === 'collection'">
          <label for="itemDescription" class="block text-sm font-medium mb-2">
            描述（可选）
          </label>
          <InputText 
            id="itemDescription"
            v-model="newItemDescription"
            placeholder="输入描述"
            class="w-full"
          />
        </div>
      </div>
      
      <template #footer>
        <Button label="取消" severity="secondary" @click="showCreateDialog = false" />
        <Button 
          label="创建" 
          @click="createItem"
          :disabled="!newItemName.trim()"
        />
      </template>
    </Dialog>

    <Dialog 
      v-model:visible="showRenameDialog"
      :header="`重命名 ${renamingItem?.type === 'collection' ? 'Collection' : renamingItem?.type === 'folder' ? 'Folder' : 'Request'}`"
      :modal="true"
      :style="{ width: '25rem' }"
    >
      <div class="flex flex-col gap-4">
        <div>
          <label for="renameItemName" class="block text-sm font-medium mb-2">
            名称
          </label>
          <InputText 
            id="renameItemName"
            v-model="renameItemName"
            placeholder="输入新名称"
            class="w-full"
            @keyup.enter="renameItem"
            autofocus
          />
        </div>
      </div>
      
      <template #footer>
        <Button label="取消" severity="secondary" @click="showRenameDialog = false" />
        <Button 
          label="重命名" 
          @click="renameItem"
          :disabled="!renameItemName.trim() || renameItemName.trim() === renamingItem?.item?.name"
        />
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
.tree-container {
  -webkit-user-select: none;
  user-select: none;
}

:deep(.p-tree) {
  border: none;
  padding: 0;
  background: transparent;
}

:deep(.p-tree .p-tree-node) {
  padding: 0.125rem 0;
}

:deep(.p-tree .p-tree-node-content) {
  padding: 0.5rem;
  border-radius: 6px;
  transition: background-color 0.2s;
}

:deep(.p-tree .p-tree-node-content:hover) {
  background-color: var(--p-surface-100);
}

:deep(.p-dark .p-tree .p-tree-node-content:hover) {
  background-color: var(--p-surface-800);
}

:deep(.p-tree .p-tree-node-content.p-highlight) {
  background-color: var(--p-highlight-background);
  color: var(--p-highlight-color);
}

:deep(.p-tree .p-tree-node-content.p-highlight *) {
  color: var(--p-highlight-color);
}

:deep(.p-tree .p-tree-node-children) {
  padding: 0 0 0 1rem;
}

:deep(.p-tree > .p-tree-node > .p-tree-node-content) {
  margin-left: -0.5rem;
}

:deep(.p-tree .p-tree-node-toggle-button) {
  width: 2rem;
  height: 2rem;
  margin-right: 0.5rem;
}

:deep(.p-tree .p-tree-node-icon) {
  margin-right: 0.5rem;
}

.method-badge {
  font-weight: 600;
  font-size: 10px;
  text-transform: uppercase;
  padding: 2px 6px;
  border-radius: 3px;
  flex-shrink: 0;
}

.node-label {
  font-size: 0.875rem;
}
</style>
