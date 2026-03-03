<script setup>
import { ref, computed, watch } from 'vue';
import { useConfirm } from 'primevue/useconfirm';
import { useCollectionsStore } from '@/stores/collections';
import { useRequestsStore } from '@/stores/requests';
import { importExportService } from '@/services/import-export';
import { generateId } from '@/utils/id-generator';

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

// Store
const collections = computed(() => collectionsStore.collections);

// Tree state
const expandedKeys = ref({});
const selectedKeys = ref({});

// Dialog state
const showCreateDialog = ref(false);
const dialogMode = ref('collection');
const newItemName = ref('');
const newItemDescription = ref('');

// Rename dialog
const showRenameDialog = ref(false);
const renameItemName = ref('');
const renamingItem = ref(null);

// Context menu
const contextMenu = ref(null);
const contextMenuNode = ref(null);

// 将 collections 转换为 Tree 节点格式
const treeNodes = computed(() => {
  const convertToTreeNode = (item, type = 'collection', parentKey = '') => {
    const key = parentKey ? `${parentKey}/${item.id}` : `${type}/${item.id}`;
    
    const node = {
      key,
      label: item.name,
      data: { ...item, type },
      icon: type === 'collection' ? 'pi pi-folder' : 'pi pi-folder-open',
      children: []
    };

    // 添加 requests
    if (item.requests && item.requests.length > 0) {
      node.children.push(...item.requests.map(req => ({
        key: `${key}/request/${req.id}`,
        label: req.name,
        data: { ...req, type: 'request' },
        icon: 'pi pi-file',
        children: []
      })));
    }

    // 添加 folders
    if (item.folders && item.folders.length > 0) {
      node.children.push(...item.folders.map(folder => 
        convertToTreeNode(folder, 'folder', key)
      ));
    }

    return node;
  };

  if (!props.searchQuery) {
    return collections.value.map(c => convertToTreeNode(c));
  }

  const query = props.searchQuery.toLowerCase();
  return collections.value
    .filter(c => c.name.toLowerCase().includes(query))
    .map(c => convertToTreeNode(c));
});

// Context menu items
const menuItems = computed(() => {
  if (!contextMenuNode.value) return [];
  
  const node = contextMenuNode.value;
  const type = node.data.type;
  const items = [];
  
  if (type === 'request') {
    items.push(
      { label: 'Open', icon: 'pi pi-external-link', command: () => handleOpen() },
      { separator: true },
      { label: 'Duplicate', icon: 'pi pi-copy', command: () => handleDuplicate() },
      { label: 'Rename', icon: 'pi pi-pencil', command: () => handleRename() },
      { separator: true },
      { label: 'Delete', icon: 'pi pi-trash', class: 'text-red-600', command: () => handleDelete() }
    );
  } else {
    items.push(
      { label: 'Add Request', icon: 'pi pi-plus', command: () => handleAddRequest() },
      { label: 'Add Folder', icon: 'pi pi-folder-plus', command: () => handleAddFolder() },
      { separator: true },
      { label: 'Duplicate', icon: 'pi pi-copy', command: () => handleDuplicate() },
      { label: 'Rename', icon: 'pi pi-pencil', command: () => handleRename() }
    );
    
    if (type === 'collection') {
      items.push(
        { label: 'Share', icon: 'pi pi-share-alt', command: () => handleShare() }
      );
    }
    
    items.push(
      { separator: true },
      { label: 'Export', icon: 'pi pi-download', command: () => handleExport() },
      { label: 'Delete', icon: 'pi pi-trash', class: 'text-red-600', command: () => handleDelete() }
    );
  }
  
  return items;
});

// Event handlers
const onNodeSelect = (node) => {
  // 双击检测
  const now = Date.now();
  const lastClick = node.lastClickTime || 0;
  node.lastClickTime = now;
  
  if (now - lastClick < 300 && node.data.type === 'request') {
    handleOpenRequest(node);
  }
};

const onTreeContextMenu = (event) => {
  event.preventDefault();
  event.stopPropagation();
  
  // 查找被右键点击的节点内容区域
  let target = event.target;
  while (target && !target.classList.contains('p-tree-node-content')) {
    target = target.parentElement;
    if (!target || target.classList.contains('p-tree')) break;
  }
  
  if (!target || !target.classList.contains('p-tree-node-content')) return;
  
  // 从节点内容中提取文本来匹配节点
  const textContent = target.textContent.trim();
  
  // 递归查找匹配的节点
  const findNodeByText = (nodes, text) => {
    for (const node of nodes) {
      // 对于 request 节点，文本包含 method badge，需要特殊处理
      const nodeText = node.data.type === 'request' 
        ? `${(node.data.method || 'get').toLowerCase()}${node.label}`
        : node.label;
      
      if (text.includes(node.label) || text === nodeText) {
        return node;
      }
      
      if (node.children && node.children.length > 0) {
        const found = findNodeByText(node.children, text);
        if (found) return found;
      }
    }
    return null;
  };
  
  const node = findNodeByText(treeNodes.value, textContent);
  
  if (node) {
    contextMenuNode.value = node;
    contextMenu.value.show(event);
  }
};

// 节点右键菜单处理（在模板中使用）
const onNodeContextMenu = (node, event) => {
  event.preventDefault();
  event.stopPropagation();
  contextMenuNode.value = node;
  contextMenu.value.show(event);
};

// Helper functions
const getCollectionAndFolder = (node) => {
  const keyParts = node.key.split('/');
  const collectionId = keyParts[1];
  const collection = collections.value.find(c => c.id === collectionId);
  
  if (!collection) return { collection: null, folder: null };
  
  if (node.data.type === 'folder') {
    return { collection, folder: node.data };
  }
  
  if (node.data.type === 'request') {
    const requestIndex = keyParts.findIndex(p => p === 'request');
    if (requestIndex > 2) {
      const folderIds = keyParts.slice(2, requestIndex);
      const folder = findFolderByPath(collection.folders || [], folderIds);
      return { collection, folder };
    }
  }
  
  return { collection, folder: null };
};

const findFolderByPath = (folders, folderIds) => {
  if (!folderIds || folderIds.length === 0) return null;
  const folder = folders.find(f => f.id === folderIds[0]);
  if (!folder) return null;
  if (folderIds.length === 1) return folder;
  return findFolderByPath(folder.folders || [], folderIds.slice(1));
};

// Action handlers
const handleOpen = () => {
  if (!contextMenuNode.value) return;
  handleOpenRequest(contextMenuNode.value);
};

const handleOpenRequest = (node) => {
  const { collection, folder } = getCollectionAndFolder(node);
  if (collection) {
    emit('open-request', {
      request: node.data,
      collection,
      folder
    });
  }
};

const handleAddRequest = () => {
  if (!contextMenuNode.value) return;
  const { collection, folder } = getCollectionAndFolder(contextMenuNode.value);
  emit('add-request', {
    collection,
    folder,
    name: `New Request in ${folder?.name || collection?.name}`
  });
};

const handleAddFolder = () => {
  if (!contextMenuNode.value) return;
  const { collection, folder } = getCollectionAndFolder(contextMenuNode.value);
  dialogMode.value = 'folder';
  showCreateDialog.value = true;
  newItemName.value = '';
  newItemDescription.value = '';
};

const handleDuplicate = async () => {
  if (!contextMenuNode.value) return;
  const node = contextMenuNode.value;
  const { collection, folder } = getCollectionAndFolder(node);
  
  if (node.data.type === 'request') {
    await duplicateRequest(collection, node.data, folder);
  } else if (node.data.type === 'folder') {
    await duplicateFolder(collection, node.data);
  } else if (node.data.type === 'collection') {
    await duplicateCollection(node.data);
  }
};

const handleRename = () => {
  if (!contextMenuNode.value) return;
  renamingItem.value = contextMenuNode.value.data;
  renameItemName.value = contextMenuNode.value.data.name;
  showRenameDialog.value = true;
};

const handleDelete = () => {
  if (!contextMenuNode.value) return;
  const node = contextMenuNode.value;
  const { collection } = getCollectionAndFolder(node);
  
  confirm.require({
    message: `确定要删除 "${node.data.name}" 吗？`,
    header: '确认删除',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: '删除',
    rejectLabel: '取消',
    acceptClass: 'p-button-danger',
    accept: async () => {
      if (node.data.type === 'request') {
        await collectionsStore.removeRequestReference(collection.id, node.data.id);
        await requestsStore.deleteRequest(node.data.id);
      } else if (node.data.type === 'folder') {
        await collectionsStore.deleteFolder(collection.id, node.data.id);
      } else if (node.data.type === 'collection') {
        await collectionsStore.deleteCollection(node.data.id);
      }
    }
  });
};

const handleShare = async () => {
  if (!contextMenuNode.value) return;
  const collection = contextMenuNode.value.data;
  
  try {
    const requestIds = collectAllRequestIds(collection);
    const requests = await requestsStore.loadMultipleRequests(requestIds);
    const shareData = {
      collection: {
        name: collection.name,
        description: collection.description,
        folders: collection.folders || [],
        requests: collection.requests || []
      },
      requests
    };
    
    await navigator.clipboard.writeText(JSON.stringify(shareData, null, 2));
    
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Success',
        detail: 'Collection copied to clipboard',
        life: 3000
      });
    }
  } catch (error) {
    console.error('Failed to share:', error);
  }
};

const handleExport = async () => {
  if (!contextMenuNode.value) return;
  const collection = contextMenuNode.value.data;
  
  try {
    const requestIds = collectAllRequestIds(collection);
    const requests = await requestsStore.loadMultipleRequests(requestIds);
    await importExportService.exportCollection(collection, requests);
    
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Success',
        detail: 'Collection exported',
        life: 3000
      });
    }
  } catch (error) {
    console.error('Failed to export:', error);
  }
};

// Duplicate functions
const duplicateRequest = async (collection, request, folder) => {
  try {
    const fullRequest = await requestsStore.loadRequest(request.id);
    if (!fullRequest) return;
    
    const newRequest = {
      ...fullRequest,
      id: generateId(),
      name: `${fullRequest.name} (Copy)`,
      collectionId: collection.id,
      folderId: folder?.id || null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    await requestsStore.saveRequest(newRequest);
    await collectionsStore.addRequestReference(
      collection.id,
      newRequest.id,
      newRequest.name,
      newRequest.method,
      newRequest.url,
      folder?.id
    );
    
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Success',
        detail: 'Request duplicated',
        life: 3000
      });
    }
  } catch (error) {
    console.error('Failed to duplicate request:', error);
  }
};

const duplicateFolder = async (collection, folder) => {
  try {
    const folderIdMap = new Map();
    const requestIdMap = new Map();
    
    const duplicateStructure = (sourceFolder) => {
      const newFolderId = generateId();
      folderIdMap.set(sourceFolder.id, newFolderId);
      
      return {
        id: newFolderId,
        name: `${sourceFolder.name} (Copy)`,
        folders: sourceFolder.folders ? sourceFolder.folders.map(f => duplicateStructure(f)) : [],
        requests: sourceFolder.requests ? sourceFolder.requests.map(req => {
          const newRequestId = generateId();
          requestIdMap.set(req.id, newRequestId);
          return { id: newRequestId, name: req.name, method: req.method, url: req.url };
        }) : []
      };
    };
    
    const newFolder = duplicateStructure(folder);
    await collectionsStore.addFolder(collection.id, newFolder.name, null);
    
    const updatedCollection = collections.value.find(c => c.id === collection.id);
    const createdFolder = updatedCollection.folders.find(f => f.name === newFolder.name);
    
    if (createdFolder) {
      await collectionsStore.updateFolder(collection.id, createdFolder.id, {
        folders: newFolder.folders,
        requests: newFolder.requests
      });
      
      const requestIds = collectAllRequestIds(folder);
      const requests = await requestsStore.loadMultipleRequests(requestIds);
      
      for (const request of requests) {
        const newRequestId = requestIdMap.get(request.id);
        if (newRequestId) {
          const newRequest = {
            ...request,
            id: newRequestId,
            collectionId: collection.id,
            folderId: request.folderId ? folderIdMap.get(request.folderId) : createdFolder.id,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
          };
          await requestsStore.saveRequest(newRequest);
        }
      }
      
      if (window.$toast) {
        window.$toast.add({
          severity: 'success',
          summary: 'Success',
          detail: 'Folder duplicated',
          life: 3000
        });
      }
    }
  } catch (error) {
    console.error('Failed to duplicate folder:', error);
  }
};

const duplicateCollection = async (collection) => {
  try {
    const newCollection = await collectionsStore.createCollection(
      `${collection.name} (Copy)`,
      collection.description
    );
    
    const requestIds = collectAllRequestIds(collection);
    const requests = await requestsStore.loadMultipleRequests(requestIds);
    
    const folderIdMap = new Map();
    const requestIdMap = new Map();
    
    const duplicateFolders = (folders) => {
      return folders.map(folder => {
        const newFolderId = generateId();
        folderIdMap.set(folder.id, newFolderId);
        
        return {
          id: newFolderId,
          name: folder.name,
          folders: folder.folders ? duplicateFolders(folder.folders) : [],
          requests: folder.requests ? folder.requests.map(req => {
            const newRequestId = generateId();
            requestIdMap.set(req.id, newRequestId);
            return { id: newRequestId, name: req.name, method: req.method, url: req.url };
          }) : []
        };
      });
    };
    
    const newFolders = collection.folders ? duplicateFolders(collection.folders) : [];
    const newRequests = collection.requests ? collection.requests.map(req => {
      const newRequestId = generateId();
      requestIdMap.set(req.id, newRequestId);
      return { id: newRequestId, name: req.name, method: req.method, url: req.url };
    }) : [];
    
    await collectionsStore.updateCollection(newCollection.id, {
      folders: newFolders,
      requests: newRequests
    });
    
    for (const request of requests) {
      const newRequestId = requestIdMap.get(request.id);
      if (newRequestId) {
        const newRequest = {
          ...request,
          id: newRequestId,
          collectionId: newCollection.id,
          folderId: request.folderId ? folderIdMap.get(request.folderId) : null,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        };
        await requestsStore.saveRequest(newRequest);
      }
    }
    
    expandedKeys.value = {
      ...expandedKeys.value,
      [`collection/${newCollection.id}`]: true
    };
    
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Success',
        detail: 'Collection duplicated',
        life: 3000
      });
    }
  } catch (error) {
    console.error('Failed to duplicate collection:', error);
  }
};

// Rename
const renameItem = async () => {
  if (!renameItemName.value.trim() || !renamingItem.value) return;
  
  const item = renamingItem.value;
  const newName = renameItemName.value.trim();
  
  try {
    if (item.type === 'collection') {
      await collectionsStore.updateCollection(item.id, { name: newName });
    } else if (item.type === 'folder') {
      const collection = collections.value.find(c => 
        findFolderInCollection(c, item.id)
      );
      if (collection) {
        await collectionsStore.updateFolder(collection.id, item.id, { name: newName });
      }
    } else if (item.type === 'request') {
      const updatedRequest = {
        ...item,
        name: newName,
        updatedAt: new Date().toISOString()
      };
      await requestsStore.saveRequest(updatedRequest);
      
      if (item.collectionId) {
        await collectionsStore.updateRequestReference(
          item.collectionId,
          item.id,
          newName,
          item.method,
          item.url,
          item.folderId
        );
      }
    }
    
    showRenameDialog.value = false;
    renamingItem.value = null;
    renameItemName.value = '';
    
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Success',
        detail: 'Renamed successfully',
        life: 3000
      });
    }
  } catch (error) {
    console.error('Failed to rename:', error);
  }
};

// Helper functions
const findFolderInCollection = (collection, folderId) => {
  const search = (folders) => {
    for (const folder of folders) {
      if (folder.id === folderId) return true;
      if (folder.folders && search(folder.folders)) return true;
    }
    return false;
  };
  return collection ? search(collection.folders || []) : false;
};

const collectAllRequestIds = (item) => {
  const ids = [];
  if (item.requests && Array.isArray(item.requests)) {
    ids.push(...item.requests.map(r => r.id));
  }
  if (item.folders && Array.isArray(item.folders)) {
    for (const folder of item.folders) {
      ids.push(...collectAllRequestIds(folder));
    }
  }
  return ids;
};

// Create dialog
const openCreateDialog = (mode = 'collection') => {
  dialogMode.value = mode;
  showCreateDialog.value = true;
  newItemName.value = '';
  newItemDescription.value = '';
};

const createItem = async () => {
  if (!newItemName.value.trim()) return;
  
  try {
    if (dialogMode.value === 'collection') {
      await collectionsStore.createCollection(
        newItemName.value.trim(),
        newItemDescription.value.trim()
      );
    } else if (dialogMode.value === 'folder' && contextMenuNode.value) {
      const { collection, folder } = getCollectionAndFolder(contextMenuNode.value);
      await collectionsStore.addFolder(
        collection.id,
        newItemName.value.trim(),
        folder?.id
      );
    }
    
    showCreateDialog.value = false;
    newItemName.value = '';
    newItemDescription.value = '';
  } catch (error) {
    console.error('Failed to create item:', error);
  }
};

// Import
const handleImportCollection = async () => {
  try {
    const result = await importExportService.importCollection();
    if (!result) return;
    
    const { collection, requests } = result;
    await collectionsStore.createCollection(collection.name, collection.description);
    const savedCollection = collectionsStore.collections.find(c => c.name === collection.name);
    
    if (savedCollection) {
      await collectionsStore.updateCollection(savedCollection.id, {
        folders: collection.folders,
        requests: collection.requests
      });
      
      for (const request of requests) {
        request.collectionId = savedCollection.id;
        await requestsStore.saveRequest(request);
      }
      
      if (window.$toast) {
        window.$toast.add({
          severity: 'success',
          summary: 'Success',
          detail: 'Collection imported',
          life: 3000
        });
      }
    }
  } catch (error) {
    console.error('Failed to import:', error);
  }
};

// Expose methods
defineExpose({
  collections
});
</script>

<template>
  <div class="p-2 bg-surface-0 dark:bg-surface-950">
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
      @contextmenu="onTreeContextMenu"
    >
      <Tree 
        :value="treeNodes"
        v-model:expandedKeys="expandedKeys"
        v-model:selectionKeys="selectedKeys"
        selectionMode="single"
        class="w-full"
        @node-select="onNodeSelect"
      >
        <template #default="slotProps">
          <div 
            class="flex items-center gap-2 flex-1 min-w-0"
            @contextmenu="onNodeContextMenu(slotProps.node, $event)"
          >
            <span 
              v-if="slotProps.node.data.type === 'request'" 
              class="method-badge"
              :class="{
                'text-green-600': slotProps.node.data.method === 'GET',
                'text-blue-600': slotProps.node.data.method === 'POST',
                'text-yellow-600': slotProps.node.data.method === 'PUT',
                'text-red-600': slotProps.node.data.method === 'DELETE',
                'text-purple-600': slotProps.node.data.method === 'PATCH'
              }"
            >
              {{ (slotProps.node.data.method || 'get').toLowerCase() }}
            </span>
            <span class="flex-1 overflow-hidden text-ellipsis whitespace-nowrap text-sm">
              {{ slotProps.node.label }}
            </span>
          </div>
        </template>
      </Tree>
    </div>

    <ContextMenu ref="contextMenu" :model="menuItems" />

    <Dialog 
      v-model:visible="showCreateDialog"
      :header="dialogMode === 'collection' ? '新建 Collection' : '新建 Folder'"
      :modal="true"
      :style="{ width: '25rem' }"
    >
      <div class="flex flex-col gap-4">
        <div>
          <label class="block text-sm font-medium mb-2">名称</label>
          <InputText 
            v-model="newItemName"
            placeholder="输入名称"
            class="w-full"
            @keyup.enter="createItem"
            autofocus
          />
        </div>
        <div v-if="dialogMode === 'collection'">
          <label class="block text-sm font-medium mb-2">描述（可选）</label>
          <InputText 
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
      header="重命名"
      :modal="true"
      :style="{ width: '25rem' }"
    >
      <div class="flex flex-col gap-4">
        <div>
          <label class="block text-sm font-medium mb-2">名称</label>
          <InputText 
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
          :disabled="!renameItemName.trim() || renameItemName.trim() === renamingItem?.name"
        />
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
:deep(.p-tree) {
  border: none;
  padding: 0;
  background: transparent;
}

.method-badge {
  font-weight: 600;
  font-size: 10px;
  text-transform: uppercase;
  padding: 2px 6px;
  border-radius: 3px;
  flex-shrink: 0;
}
</style>
