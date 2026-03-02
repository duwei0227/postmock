import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { storageService } from '@/services/storage';
import type { HistoryItem } from '@/types/models';

export const useHistoryStore = defineStore('history', () => {
  // State
  const history = ref<HistoryItem[]>([]);
  const maxItems = ref(100);
  const isLoading = ref(false);

  // Getters
  const recentHistory = computed(() => {
    return (limit: number = 20) => history.value.slice(0, limit);
  });

  const getHistoryByRequestId = computed(() => {
    return (requestId: string) => {
      return history.value.filter(h => h.requestId === requestId);
    };
  });

  // Actions
  async function loadHistory() {
    isLoading.value = true;
    try {
      history.value = await storageService.loadHistory();
    } catch (e) {
      console.error('Failed to load history:', e);
    } finally {
      isLoading.value = false;
    }
  }

  async function addHistoryItem(item: HistoryItem) {
    // Add to beginning
    history.value.unshift(item);
    
    // Enforce size limit
    if (history.value.length > maxItems.value) {
      history.value = history.value.slice(0, maxItems.value);
    }
    
    try {
      await storageService.saveHistory(history.value);
    } catch (e) {
      console.error('Failed to save history:', e);
    }
  }

  async function clearHistory() {
    history.value = [];
    try {
      await storageService.saveHistory([]);
    } catch (e) {
      console.error('Failed to clear history:', e);
      throw e;
    }
  }

  async function deleteHistoryItem(id: string) {
    const index = history.value.findIndex(h => h.id === id);
    if (index !== -1) {
      history.value.splice(index, 1);
      try {
        await storageService.saveHistory(history.value);
      } catch (e) {
        console.error('Failed to delete history item:', e);
        throw e;
      }
    }
  }

  return {
    // State
    history,
    maxItems,
    isLoading,
    
    // Getters
    recentHistory,
    getHistoryByRequestId,
    
    // Actions
    loadHistory,
    addHistoryItem,
    clearHistory,
    deleteHistoryItem
  };
});
