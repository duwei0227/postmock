<script setup>
import { ref } from 'vue';

const emit = defineEmits(['new-request', 'import-file', 'import-curl']);

const showImportDialog = ref(false);
const importType = ref('file');
const curlInput = ref('');
const isImporting = ref(false);

const handleNewRequest = () => {
  emit('new-request');
};

const openImportDialog = () => {
  showImportDialog.value = true;
  importType.value = 'file';
  curlInput.value = '';
};

const closeImportDialog = () => {
  showImportDialog.value = false;
  curlInput.value = '';
};

const handleImport = async () => {
  if (importType.value === 'file') {
    emit('import-file');
    closeImportDialog();
  } else if (importType.value === 'curl') {
    if (!curlInput.value.trim()) {
      if (window.$toast) {
        window.$toast.add({
          severity: 'warn',
          summary: 'Warning',
          detail: 'Please enter a cURL command',
          life: 3000
        });
      }
      return;
    }
    
    emit('import-curl', curlInput.value.trim());
    closeImportDialog();
  }
};
</script>

<template>
  <div class="toolbar bg-surface-0 dark:bg-surface-950 text-surface-900 dark:text-surface-50 px-4 py-2 border-b border-surface-200 dark:border-surface-700 flex items-center gap-2">
    <button 
      @click="handleNewRequest"
      class="px-3 py-1.5 text-sm bg-primary hover:bg-primary-600 text-primary-contrast rounded transition"
    >
      + New Request
    </button>
    
    <button 
      @click="openImportDialog"
      class="px-3 py-1.5 text-sm bg-surface-100 dark:bg-surface-800 hover:bg-surface-200 dark:hover:bg-surface-700 rounded transition"
    >
      Import
    </button>
  </div>

  <!-- Import Dialog -->
  <Dialog 
    v-model:visible="showImportDialog"
    header="Import"
    :modal="true"
    :style="{ width: '32rem' }"
    @hide="closeImportDialog"
  >
    <div class="flex flex-col gap-4">
      <!-- Import Type Selection -->
      <div>
        <label class="block text-sm font-medium mb-2">Import Type</label>
        <div class="flex gap-4">
          <div class="flex items-center">
            <RadioButton 
              v-model="importType" 
              inputId="type-file" 
              value="file" 
            />
            <label for="type-file" class="ml-2 cursor-pointer">File</label>
          </div>
          <div class="flex items-center">
            <RadioButton 
              v-model="importType" 
              inputId="type-curl" 
              value="curl" 
            />
            <label for="type-curl" class="ml-2 cursor-pointer">cURL</label>
          </div>
        </div>
      </div>

      <!-- File Import Description -->
      <div v-if="importType === 'file'" class="text-sm text-surface-600 dark:text-surface-400">
        <p class="mb-2">Import a collection from a previously exported JSON file.</p>
        <ul class="list-disc list-inside space-y-1">
          <li>The file will be validated before import</li>
          <li>A new collection will be created with unique IDs</li>
          <li>Existing collections will not be affected</li>
        </ul>
      </div>

      <!-- cURL Import Input -->
      <div v-if="importType === 'curl'">
        <label class="block text-sm font-medium mb-2">cURL Command</label>
        <Textarea 
          v-model="curlInput"
          rows="8"
          placeholder="Paste your cURL command here...&#10;Example:&#10;curl -X POST https://api.example.com/users -H 'Content-Type: application/json' -d '{&quot;name&quot;:&quot;John&quot;}'"
          class="w-full font-mono text-sm"
        />
        <p class="text-xs text-surface-500 dark:text-surface-400 mt-2">
          The cURL command will be parsed and a new request will be created
        </p>
      </div>
    </div>
    
    <template #footer>
      <Button 
        label="Cancel" 
        severity="secondary" 
        @click="closeImportDialog" 
      />
      <Button 
        :label="importType === 'file' ? 'Select File' : 'Import'" 
        @click="handleImport"
        :disabled="isImporting"
      />
    </template>
  </Dialog>
</template>

<style scoped>
</style>
