<script setup>
import { ref, computed } from 'vue';

const props = defineProps({
  visible: {
    type: Boolean,
    default: false
  },
  updateInfo: {
    type: Object,
    default: () => null
  },
  downloading: {
    type: Boolean,
    default: false
  },
  downloadProgress: {
    type: Number,
    default: 0
  }
});

const emit = defineEmits(['update:visible', 'install', 'cancel']);

const localVisible = computed({
  get: () => props.visible,
  set: (value) => emit('update:visible', value)
});

const handleInstall = () => {
  emit('install');
};

const handleCancel = () => {
  emit('cancel');
  localVisible.value = false;
};

const formatDate = (dateString) => {
  if (!dateString) return 'N/A';
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  } catch (e) {
    return dateString;
  }
};

const formatBytes = (bytes) => {
  if (!bytes) return 'Unknown';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(2)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
};
</script>

<template>
  <Dialog
    v-model:visible="localVisible"
    modal
    :closable="!downloading"
    :closeOnEscape="!downloading"
    :style="{ width: '600px' }"
    header="Update Available"
  >
    <div v-if="updateInfo" class="space-y-4">
      <!-- Version Info -->
      <div class="flex items-center justify-between p-4 bg-surface-50 dark:bg-surface-800 rounded-lg">
        <div>
          <div class="text-sm text-surface-600 dark:text-surface-400">New Version</div>
          <div class="text-2xl font-bold text-primary">{{ updateInfo.version }}</div>
        </div>
        <div class="text-right">
          <div class="text-sm text-surface-600 dark:text-surface-400">Release Date</div>
          <div class="text-sm font-medium">{{ formatDate(updateInfo.date) }}</div>
        </div>
      </div>

      <!-- Release Notes -->
      <div v-if="updateInfo.body" class="space-y-2">
        <h3 class="text-lg font-semibold">What's New</h3>
        <div 
          class="p-4 bg-surface-50 dark:bg-surface-800 rounded-lg max-h-64 overflow-y-auto"
          style="white-space: pre-wrap; word-wrap: break-word;"
        >
          {{ updateInfo.body }}
        </div>
      </div>

      <!-- Download Progress -->
      <div v-if="downloading" class="space-y-2">
        <div class="flex items-center justify-between text-sm">
          <span class="text-surface-600 dark:text-surface-400">Downloading update...</span>
          <span class="font-medium">{{ downloadProgress }}%</span>
        </div>
        <ProgressBar :value="downloadProgress" :showValue="false" />
        <div class="text-xs text-surface-500 dark:text-surface-500 text-center">
          Please wait while the update is being downloaded
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-end gap-2">
        <Button
          label="Cancel"
          severity="secondary"
          @click="handleCancel"
          :disabled="downloading"
        />
        <Button
          label="Install Update"
          icon="pi pi-download"
          @click="handleInstall"
          :loading="downloading"
          :disabled="downloading"
        />
      </div>
    </template>
  </Dialog>
</template>

<style scoped>
/* Ensure proper text wrapping in release notes */
:deep(.p-dialog-content) {
  overflow-y: auto;
}
</style>
