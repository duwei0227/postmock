<script setup>
import { ref, computed, watch } from 'vue';

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  placeholder: {
    type: String,
    default: ''
  },
  size: {
    type: String,
    default: 'normal'
  },
  availableVariables: {
    type: Object,
    default: () => ({})
  }
});

const emit = defineEmits(['update:modelValue', 'input']);

const inputRef = ref(null);
const showSuggestions = ref(false);
const cursorPosition = ref(0);
const currentVariablePrefix = ref('');
const selectedSuggestionIndex = ref(0); // 当前选中的建议索引

const variableSuggestions = computed(() => {
  console.log('VariableInput - currentVariablePrefix:', currentVariablePrefix.value);
  console.log('VariableInput - availableVariables:', props.availableVariables);
  
  if (!currentVariablePrefix.value) {
    // 即使没有前缀，如果用户输入了 {{，也显示所有变量
    if (showSuggestions.value) {
      const allSuggestions = Object.keys(props.availableVariables).map(key => ({
        key,
        value: props.availableVariables[key]
      }));
      console.log('VariableInput - all suggestions:', allSuggestions);
      return allSuggestions;
    }
    return [];
  }
  
  const prefix = currentVariablePrefix.value.toLowerCase();
  const suggestions = Object.keys(props.availableVariables)
    .filter(key => key.toLowerCase().includes(prefix))
    .map(key => ({
      key,
      value: props.availableVariables[key]
    }));
  
  console.log('VariableInput - filtered suggestions:', suggestions);
  return suggestions;
});

// 监听 availableVariables 变化
watch(() => props.availableVariables, (newVars) => {
  console.log('VariableInput - availableVariables changed:', newVars);
}, { deep: true, immediate: true });

const handleInput = (event) => {
  const value = event.target.value;
  emit('update:modelValue', value);
  emit('input', event);
  
  checkForVariableTrigger(value, event.target.selectionStart);
};

const handleKeyDown = (event) => {
  // 只在显示建议时处理键盘事件
  if (!showSuggestions.value || variableSuggestions.value.length === 0) {
    return;
  }
  
  switch (event.key) {
    case 'ArrowDown':
      event.preventDefault();
      selectedSuggestionIndex.value = Math.min(
        selectedSuggestionIndex.value + 1,
        variableSuggestions.value.length - 1
      );
      break;
      
    case 'ArrowUp':
      event.preventDefault();
      selectedSuggestionIndex.value = Math.max(selectedSuggestionIndex.value - 1, 0);
      break;
      
    case 'Enter':
    case 'Tab':
      if (variableSuggestions.value[selectedSuggestionIndex.value]) {
        event.preventDefault();
        selectVariable(variableSuggestions.value[selectedSuggestionIndex.value]);
      }
      break;
      
    case 'Escape':
      event.preventDefault();
      showSuggestions.value = false;
      break;
  }
};

const handleFocus = (event) => {
  // 将光标移动到末尾
  const input = event.target;
  const length = input.value.length;
  
  // 使用 setTimeout 确保在浏览器默认行为之后执行
  setTimeout(() => {
    input.setSelectionRange(length, length);
  }, 0);
};

const checkForVariableTrigger = (value, position) => {
  cursorPosition.value = position;
  
  // 查找光标前最近的 {{
  const beforeCursor = value.substring(0, position);
  const lastOpenBrace = beforeCursor.lastIndexOf('{{');
  const lastCloseBrace = beforeCursor.lastIndexOf('}}');
  
  // 如果找到 {{ 且在最后一个 }} 之后，说明正在输入变量
  if (lastOpenBrace !== -1 && lastOpenBrace > lastCloseBrace) {
    const variableText = beforeCursor.substring(lastOpenBrace + 2);
    currentVariablePrefix.value = variableText;
    showSuggestions.value = true;
    selectedSuggestionIndex.value = 0; // 重置选中索引
  } else {
    showSuggestions.value = false;
    currentVariablePrefix.value = '';
    selectedSuggestionIndex.value = 0;
  }
};

const selectVariable = (variable) => {
  const value = props.modelValue;
  const beforeCursor = value.substring(0, cursorPosition.value);
  const afterCursor = value.substring(cursorPosition.value);
  
  const lastOpenBrace = beforeCursor.lastIndexOf('{{');
  const newValue = value.substring(0, lastOpenBrace + 2) + variable.key + '}}' + afterCursor;
  
  emit('update:modelValue', newValue);
  showSuggestions.value = false;
  currentVariablePrefix.value = '';
  selectedSuggestionIndex.value = 0;
  
  // 聚焦回输入框
  setTimeout(() => {
    if (inputRef.value) {
      inputRef.value.$el.focus();
    }
  }, 0);
};

const hideSuggestions = () => {
  setTimeout(() => {
    showSuggestions.value = false;
    selectedSuggestionIndex.value = 0;
  }, 200);
};

// 检查变量是否存在
const checkVariableExists = (varName) => {
  return props.availableVariables.hasOwnProperty(varName);
};

// 检查输入值中是否有不存在的变量
const hasInvalidVariables = computed(() => {
  if (!props.modelValue) return false;
  
  console.log('[VariableInput] Checking invalid variables for:', props.modelValue);
  console.log('[VariableInput] Available variables:', props.availableVariables);
  console.log('[VariableInput] Available variables keys:', Object.keys(props.availableVariables));
  
  // 使用正则表达式匹配 {{variable}}
  const regex = /\{\{([^}]+)\}\}/g;
  let match;
  
  while ((match = regex.exec(props.modelValue)) !== null) {
    const varName = match[1].trim();
    const exists = checkVariableExists(varName);
    console.log(`[VariableInput] Variable "${varName}" exists:`, exists);
    
    if (!exists) {
      console.log('[VariableInput] Found invalid variable:', varName);
      return true; // 找到不存在的变量
    }
  }
  
  console.log('[VariableInput] No invalid variables found');
  return false;
});
</script>

<template>
  <div class="variable-input-wrapper relative">
    <InputText
      ref="inputRef"
      :modelValue="modelValue"
      :placeholder="placeholder"
      :size="size"
      :class="['w-full', { 'invalid-variable': hasInvalidVariables }]"
      @input="handleInput"
      @keydown="handleKeyDown"
      @focus="handleFocus"
      @blur="hideSuggestions"
    />
    
    <!-- Variable Suggestions Dropdown -->
    <div
      v-if="showSuggestions && variableSuggestions.length > 0"
      class="absolute z-50 w-full mt-1 bg-surface-0 dark:bg-surface-900 border border-surface-300 dark:border-surface-700 rounded shadow-lg max-h-48 overflow-y-auto"
    >
      <div
        v-for="(variable, index) in variableSuggestions"
        :key="variable.key"
        :class="[
          'px-3 py-2 cursor-pointer transition',
          index === selectedSuggestionIndex 
            ? 'bg-primary-100 dark:bg-primary-900/30' 
            : 'hover:bg-surface-100 dark:hover:bg-surface-800'
        ]"
        @mousedown="selectVariable(variable)"
        @mouseenter="selectedSuggestionIndex = index"
      >
        <div class="flex items-center justify-between">
          <span class="text-sm font-medium text-primary">{{ variable.key }}</span>
          <span class="text-xs text-surface-500 dark:text-surface-400 ml-2 truncate max-w-xs">
            {{ variable.value }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.variable-input-wrapper {
  position: relative;
}

/* 不存在的变量显示红色 - 使用更强的选择器 */
:deep(.invalid-variable.p-inputtext) {
  color: #ef4444 !important;
}

:deep(.p-dark .invalid-variable.p-inputtext) {
  color: #f87171 !important;
}

/* 备用选择器 */
:deep(.invalid-variable input) {
  color: #ef4444 !important;
}

:deep(.p-dark .invalid-variable input) {
  color: #f87171 !important;
}
</style>
