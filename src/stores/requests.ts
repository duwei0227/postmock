import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { storageService } from '@/services/storage';
import type { Request } from '@/types/models';

export const useRequestsStore = defineStore('requests', () => {
  // State - using Map for efficient lookups
  const requests = ref<Map<string, Request>>(new Map());
  const isLoading = ref(false);

  // Getters
  const getRequestById = computed(() => {
    return (id: string) => requests.value.get(id);
  });

  const getRequestsByCollectionId = computed(() => {
    return (collectionId: string) => {
      return Array.from(requests.value.values()).filter(
        r => r.collectionId === collectionId
      );
    };
  });

  // Actions
  async function loadRequest(id: string): Promise<Request | null> {
    // Check cache first
    if (requests.value.has(id)) {
      return requests.value.get(id)!;
    }

    // Load from storage
    isLoading.value = true;
    try {
      const request = await storageService.loadRequest(id);
      if (request) {
        requests.value.set(id, request);
      }
      return request;
    } catch (e) {
      console.error(`Failed to load request ${id}:`, e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  async function loadMultipleRequests(ids: string[]): Promise<Request[]> {
    const loadedRequests: Request[] = [];
    
    for (const id of ids) {
      const request = await loadRequest(id);
      if (request) {
        loadedRequests.push(request);
      }
    }
    
    return loadedRequests;
  }

  async function saveRequest(request: Request): Promise<void> {
    try {
      request.updatedAt = new Date().toISOString();
      await storageService.saveRequest(request);
      requests.value.set(request.id, request);
    } catch (e) {
      console.error(`Failed to save request ${request.id}:`, e);
      throw e;
    }
  }

  async function deleteRequest(id: string): Promise<void> {
    try {
      await storageService.deleteRequest(id);
      requests.value.delete(id);
    } catch (e) {
      console.error(`Failed to delete request ${id}:`, e);
      throw e;
    }
  }

  function clearCache(): void {
    requests.value.clear();
  }

  function removeCachedRequest(id: string): void {
    requests.value.delete(id);
  }

  return {
    // State
    requests,
    isLoading,
    
    // Getters
    getRequestById,
    getRequestsByCollectionId,
    
    // Actions
    loadRequest,
    loadMultipleRequests,
    saveRequest,
    deleteRequest,
    clearCache,
    removeCachedRequest
  };
});
