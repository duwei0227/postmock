<script setup>
import { ref } from 'vue';

const props = defineProps({
  folders: Array,
  collection: Object
});

const emit = defineEmits(['show-context-menu']);

const expandedFolders = ref(new Set());

const toggleFolder = (folderId) => {
  if (expandedFolders.value.has(folderId)) {
    expandedFolders.value.delete(folderId);
  } else {
    expandedFolders.value.add(folderId);
  }
};

const isFolderExpanded = (folderId) => {
  return expandedFolders.value.has(folderId);
};

const showContextMenu = (event, folder) => {
  emit('show-context-menu', event, folder, props.collection);
};
</script>

<template>
  <div>
    <div 
      v-for="folder in folders"
      :key="folder.id"
      class="mb-1"
    >
      <div 
        class="p-2 rounded hover:bg-surface-200 dark:hover:bg-surface-800 cursor-pointer transition"
        @contextmenu="showContextMenu($event, folder)"
      >
        <div class="flex items-center gap-1">
          <i 
            v-if="folder.folders && folder.folders.length > 0"
            :class="[
              'pi text-xs cursor-pointer',
              isFolderExpanded(folder.id) ? 'pi-chevron-down' : 'pi-chevron-right'
            ]"
            @click.stop="toggleFolder(folder.id)"
          ></i>
          <i v-else class="pi text-xs" style="width: 12px;"></i>
          <i class="pi pi-folder text-xs text-primary"></i>
          <span class="text-xs font-medium text-surface-900 dark:text-surface-50">
            {{ folder.name }}
          </span>
        </div>
      </div>
      
      <!-- Sub-folders -->
      <div v-if="isFolderExpanded(folder.id) && folder.folders && folder.folders.length > 0" class="ml-4">
        <FolderTree 
          :folders="folder.folders"
          :collection="collection"
          @show-context-menu="showContextMenu"
        />
      </div>
    </div>
  </div>
</template>
