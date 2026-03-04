<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import { storageService } from '@/services/storage';
import { useCollectionsStore } from '@/stores/collections';
import { useRequestsStore } from '@/stores/requests';
import { useEnvironmentsStore } from '@/stores/environments';
import { useHistoryStore } from '@/stores/history';
import { useAppStateStore } from '@/stores/appState';
import { useSequencesStore } from '@/stores/sequences';
import { importExportService } from '@/services/import-export';
import { parseCurl } from '@/utils/curl-parser';
import { generateId } from '@/utils/id-generator';
import Navbar from "@/components/Navbar.vue";
import Toolbar from "@/components/Toolbar.vue";
import MainContent from "@/components/MainContent.vue";
import Footer from "@/components/Footer.vue";
import CreateNewModal from "@/components/CreateNewModal.vue";

const consoleLogs = ref([]);
const toast = useToast();
const confirm = useConfirm();
const mainContentRef = ref(null);
const showCreateNewModal = ref(false);

// Initialize stores
const collectionsStore = useCollectionsStore();
const requestsStore = useRequestsStore();
const environmentsStore = useEnvironmentsStore();
const historyStore = useHistoryStore();
const appStateStore = useAppStateStore();
const sequencesStore = useSequencesStore();

// 将 toast 和 confirm 挂载到全局，供子组件使用
onMounted(async () => {
  window.$toast = toast;
  window.$confirm = confirm;
  
  // Add global keyboard shortcut for Ctrl+N
  window.addEventListener('keydown', handleGlobalKeyDown);
  
  try {
    // Initialize storage service
    await storageService.initialize();
    
    // Load all data
    await Promise.all([
      collectionsStore.loadCollections(),
      environmentsStore.loadEnvironments(),
      historyStore.loadHistory(),
      appStateStore.loadState(),
      sequencesStore.loadSequences()
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
  // Remove global keyboard shortcut
  window.removeEventListener('keydown', handleGlobalKeyDown);
  
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

const handleImportFile = async () => {
  try {
    const result = await importExportService.importCollection();
    if (!result) return; // User cancelled
    
    const { collection, requests } = result;
    
    // Check for duplicate collection name and rename if necessary
    let collectionName = collection.name;
    if (collectionsStore.collections.some(c => c.name === collectionName)) {
      // First try with "Imported"
      collectionName = `${collection.name} (Imported)`;
      let counter = 2;
      // If still duplicate, add counter
      while (collectionsStore.collections.some(c => c.name === collectionName)) {
        collectionName = `${collection.name} (Imported ${counter})`;
        counter++;
      }
    }
    
    // Create collection with potentially renamed name
    const newCollection = await collectionsStore.createCollection(
      collectionName,
      collection.description
    );
    
    if (newCollection) {
      // Update collection structure with remapped IDs
      await collectionsStore.updateCollection(newCollection.id, {
        folders: collection.folders,
        requests: collection.requests
      });
      
      // Save all requests with remapped IDs
      for (const request of requests) {
        // Ensure collectionId is set to the new collection
        request.collectionId = newCollection.id;
        await requestsStore.saveRequest(request);
      }
      
      toast.add({
        severity: 'success',
        summary: 'Success',
        detail: `Collection "${collectionName}" imported successfully`,
        life: 3000
      });
    }
  } catch (error) {
    console.error('Failed to import collection:', error);
    toast.add({
      severity: 'error',
      summary: 'Import Failed',
      detail: error.message || 'Failed to import collection',
      life: 5000
    });
  }
};

const handleImportCurl = async (curlCommand) => {
  try {
    const parsed = parseCurl(curlCommand);
    
    // Create a new request from parsed cURL
    const newRequest = {
      id: generateId(),
      name: `${parsed.method} ${new URL(parsed.url).pathname}`,
      method: parsed.method,
      url: parsed.url,
      params: [{ key: '', value: '', enabled: true }],
      headers: parsed.headers,
      body: parsed.body,
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
      collectionId: null,
      folderId: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    // Save request
    await requestsStore.saveRequest(newRequest);
    
    // Open in tab
    appStateStore.addOpenRequest(newRequest.id);
    
    toast.add({
      severity: 'success',
      summary: 'Success',
      detail: 'cURL command imported successfully',
      life: 3000
    });
  } catch (error) {
    console.error('Failed to import cURL:', error);
    toast.add({
      severity: 'error',
      summary: 'Import Failed',
      detail: 'Failed to parse cURL command',
      life: 5000
    });
  }
};

// Global keyboard shortcut handler
const handleGlobalKeyDown = (event) => {
  // Ctrl+N or Cmd+N to open Create New modal
  if ((event.ctrlKey || event.metaKey) && event.key === 'n') {
    event.preventDefault();
    showCreateNewModal.value = true;
  }
};

// Handle create action from modal
const handleCreate = (type) => {
  if (type === 'request') {
    handleNewRequest();
  } else if (type === 'collection') {
    // Access CollectionsPanel through MainContent ref
    if (mainContentRef.value?.collectionsPanelRef) {
      mainContentRef.value.collectionsPanelRef.openCreateDialog('collection');
    }
  } else if (type === 'environment') {
    // Access EnvironmentManager through MainContent ref
    if (mainContentRef.value?.environmentManagerRef) {
      mainContentRef.value.environmentManagerRef.openCreateDialog();
    }
  }
};
</script>

<template>
  <div class="app-container flex flex-col h-screen bg-surface-0 dark:bg-surface-950 relative">
    <Toast position="top-right" />
    <ConfirmDialog />
    
    <CreateNewModal 
      v-model:visible="showCreateNewModal"
      @create="handleCreate"
    />
    
    <Navbar />
    <Toolbar 
      @new-request="handleNewRequest"
      @import-file="handleImportFile"
      @import-curl="handleImportCurl"
    />
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
