<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import { storageService } from '@/services/storage';
import { useCollectionsStore } from '@/stores/collections';
import { useEnvironmentsStore } from '@/stores/environments';
import { useHistoryStore } from '@/stores/history';
import { useAppStateStore } from '@/stores/appState';
import Navbar from "@/components/Navbar.vue";
import Toolbar from "@/components/Toolbar.vue";
import MainContent from "@/components/MainContent.vue";
import Footer from "@/components/Footer.vue";

const consoleLogs = ref([]);
const toast = useToast();
const confirm = useConfirm();
const mainContentRef = ref(null);

// Initialize stores
const collectionsStore = useCollectionsStore();
const environmentsStore = useEnvironmentsStore();
const historyStore = useHistoryStore();
const appStateStore = useAppStateStore();

// 将 toast 和 confirm 挂载到全局，供子组件使用
onMounted(async () => {
  window.$toast = toast;
  window.$confirm = confirm;
  
  try {
    // Initialize storage service
    await storageService.initialize();
    
    // Load all data
    await Promise.all([
      collectionsStore.loadCollections(),
      environmentsStore.loadEnvironments(),
      historyStore.loadHistory(),
      appStateStore.loadState()
    ]);
    
    console.log('Application data loaded successfully');
  } catch (error) {
    console.error('Failed to initialize application:', error);
    toast.add({
      severity: 'error',
      summary: 'Initialization Error',
      detail: 'Failed to load application data',
      life: 5000
    });
  }
});

onBeforeUnmount(async () => {
  try {
    // Save app state before closing
    await appStateStore.saveState();
    // Flush any pending saves
    await storageService.flush();
  } catch (error) {
    console.error('Failed to save app state:', error);
  }
});

const handleClearConsole = () => {
  consoleLogs.value = [];
};

const handleAddConsoleLog = (log) => {
  consoleLogs.value.unshift(log);
};

const handleNewRequest = () => {
  if (mainContentRef.value) {
    mainContentRef.value.createNewRequest();
  }
};
</script>

<template>
  <div class="app-container flex flex-col h-screen bg-surface-0 dark:bg-surface-950 relative">
    <Toast position="top-right" />
    <ConfirmDialog />
    
    <Navbar />
    <Toolbar @new-request="handleNewRequest" />
    <MainContent 
      ref="mainContentRef"
      class="pb-[33px]"
      @add-console-log="handleAddConsoleLog"
    />
    <Footer 
      :openRequests="[]"
      :consoleLogs="consoleLogs"
      @clear-console="handleClearConsole"
    />
  </div>
</template>

<style scoped>
</style>
