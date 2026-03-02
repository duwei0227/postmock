import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { storageService } from '@/services/storage';
import type { Collection, Folder, RequestReference } from '@/types/models';
import { generateId } from '@/utils/id-generator';

export const useCollectionsStore = defineStore('collections', () => {
  // State
  const collections = ref<Collection[]>([]);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  // Getters
  const getCollectionById = computed(() => {
    return (id: string) => collections.value.find(c => c.id === id);
  });

  const getCollectionByName = computed(() => {
    return (name: string) => collections.value.find(c => c.name === name);
  });

  // Actions
  async function loadCollections() {
    isLoading.value = true;
    error.value = null;
    try {
      collections.value = await storageService.loadCollections();
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load collections';
      console.error('Failed to load collections:', e);
    } finally {
      isLoading.value = false;
    }
  }

  async function createCollection(name: string, description?: string) {
    try {
      const collection: Collection = {
        id: generateId(),
        name,
        description: description || '',
        folders: [],
        requests: [],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      await storageService.saveCollection(collection);
      collections.value.push(collection);
      return collection;
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to create collection';
      console.error('Failed to create collection:', e);
      throw e;
    }
  }

  async function updateCollection(id: string, updates: Partial<Collection>) {
    try {
      const collection = collections.value.find(c => c.id === id);
      if (!collection) {
        throw new Error(`Collection ${id} not found`);
      }

      Object.assign(collection, updates, {
        updatedAt: new Date().toISOString()
      });

      await storageService.saveCollection(collection);
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to update collection';
      console.error('Failed to update collection:', e);
      throw e;
    }
  }

  async function deleteCollection(id: string) {
    try {
      await storageService.deleteCollection(id);
      const index = collections.value.findIndex(c => c.id === id);
      if (index !== -1) {
        collections.value.splice(index, 1);
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to delete collection';
      console.error('Failed to delete collection:', e);
      throw e;
    }
  }

  async function addFolder(collectionId: string, folderName: string, parentFolderId?: string) {
    try {
      const collection = collections.value.find(c => c.id === collectionId);
      if (!collection) {
        throw new Error(`Collection ${collectionId} not found`);
      }

      const newFolder: Folder = {
        id: generateId(),
        name: folderName,
        folders: [],
        requests: []
      };

      if (parentFolderId) {
        const parentFolder = findFolder(collection.folders, parentFolderId);
        if (!parentFolder) {
          throw new Error(`Parent folder ${parentFolderId} not found`);
        }
        parentFolder.folders.push(newFolder);
      } else {
        collection.folders.push(newFolder);
      }

      collection.updatedAt = new Date().toISOString();
      await storageService.saveCollection(collection);
      return newFolder;
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to add folder';
      console.error('Failed to add folder:', e);
      throw e;
    }
  }

  async function updateFolder(collectionId: string, folderId: string, updates: Partial<Folder>) {
    try {
      const collection = collections.value.find(c => c.id === collectionId);
      if (!collection) {
        throw new Error(`Collection ${collectionId} not found`);
      }

      const folder = findFolder(collection.folders, folderId);
      if (!folder) {
        throw new Error(`Folder ${folderId} not found`);
      }

      Object.assign(folder, updates);
      collection.updatedAt = new Date().toISOString();
      await storageService.saveCollection(collection);
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to update folder';
      console.error('Failed to update folder:', e);
      throw e;
    }
  }

  async function deleteFolder(collectionId: string, folderId: string) {
    try {
      const collection = collections.value.find(c => c.id === collectionId);
      if (!collection) {
        throw new Error(`Collection ${collectionId} not found`);
      }

      const deleted = removeFolderRecursive(collection.folders, folderId);
      if (!deleted) {
        throw new Error(`Folder ${folderId} not found`);
      }

      collection.updatedAt = new Date().toISOString();
      await storageService.saveCollection(collection);
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to delete folder';
      console.error('Failed to delete folder:', e);
      throw e;
    }
  }

  async function addRequestReference(
    collectionId: string,
    requestId: string,
    requestName: string,
    requestMethod: string,
    requestUrl: string,
    folderId?: string
  ) {
    try {
      const collection = collections.value.find(c => c.id === collectionId);
      if (!collection) {
        throw new Error(`Collection ${collectionId} not found`);
      }

      const requestRef: RequestReference = {
        id: requestId,
        name: requestName,
        method: requestMethod as any,
        url: requestUrl
      };

      if (folderId) {
        const folder = findFolder(collection.folders, folderId);
        if (!folder) {
          throw new Error(`Folder ${folderId} not found`);
        }
        folder.requests.push(requestRef);
      } else {
        collection.requests.push(requestRef);
      }

      collection.updatedAt = new Date().toISOString();
      await storageService.saveCollection(collection);
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to add request reference';
      console.error('Failed to add request reference:', e);
      throw e;
    }
  }

  async function removeRequestReference(collectionId: string, requestId: string) {
    try {
      const collection = collections.value.find(c => c.id === collectionId);
      if (!collection) {
        throw new Error(`Collection ${collectionId} not found`);
      }

      const removed = removeRequestRefRecursive(collection, requestId);
      if (!removed) {
        throw new Error(`Request reference ${requestId} not found`);
      }

      collection.updatedAt = new Date().toISOString();
      await storageService.saveCollection(collection);
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to remove request reference';
      console.error('Failed to remove request reference:', e);
      throw e;
    }
  }

  async function updateRequestReference(
    collectionId: string,
    requestId: string,
    requestName: string,
    requestMethod: string,
    requestUrl: string,
    folderId?: string
  ) {
    try {
      const collection = collections.value.find(c => c.id === collectionId);
      if (!collection) {
        throw new Error(`Collection ${collectionId} not found`);
      }

      // Find and update the request reference
      const updateRef = (target: Collection | Folder): boolean => {
        const requestRef = target.requests.find(r => r.id === requestId);
        if (requestRef) {
          requestRef.name = requestName;
          requestRef.method = requestMethod as any;
          requestRef.url = requestUrl;
          return true;
        }

        if ('folders' in target) {
          for (const folder of target.folders) {
            if (updateRef(folder)) {
              return true;
            }
          }
        }
        return false;
      };

      const updated = updateRef(collection);
      if (!updated) {
        throw new Error(`Request reference ${requestId} not found`);
      }

      collection.updatedAt = new Date().toISOString();
      await storageService.saveCollection(collection);
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to update request reference';
      console.error('Failed to update request reference:', e);
      throw e;
    }
  }


  // Helper functions
  function findFolder(folders: Folder[], folderId: string): Folder | null {
    for (const folder of folders) {
      if (folder.id === folderId) {
        return folder;
      }
      const found = findFolder(folder.folders, folderId);
      if (found) {
        return found;
      }
    }
    return null;
  }

  function removeFolderRecursive(folders: Folder[], folderId: string): boolean {
    const index = folders.findIndex(f => f.id === folderId);
    if (index !== -1) {
      folders.splice(index, 1);
      return true;
    }

    for (const folder of folders) {
      if (removeFolderRecursive(folder.folders, folderId)) {
        return true;
      }
    }
    return false;
  }

  function removeRequestRefRecursive(
    target: Collection | Folder,
    requestId: string
  ): boolean {
    const index = target.requests.findIndex(r => r.id === requestId);
    if (index !== -1) {
      target.requests.splice(index, 1);
      return true;
    }

    if ('folders' in target) {
      for (const folder of target.folders) {
        if (removeRequestRefRecursive(folder, requestId)) {
          return true;
        }
      }
    }
    return false;
  }

  return {
    // State
    collections,
    isLoading,
    error,
    
    // Getters
    getCollectionById,
    getCollectionByName,
    
    // Actions
    loadCollections,
    createCollection,
    updateCollection,
    deleteCollection,
    addFolder,
    updateFolder,
    deleteFolder,
    addRequestReference,
    updateRequestReference,
    removeRequestReference
  };
});
