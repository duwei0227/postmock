<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
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

const emit = defineEmits(['add-request', 'open-request', 'request-added', 'request-deleted', 'request-duplicated']);

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
      { 
        label: 'Duplicate', 
        icon: 'pi pi-copy', 
        command: () => handleDuplicate(),
        shortcut: 'Ctrl+D'
      },
      { label: 'Rename', icon: 'pi pi-pencil', command: () => handleRename() },
      { separator: true },
      { 
        label: 'Delete', 
        icon: 'pi pi-trash', 
        class: 'text-red-600', 
        command: () => handleDelete(),
        shortcut: 'Delete'
      }
    );
  } else {
    items.push(
      { label: 'Add Request', icon: 'pi pi-plus', command: () => handleAddRequest() },
      { label: 'Add Folder', icon: 'pi pi-folder-plus', command: () => handleAddFolder() },
      { separator: true },
      { 
        label: 'Duplicate', 
        icon: 'pi pi-copy', 
        command: () => handleDuplicate(),
        shortcut: 'Ctrl+D'
      },
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
      { 
        label: 'Delete', 
        icon: 'pi pi-trash', 
        class: 'text-red-600', 
        command: () => handleDelete(),
        shortcut: 'Delete'
      }
    );
  }
  
  return items;
});

// Event handlers
const onNodeSelect = (node) => {
  // 如果是 request 类型，直接打开
  if (node.data.type === 'request') {
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
    // 深拷贝节点，避免引用问题
    contextMenuNode.value = {
      key: node.key,
      label: node.label,
      data: JSON.parse(JSON.stringify(node.data)),
      icon: node.icon,
      children: node.children
    };
    contextMenu.value.show(event);
  }
};

// 节点右键菜单处理（在模板中使用）
const onNodeContextMenu = (node, event) => {
  event.preventDefault();
  event.stopPropagation();
  
  // 深拷贝节点，避免引用问题
  contextMenuNode.value = {
    key: node.key,
    label: node.label,
    data: JSON.parse(JSON.stringify(node.data)),
    icon: node.icon,
    children: node.children
  };
  
  contextMenu.value.show(event);
};

// 禁用方向键导航
const onTreeKeyDown = (event) => {
  // 阻止方向键的默认行为
  if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(event.key)) {
    event.preventDefault();
    event.stopPropagation();
  }
};

// 全局键盘快捷键处理
const handleKeyDown = (event) => {
  // 检查是否有选中的节点
  const selectedKey = Object.keys(selectedKeys.value)[0];
  if (!selectedKey) return;
  
  // 查找选中的节点
  const findNodeByKey = (nodes, key) => {
    for (const node of nodes) {
      if (node.key === key) return node;
      if (node.children && node.children.length > 0) {
        const found = findNodeByKey(node.children, key);
        if (found) return found;
      }
    }
    return null;
  };
  
  const selectedNode = findNodeByKey(treeNodes.value, selectedKey);
  if (!selectedNode) return;
  
  // Ctrl+D: Duplicate
  if (event.ctrlKey && event.key === 'd') {
    event.preventDefault();
    event.stopPropagation();
    
    // 设置 contextMenuNode 为选中的节点
    contextMenuNode.value = {
      key: selectedNode.key,
      label: selectedNode.label,
      data: JSON.parse(JSON.stringify(selectedNode.data)),
      icon: selectedNode.icon,
      children: selectedNode.children
    };
    
    handleDuplicate();
  }
  
  // Delete: Delete
  if (event.key === 'Delete') {
    event.preventDefault();
    event.stopPropagation();
    
    // 设置 contextMenuNode 为选中的节点
    contextMenuNode.value = {
      key: selectedNode.key,
      label: selectedNode.label,
      data: JSON.parse(JSON.stringify(selectedNode.data)),
      icon: selectedNode.icon,
      children: selectedNode.children
    };
    
    handleDelete();
  }
};

// 挂载和卸载键盘事件监听器
onMounted(() => {
  window.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown);
});

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
    // 只传递必要的 request 信息，不包含任何临时属性
    emit('open-request', {
      request: {
        id: node.data.id,
        name: node.data.name,
        method: node.data.method,
        url: node.data.url
      },
      collection,
      folder
    });
  }
};

const handleAddRequest = () => {
  if (!contextMenuNode.value) return;
  const { collection, folder } = getCollectionAndFolder(contextMenuNode.value);
  
  // 发出事件，让 MainContent 创建请求
  emit('add-request', {
    collection,
    folder,
    name: `New Request`
  });
  
  // 清除 contextMenuNode 引用
  contextMenuNode.value = null;
};

const handleAddFolder = () => {
  if (!contextMenuNode.value) return;
  const { collection, folder } = getCollectionAndFolder(contextMenuNode.value);
  dialogMode.value = 'folder';
  showCreateDialog.value = true;
  newItemName.value = '';
  newItemDescription.value = '';
  
  // 注意：不要在这里清除 contextMenuNode，因为 createItem 函数还需要使用它
};

const handleDuplicate = async () => {
  if (!contextMenuNode.value) return;
  const node = contextMenuNode.value;
  
  // 深拷贝节点数据，避免引用问题
  const nodeData = JSON.parse(JSON.stringify(node.data));
  
  const { collection, folder } = getCollectionAndFolder(node);
  
  if (nodeData.type === 'request') {
    await duplicateRequest(collection, nodeData, folder);
  } else if (nodeData.type === 'folder') {
    await duplicateFolder(collection, nodeData);
  } else if (nodeData.type === 'collection') {
    await duplicateCollection(nodeData);
  }
  
  // 清除 contextMenuNode 引用
  contextMenuNode.value = null;
};

const handleRename = () => {
  if (!contextMenuNode.value) return;
  // 深拷贝 node.data，避免引用问题
  renamingItem.value = JSON.parse(JSON.stringify(contextMenuNode.value.data));
  renameItemName.value = contextMenuNode.value.data.name;
  showRenameDialog.value = true;
};

const handleDelete = () => {
  if (!contextMenuNode.value) return;
  const node = contextMenuNode.value;
  
  // 深拷贝节点数据，避免引用问题
  const nodeData = JSON.parse(JSON.stringify(node.data));
  const nodeKey = node.key;
  
  const { collection } = getCollectionAndFolder(node);
  
  confirm.require({
    message: `确定要删除 "${nodeData.name}" 吗？`,
    header: '确认删除',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: '删除',
    rejectLabel: '取消',
    acceptClass: 'p-button-danger',
    accept: async () => {
      if (nodeData.type === 'request') {
        await collectionsStore.removeRequestReference(collection.id, nodeData.id);
        await requestsStore.deleteRequest(nodeData.id);
        // 通知 MainContent 关闭对应的 Tab
        emit('request-deleted', nodeData.id);
      } else if (nodeData.type === 'folder') {
        // 收集 folder 中的所有 request IDs
        const requestIds = collectAllRequestIds(nodeData);
        await collectionsStore.deleteFolder(collection.id, nodeData.id);
        // 通知 MainContent 关闭所有相关的 Tabs
        requestIds.forEach(id => emit('request-deleted', id));
      } else if (nodeData.type === 'collection') {
        // 收集 collection 中的所有 request IDs
        const requestIds = collectAllRequestIds(nodeData);
        await collectionsStore.deleteCollection(nodeData.id);
        // 通知 MainContent 关闭所有相关的 Tabs
        requestIds.forEach(id => emit('request-deleted', id));
      }
      
      // 清除 contextMenuNode 引用
      contextMenuNode.value = null;
    }
  });
};

const handleShare = async () => {
  if (!contextMenuNode.value) return;
  
  // 深拷贝 collection 数据，避免引用问题
  const collection = JSON.parse(JSON.stringify(contextMenuNode.value.data));
  
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
  
  // 清除 contextMenuNode 引用
  contextMenuNode.value = null;
};

const handleExport = async () => {
  if (!contextMenuNode.value) return;
  
  // 深拷贝 collection 数据，避免引用问题
  const collection = JSON.parse(JSON.stringify(contextMenuNode.value.data));
  
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
  
  // 清除 contextMenuNode 引用
  contextMenuNode.value = null;
};

// Duplicate functions
const duplicateRequest = async (collection, request, folder) => {
  try {
    const fullRequest = await requestsStore.loadRequest(request.id);
    if (!fullRequest) return;
    
    // 使用 JSON.parse(JSON.stringify()) 创建完全独立的深拷贝
    const clonedRequest = JSON.parse(JSON.stringify(fullRequest));
    
    // 更新克隆请求的属性
    const newRequest = {
      ...clonedRequest,
      id: generateId(),
      name: `${clonedRequest.name} (Copy)`,
      collectionId: collection.id,
      folderId: folder?.id || null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    // 清除所有临时属性（以 _ 开头的属性）
    Object.keys(newRequest).forEach(key => {
      if (key.startsWith('_')) {
        delete newRequest[key];
      }
    });
    
    await requestsStore.saveRequest(newRequest);
    await collectionsStore.addRequestReference(
      collection.id,
      newRequest.id,
      newRequest.name,
      newRequest.method,
      newRequest.url,
      folder?.id
    );
    
    // 等待 Vue 更新 DOM 和 computed 属性
    await new Promise(resolve => setTimeout(resolve, 100));
    
    // 自动选中新创建的 request
    selectRequestNode(newRequest.id, collection.id, folder?.id);
    
    // 通知 MainContent 打开新创建的 request
    emit('request-duplicated', newRequest.id);
    
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
    
    // 找到 folder 的父 folder（如果有）
    const { folder: parentFolder } = getCollectionAndFolder(contextMenuNode.value);
    
    // addFolder 返回新创建的 folder 对象
    const createdFolder = await collectionsStore.addFolder(
      collection.id, 
      newFolder.name, 
      parentFolder?.id || null
    );
    
    if (createdFolder) {
      // 更新 folderIdMap，将源 folder 的 ID 映射到实际创建的 folder ID
      folderIdMap.set(folder.id, createdFolder.id);
      
      // 更新新创建的 folder，添加子 folders 和 requests
      await collectionsStore.updateFolder(collection.id, createdFolder.id, {
        folders: newFolder.folders,
        requests: newFolder.requests
      });
      
      // 复制所有 requests 的完整数据
      const requestIds = collectAllRequestIds(folder);
      const requests = await requestsStore.loadMultipleRequests(requestIds);
      
      for (const request of requests) {
        const newRequestId = requestIdMap.get(request.id);
        if (newRequestId) {
          // 使用深拷贝创建完全独立的请求副本
          const clonedRequest = JSON.parse(JSON.stringify(request));
          
          const newRequest = {
            ...clonedRequest,
            id: newRequestId,
            collectionId: collection.id,
            folderId: request.folderId ? folderIdMap.get(request.folderId) : createdFolder.id,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
          };
          
          // 清除所有临时属性（以 _ 开头的属性）
          Object.keys(newRequest).forEach(key => {
            if (key.startsWith('_')) {
              delete newRequest[key];
            }
          });
          
          await requestsStore.saveRequest(newRequest);
        }
      }
      
      // 重新加载 collections 以确保数据同步
      await collectionsStore.loadCollections();
      
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
        // 使用深拷贝创建完全独立的请求副本
        const clonedRequest = JSON.parse(JSON.stringify(request));
        
        const newRequest = {
          ...clonedRequest,
          id: newRequestId,
          collectionId: newCollection.id,
          folderId: request.folderId ? folderIdMap.get(request.folderId) : null,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        };
        
        // 清除所有临时属性（以 _ 开头的属性）
        Object.keys(newRequest).forEach(key => {
          if (key.startsWith('_')) {
            delete newRequest[key];
          }
        });
        
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

// 检查请求名称是否在同一目录下重复
const isRequestNameDuplicate = (collectionId, folderId, requestName, excludeRequestId = null) => {
  const collection = collections.value.find(c => c.id === collectionId);
  if (!collection) return false;
  
  // 获取目标目录下的所有请求
  let requests = [];
  if (folderId) {
    // 在指定 folder 中查找
    const findFolder = (folders, targetId) => {
      for (const folder of folders) {
        if (folder.id === targetId) return folder;
        if (folder.folders && folder.folders.length > 0) {
          const found = findFolder(folder.folders, targetId);
          if (found) return found;
        }
      }
      return null;
    };
    const folder = findFolder(collection.folders || [], folderId);
    requests = folder?.requests || [];
  } else {
    // 在 collection 根目录下查找
    requests = collection.requests || [];
  }
  
  // 检查是否有同名请求（排除当前请求自己）
  return requests.some(req => 
    req.name.toLowerCase() === requestName.toLowerCase() && 
    req.id !== excludeRequestId
  );
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
      // 先加载完整的 request 数据
      const fullRequest = await requestsStore.loadRequest(item.id);
      if (!fullRequest) {
        console.error('Request not found:', item.id);
        if (window.$toast) {
          window.$toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Request not found',
            life: 3000
          });
        }
        return;
      }
      
      // 检查名称是否重复
      if (isRequestNameDuplicate(fullRequest.collectionId, fullRequest.folderId, newName, fullRequest.id)) {
        if (window.$toast) {
          window.$toast.add({
            severity: 'warn',
            summary: 'Duplicate Name',
            detail: 'A request with this name already exists in the same location',
            life: 3000
          });
        }
        return;
      }
      
      // 更新完整的 request 对象
      const updatedRequest = {
        ...fullRequest,
        name: newName,
        updatedAt: new Date().toISOString()
      };
      await requestsStore.saveRequest(updatedRequest);
      
      // 更新 collection 中的引用
      if (fullRequest.collectionId) {
        await collectionsStore.updateRequestReference(
          fullRequest.collectionId,
          fullRequest.id,
          newName,
          fullRequest.method,
          fullRequest.url,
          fullRequest.folderId
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

// 选中指定的 request 节点
const selectRequestNode = (requestId, collectionId, folderId) => {
  // 构建节点的 key
  let key = `collection/${collectionId}`;
  
  if (folderId) {
    // 需要找到 folder 的完整路径
    const collection = collections.value.find(c => c.id === collectionId);
    if (collection) {
      const folderPath = findFolderPath(collection.folders || [], folderId);
      if (folderPath) {
        key = `${key}/${folderPath.join('/')}`;
      }
    }
  }
  
  key = `${key}/request/${requestId}`;
  
  // 展开父节点
  const expandParents = (nodeKey) => {
    const parts = nodeKey.split('/');
    const newExpandedKeys = { ...expandedKeys.value };
    
    // 展开所有父节点
    for (let i = 2; i < parts.length - 1; i += 2) {
      const parentKey = parts.slice(0, i + 1).join('/');
      newExpandedKeys[parentKey] = true;
    }
    
    expandedKeys.value = newExpandedKeys;
  };
  
  expandParents(key);
  
  // 选中节点
  selectedKeys.value = { [key]: true };
};

// 查找 folder 的路径
const findFolderPath = (folders, targetId, currentPath = []) => {
  for (const folder of folders) {
    const path = [...currentPath, folder.id];
    if (folder.id === targetId) {
      return path;
    }
    if (folder.folders && folder.folders.length > 0) {
      const found = findFolderPath(folder.folders, targetId, path);
      if (found) return found;
    }
  }
  return null;
};

// 清除选中状态
const clearSelection = () => {
  selectedKeys.value = {};
};

// Expose methods
defineExpose({
  collections,
  selectRequestNode,
  clearSelection
});
</script>

<template>
  <div class="p-2 bg-surface-0 dark:bg-surface-950">
    <div class="mb-2">
      <Button 
        @click="openCreateDialog('collection')"
        label="新建 Collection"
        icon="pi pi-plus"
        size="small"
        class="w-full"
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
      @keydown="onTreeKeyDown"
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

    <ContextMenu ref="contextMenu" :model="menuItems">
      <template #item="{ item, props }">
        <a v-ripple class="flex items-center" v-bind="props.action">
          <span :class="item.icon" />
          <span class="ml-2">{{ item.label }}</span>
          <span v-if="item.shortcut" class="ml-auto pl-4 text-xs opacity-60 font-mono">
            {{ item.shortcut }}
          </span>
        </a>
      </template>
    </ContextMenu>

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

/* ContextMenu 快捷键样式 */
:deep(.p-contextmenu .p-menuitem-link) {
  display: flex;
  align-items: center;
  width: 100%;
}

:deep(.p-contextmenu .p-menuitem-link .ml-auto) {
  margin-left: auto;
}
</style>
