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
  
  // 定义内置变量的语法说明
  const builtInVariableSyntax = {
    '$timestamp': 'Current timestamp in milliseconds',
    '$isoTimestamp': 'Current ISO 8601 timestamp',
    '$randomInt': '$randomInt or $randomInt(start, end) - Random integer (default: 0-1000)',
    '$guid': 'Random UUID/GUID',
    '$date': '$date or $date("format") - Current date (default: yyyy-MM-dd)',
    '$time': '$time or $time("format") - Current time (default: HH:mm:ss)',
    '$datetime': '$datetime or $datetime("format") - Current datetime (default: yyyy-MM-dd HH:mm:ss)',
    '$randomString': '$randomString or $randomString(length, "type") - Random string (deprecated, use specific types)',
    '$randomAlpha': '$randomAlpha or $randomAlpha(length) - Random letters (default: 10 chars, mixed case)',
    '$randomNumeric': '$randomNumeric or $randomNumeric(length) - Random digits (default: 10 chars)',
    '$randomUppercase': '$randomUppercase or $randomUppercase(length) - Random uppercase letters (default: 10 chars)',
    '$randomLowercase': '$randomLowercase or $randomLowercase(length) - Random lowercase letters (default: 10 chars)',
    '$randomAlphanumeric': '$randomAlphanumeric or $randomAlphanumeric(length) - Random letters and digits (default: 10 chars)',
    '$randomChinese': '$randomChinese or $randomChinese(length) - Random Chinese characters (default: 10 chars)'
  };
  
  if (!currentVariablePrefix.value) {
    // 即使没有前缀，如果用户输入了 {{，也显示所有变量
    if (showSuggestions.value) {
      const allSuggestions = Object.keys(props.availableVariables).map(key => ({
        key,
        value: props.availableVariables[key],
        syntax: builtInVariableSyntax[key] || null
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
      value: props.availableVariables[key],
      syntax: builtInVariableSyntax[key] || null
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
  // 检查是否是 $randomInt 函数调用格式
  const randomIntMatch = varName.match(/^\$randomInt\s*\(\s*\d+\s*,\s*\d+\s*\)$/);
  if (randomIntMatch) {
    return true; // $randomInt(start, end) 格式是有效的
  }
  
  // 检查是否是 $randomString 函数调用格式（保留向后兼容）
  const randomStringMatch = varName.match(/^\$randomString\s*\(\s*\d+(?:\s*,\s*['"]([^'"]+)['"])?\s*\)$/);
  if (randomStringMatch) {
    return true; // $randomString(length) 或 $randomString(length, "type") 格式是有效的
  }
  
  // 检查是否是 $randomAlpha 函数调用格式
  const randomAlphaMatch = varName.match(/^\$randomAlpha\s*\(\s*\d+\s*\)$/);
  if (randomAlphaMatch) {
    return true;
  }
  
  // 检查是否是 $randomNumeric 函数调用格式
  const randomNumericMatch = varName.match(/^\$randomNumeric\s*\(\s*\d+\s*\)$/);
  if (randomNumericMatch) {
    return true;
  }
  
  // 检查是否是 $randomUppercase 函数调用格式
  const randomUppercaseMatch = varName.match(/^\$randomUppercase\s*\(\s*\d+\s*\)$/);
  if (randomUppercaseMatch) {
    return true;
  }
  
  // 检查是否是 $randomLowercase 函数调用格式
  const randomLowercaseMatch = varName.match(/^\$randomLowercase\s*\(\s*\d+\s*\)$/);
  if (randomLowercaseMatch) {
    return true;
  }
  
  // 检查是否是 $randomAlphanumeric 函数调用格式
  const randomAlphanumericMatch = varName.match(/^\$randomAlphanumeric\s*\(\s*\d+\s*\)$/);
  if (randomAlphanumericMatch) {
    return true;
  }
  
  // 检查是否是 $randomChinese 函数调用格式
  const randomChineseMatch = varName.match(/^\$randomChinese\s*\(\s*\d+\s*\)$/);
  if (randomChineseMatch) {
    return true; // $randomChinese(length) 格式是有效的
  }
  
  // 检查是否是 $date 函数调用格式
  const dateMatch = varName.match(/^\$date\s*\(\s*['"]([^'"]+)['"]\s*\)$/);
  if (dateMatch) {
    return true; // $date("format") 格式是有效的
  }
  
  // 检查是否是 $time 函数调用格式
  const timeMatch = varName.match(/^\$time\s*\(\s*['"]([^'"]+)['"]\s*\)$/);
  if (timeMatch) {
    return true; // $time("format") 格式是有效的
  }
  
  // 检查是否是 $datetime 函数调用格式
  const datetimeMatch = varName.match(/^\$datetime\s*\(\s*['"]([^'"]+)['"]\s*\)$/);
  if (datetimeMatch) {
    return true; // $datetime("format") 格式是有效的
  }
  
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
      class="absolute z-50 w-full mt-1 bg-surface-0 dark:bg-surface-900 border border-surface-300 dark:border-surface-700 rounded shadow-lg max-h-64 overflow-y-auto"
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
        <div class="flex flex-col gap-1">
          <div class="flex items-center justify-between">
            <span class="text-sm font-medium text-primary">{{ variable.key }}</span>
            <span 
              v-if="!variable.syntax"
              class="text-xs text-surface-500 dark:text-surface-400 ml-2 truncate max-w-xs"
            >
              {{ variable.value }}
            </span>
          </div>
          <div v-if="variable.syntax" class="text-xs text-surface-600 dark:text-surface-400">
            {{ variable.syntax }}
          </div>
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
