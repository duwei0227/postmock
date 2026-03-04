<script setup>
import { ref, onMounted } from 'vue';
import { getCurrentWindow } from '@tauri-apps/api/window';
import { invoke } from '@tauri-apps/api/core';
import KeyboardShortcutsDialog from './KeyboardShortcutsDialog.vue';
import AboutDialog from './AboutDialog.vue';

const isDark = ref(true);
const isMaximized = ref(false);
const appWindow = getCurrentWindow();

// Help menu state
const helpMenuRef = ref(null);
const showShortcutsDialog = ref(false);
const showAboutDialog = ref(false);

const helpMenuItems = ref([
  {
    label: 'Check For Update',
    icon: 'pi pi-refresh',
    command: () => checkForUpdate()
  },
  {
    label: 'Keyboard Shortcuts',
    icon: 'pi pi-sliders-h',
    command: () => showShortcutsDialog.value = true
  },
  { separator: true },
  {
    label: 'About Postmock',
    icon: 'pi pi-info-circle',
    command: () => showAboutDialog.value = true
  }
]);

const toggleTheme = () => {
  isDark.value = !isDark.value;
  const element = document.documentElement;
  
  if (isDark.value) {
    element.classList.add('p-dark');
  } else {
    element.classList.remove('p-dark');
  }
  
  localStorage.setItem('theme', isDark.value ? 'dark' : 'light');
};

const minimizeWindow = async () => {
  await appWindow.minimize();
};

const toggleMaximize = async () => {
  if (isMaximized.value) {
    await appWindow.unmaximize();
  } else {
    await appWindow.maximize();
  }
  isMaximized.value = !isMaximized.value;
};

const closeWindow = async () => {
  await appWindow.close();
};

// Help menu functions
const checkForUpdate = async () => {
  try {
    // Get current version
    const appInfo = await invoke('get_app_info');
    const currentVersion = appInfo.version || '0.1.0';
    
    // Fetch latest release from GitHub
    const response = await fetch('https://api.github.com/repos/duwei0227/postmock/releases/latest');
    
    if (!response.ok) {
      throw new Error('Failed to fetch update information');
    }
    
    const latestRelease = await response.json();
    const latestVersion = latestRelease.tag_name.replace(/^v/, ''); // Remove 'v' prefix if exists
    
    // Compare versions
    if (latestVersion === currentVersion) {
      if (window.$toast) {
        window.$toast.add({
          severity: 'info',
          summary: 'Up to Date',
          detail: `You are using the latest version (${currentVersion})`,
          life: 3000
        });
      }
    } else {
      if (window.$toast) {
        window.$toast.add({
          severity: 'success',
          summary: 'Update Available',
          detail: `New version ${latestVersion} is available! Current: ${currentVersion}`,
          life: 5000
        });
      }
      
      // Open release page in browser
      if (window.$confirm) {
        window.$confirm.require({
          message: `A new version (${latestVersion}) is available. Would you like to view the release page?`,
          header: 'Update Available',
          icon: 'pi pi-info-circle',
          acceptLabel: 'View Release',
          rejectLabel: 'Later',
          accept: () => {
            // Copy release URL to clipboard
            if (navigator.clipboard) {
              navigator.clipboard.writeText(latestRelease.html_url);
              if (window.$toast) {
                window.$toast.add({
                  severity: 'success',
                  summary: 'Link Copied',
                  detail: 'Release page URL copied to clipboard',
                  life: 2000
                });
              }
            }
          }
        });
      }
    }
  } catch (error) {
    console.error('Failed to check for updates:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Update Check Failed',
        detail: 'Unable to check for updates. Please try again later.',
        life: 3000
      });
    }
  }
};

const showHelpMenu = (event) => {
  helpMenuRef.value.toggle(event);
};

// Manually handle titlebar click events
const handleTitlebarMouseDown = async (e) => {
  // Check if clicking on a button
  if (e.target.tagName === 'BUTTON' || e.target.closest('button')) {
    return;
  }
  
  if (e.buttons === 1) {
    // Primary button (left click)
    if (e.detail === 2) {
      // Double-click to maximize/restore
      await toggleMaximize();
    } else {
      // Single click to start dragging
      await appWindow.startDragging();
    }
  }
};

onMounted(async () => {
  const savedTheme = localStorage.getItem('theme');
  isDark.value = savedTheme !== 'light';
  
  if (isDark.value) {
    document.documentElement.classList.add('p-dark');
  }
  
  try {
    isMaximized.value = await appWindow.isMaximized();
  } catch (e) {
    console.error('Failed to get window state:', e);
  }
  
  // Add global keyboard shortcut listeners
  window.addEventListener('keydown', handleGlobalShortcuts);
});

// Global keyboard shortcut handler
const handleGlobalShortcuts = (event) => {
  // Ctrl+/ or Cmd+/ to show shortcuts
  if ((event.ctrlKey || event.metaKey) && event.key === '/') {
    event.preventDefault();
    showShortcutsDialog.value = true;
  }
};
</script>

<template>
  <nav 
    class="navbar bg-surface-0 dark:bg-surface-950 text-surface-900 dark:text-surface-50 px-4 py-2 border-b border-surface-200 dark:border-surface-700 select-none"
    @mousedown="handleTitlebarMouseDown"
  >
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-4">
        <h1 class="text-lg font-bold">Postmock</h1>
      </div>
      <div class="flex items-center gap-1">
        <button 
          @click="showHelpMenu"
          class="px-2 py-1 rounded hover:bg-surface-100 dark:hover:bg-surface-800 transition"
          title="Help"
        >
          <i class="pi pi-question-circle"></i>
        </button>
        <button 
          @click="toggleTheme"
          class="px-2 py-1 rounded hover:bg-surface-100 dark:hover:bg-surface-800 transition"
          :title="isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'"
        >
          <i :class="isDark ? 'pi pi-sun' : 'pi pi-moon'"></i>
        </button>
        
        <!-- Separator -->
        <div class="h-5 w-px bg-surface-300 dark:bg-surface-600 mx-2"></div>
        
        <button 
          @click="minimizeWindow"
          class="px-2 py-1 rounded hover:bg-surface-100 dark:hover:bg-surface-800 transition"
          title="Minimize"
        >
          <i class="pi pi-minus text-xs"></i>
        </button>
        <button 
          @click="toggleMaximize"
          class="px-2 py-1 rounded hover:bg-surface-100 dark:hover:bg-surface-800 transition"
          title="Maximize/Restore"
        >
          <i :class="isMaximized ? 'pi pi-clone' : 'pi pi-stop'" class="text-xs"></i>
        </button>
        <button 
          @click="closeWindow"
          class="px-2 py-1 rounded hover:bg-red-600 hover:text-white transition"
          title="Close"
        >
          <i class="pi pi-times"></i>
        </button>
      </div>
    </div>
    
    <!-- Help Menu -->
    <ContextMenu ref="helpMenuRef" :model="helpMenuItems" :style="{ minWidth: '220px' }">
      <template #item="{ item, props }">
        <a v-ripple class="flex items-center gap-2" v-bind="props.action">
          <i v-if="item.icon" :class="item.icon"></i>
          <span>{{ item.label }}</span>
        </a>
      </template>
    </ContextMenu>
    
    <!-- Dialogs -->
    <KeyboardShortcutsDialog 
      v-model:visible="showShortcutsDialog"
    />
    
    <AboutDialog 
      v-model:visible="showAboutDialog"
    />
  </nav>
</template>

<style scoped>
/* Disable text selection for smoother dragging */
.navbar {
  cursor: default;
  user-select: none;
}

/* Ensure buttons can receive click events */
button {
  cursor: pointer;
  user-select: none;
}

/* Ensure ContextMenu items have proper spacing for icons */
:deep(.p-contextmenu .p-menuitem-link) {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

:deep(.p-contextmenu .p-menuitem-icon) {
  flex-shrink: 0;
  width: 1rem;
}

:deep(.p-contextmenu .p-menuitem-text) {
  flex: 1;
  white-space: nowrap;
}
</style>
