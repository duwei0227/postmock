<script setup>
import { ref, onMounted } from 'vue';
import { getCurrentWindow } from '@tauri-apps/api/window';

const isDark = ref(true);
const isMaximized = ref(false);
const appWindow = getCurrentWindow();

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

// 手动处理拖动区域的点击事件
const handleTitlebarMouseDown = async (e) => {
  // 检查是否点击在按钮上
  if (e.target.tagName === 'BUTTON' || e.target.closest('button')) {
    return;
  }
  
  if (e.buttons === 1) {
    // 主按钮（左键）
    if (e.detail === 2) {
      // 双击最大化/还原
      await toggleMaximize();
    } else {
      // 单击开始拖动
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
});
</script>

<template>
  <nav 
    class="navbar bg-surface-0 dark:bg-surface-950 text-surface-900 dark:text-surface-50 px-4 py-2 border-b border-surface-200 dark:border-surface-700 select-none"
    @mousedown="handleTitlebarMouseDown"
  >
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-4">
        <h1 class="text-lg font-bold">Postmock</h1>
        <menu class="flex gap-3 text-sm">
          <button class="hover:text-primary transition">File</button>
          <button class="hover:text-primary transition">Edit</button>
          <button class="hover:text-primary transition">View</button>
          <button class="hover:text-primary transition">Help</button>
        </menu>
      </div>
      <div class="flex items-center gap-1">
        <button 
          @click="toggleTheme"
          class="px-2 py-1 rounded hover:bg-surface-100 dark:hover:bg-surface-800 transition"
          :title="isDark ? '切换到亮色模式' : '切换到暗色模式'"
        >
          <i :class="isDark ? 'pi pi-sun' : 'pi pi-moon'"></i>
        </button>
        <button 
          @click="minimizeWindow"
          class="px-2 py-1 rounded hover:bg-surface-100 dark:hover:bg-surface-800 transition"
          title="最小化"
        >
          <i class="pi pi-minus text-xs"></i>
        </button>
        <button 
          @click="toggleMaximize"
          class="px-2 py-1 rounded hover:bg-surface-100 dark:hover:bg-surface-800 transition"
          title="最大化/还原"
        >
          <i :class="isMaximized ? 'pi pi-clone' : 'pi pi-stop'" class="text-xs"></i>
        </button>
        <button 
          @click="closeWindow"
          class="px-2 py-1 rounded hover:bg-red-600 hover:text-white transition"
          title="关闭"
        >
          <i class="pi pi-times"></i>
        </button>
      </div>
    </div>
  </nav>
</template>

<style scoped>
/* 禁用文本选择，使拖动更流畅 */
.navbar {
  cursor: default;
  user-select: none;
}

/* 确保按钮可以接收点击事件 */
button {
  cursor: pointer;
  user-select: none;
}
</style>
