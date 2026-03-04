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
const showParameterHint = ref(false);
const parameterHintContent = ref('');
const cursorPosition = ref(0);
const currentVariablePrefix = ref('');
const selectedSuggestionIndex = ref(0); // 当前选中的建议索引

// 参数提示信息
const parameterHints = {
  '$sequence': {
    title: '$sequence Parameters',
    description: 'Auto-increment sequence with customizable settings',
    examples: [
      { syntax: '$sequence', desc: 'Default: start=1, step=1' },
      { syntax: '$sequence(100)', desc: 'Start from 100' },
      { syntax: '$sequence(start=100)', desc: 'Named param: start value' },
      { syntax: '$sequence(step=10)', desc: 'Named param: step value' },
      { syntax: '$sequence(padding=5)', desc: 'Named param: zero padding' },
      { syntax: '$sequence(name=order)', desc: 'Named param: sequence name' },
      { syntax: '$sequence(name=order, start=1000, step=10)', desc: 'Multiple params' }
    ],
    params: [
      { name: 'name', type: 'string', default: '"default"', desc: 'Sequence name' },
      { name: 'padding', type: 'number', default: '0', desc: 'Zero padding digits' },
      { name: 'start', type: 'number', default: '1', desc: 'Starting value' },
      { name: 'step', type: 'number', default: '1', desc: 'Increment step' }
    ]
  },
  '$randomInt': {
    title: '$randomInt Parameters',
    description: 'Generate random integer within specified range',
    examples: [
      { syntax: '$randomInt', desc: 'Random 0-1000 (default)' },
      { syntax: '$randomInt(1, 100)', desc: 'Random between 1 and 100' },
      { syntax: '$randomInt(min=1, max=100)', desc: 'Named params: min and max' },
      { syntax: '$randomInt(start=50, end=150)', desc: 'Named params: start and end' }
    ],
    params: [
      { name: 'start / min', type: 'number', default: '0', desc: 'Minimum value (inclusive)' },
      { name: 'end / max', type: 'number', default: '1000', desc: 'Maximum value (inclusive)' }
    ]
  },
  '$date': {
    title: '$date Parameters',
    description: 'Current date with custom format',
    examples: [
      { syntax: '$date', desc: 'Default: yyyy-MM-dd' },
      { syntax: '$date("yyyy/MM/dd")', desc: 'Custom format with slashes' },
      { syntax: '$date("yyyyMMdd")', desc: 'Compact format' },
      { syntax: '$date(format="yyyy-MM-dd")', desc: 'Named param: format' },
      { syntax: '$date(fmt="dd/MM/yyyy")', desc: 'Named param: fmt (alias)' }
    ],
    params: [
      { name: 'format / fmt', type: 'string', default: '"yyyy-MM-dd"', desc: 'Date format (yyyy=year, MM=month, dd=day)' }
    ]
  },
  '$time': {
    title: '$time Parameters',
    description: 'Current time with custom format',
    examples: [
      { syntax: '$time', desc: 'Default: HH:mm:ss' },
      { syntax: '$time("HH:mm")', desc: 'Hours and minutes only' },
      { syntax: '$time(format="HH:mm:ss")', desc: 'Named param: format' },
      { syntax: '$time(fmt="HHmmss")', desc: 'Compact time format' }
    ],
    params: [
      { name: 'format / fmt', type: 'string', default: '"HH:mm:ss"', desc: 'Time format (HH=hours, mm=minutes, ss=seconds)' }
    ]
  },
  '$datetime': {
    title: '$datetime Parameters',
    description: 'Current datetime with custom format',
    examples: [
      { syntax: '$datetime', desc: 'Default: yyyy-MM-dd HH:mm:ss' },
      { syntax: '$datetime("yyyy-MM-dd HH:mm")', desc: 'Without seconds' },
      { syntax: '$datetime(format="yyyyMMdd_HHmmss")', desc: 'Compact with underscore' },
      { syntax: '$datetime(fmt="yyyy/MM/dd HH:mm")', desc: 'Custom format' }
    ],
    params: [
      { name: 'format / fmt', type: 'string', default: '"yyyy-MM-dd HH:mm:ss"', desc: 'Datetime format' }
    ]
  },
  '$randomAlpha': {
    title: '$randomAlpha Parameters',
    description: 'Generate random letters (mixed case)',
    examples: [
      { syntax: '$randomAlpha', desc: 'Default: 10 letters' },
      { syntax: '$randomAlpha(20)', desc: '20 random letters' },
      { syntax: '$randomAlpha(length=15)', desc: 'Named param: length' },
      { syntax: '$randomAlpha(len=8)', desc: 'Named param: len (alias)' }
    ],
    params: [
      { name: 'length / len', type: 'number', default: '10', desc: 'String length' }
    ]
  },
  '$randomNumeric': {
    title: '$randomNumeric Parameters',
    description: 'Generate random digits',
    examples: [
      { syntax: '$randomNumeric', desc: 'Default: 10 digits' },
      { syntax: '$randomNumeric(6)', desc: '6 random digits' },
      { syntax: '$randomNumeric(length=8)', desc: 'Named param: length' },
      { syntax: '$randomNumeric(len=12)', desc: 'Named param: len (alias)' }
    ],
    params: [
      { name: 'length / len', type: 'number', default: '10', desc: 'String length' }
    ]
  },
  '$randomUppercase': {
    title: '$randomUppercase Parameters',
    description: 'Generate random uppercase letters',
    examples: [
      { syntax: '$randomUppercase', desc: 'Default: 10 uppercase letters' },
      { syntax: '$randomUppercase(15)', desc: '15 uppercase letters' },
      { syntax: '$randomUppercase(length=20)', desc: 'Named param: length' },
      { syntax: '$randomUppercase(len=12)', desc: 'Named param: len (alias)' }
    ],
    params: [
      { name: 'length / len', type: 'number', default: '10', desc: 'String length' }
    ]
  },
  '$randomLowercase': {
    title: '$randomLowercase Parameters',
    description: 'Generate random lowercase letters',
    examples: [
      { syntax: '$randomLowercase', desc: 'Default: 10 lowercase letters' },
      { syntax: '$randomLowercase(12)', desc: '12 lowercase letters' },
      { syntax: '$randomLowercase(length=18)', desc: 'Named param: length' },
      { syntax: '$randomLowercase(len=8)', desc: 'Named param: len (alias)' }
    ],
    params: [
      { name: 'length / len', type: 'number', default: '10', desc: 'String length' }
    ]
  },
  '$randomAlphanumeric': {
    title: '$randomAlphanumeric Parameters',
    description: 'Generate random letters and digits',
    examples: [
      { syntax: '$randomAlphanumeric', desc: 'Default: 10 characters' },
      { syntax: '$randomAlphanumeric(16)', desc: '16 random characters' },
      { syntax: '$randomAlphanumeric(length=32)', desc: 'Named param: length' },
      { syntax: '$randomAlphanumeric(len=24)', desc: 'Named param: len (alias)' }
    ],
    params: [
      { name: 'length / len', type: 'number', default: '10', desc: 'String length' }
    ]
  },
  '$randomChinese': {
    title: '$randomChinese Parameters',
    description: 'Generate random Chinese characters with readable phrases',
    examples: [
      { syntax: '$randomChinese', desc: 'Default: 10 characters' },
      { syntax: '$randomChinese(20)', desc: '20 Chinese characters' },
      { syntax: '$randomChinese(length=15)', desc: 'Named param: length' },
      { syntax: '$randomChinese(len=25)', desc: 'Named param: len (alias)' }
    ],
    params: [
      { name: 'length / len', type: 'number', default: '10', desc: 'String length' }
    ]
  }
};

const variableSuggestions = computed(() => {
  console.log('VariableInput - currentVariablePrefix:', currentVariablePrefix.value);
  console.log('VariableInput - availableVariables:', props.availableVariables);
  
  // 定义内置变量的语法说明
  const builtInVariableSyntax = {
    '$timestamp': 'Current timestamp in milliseconds',
    '$isoTimestamp': 'Current ISO 8601 timestamp',
    '$randomInt': '$randomInt, $randomInt(start, end), or $randomInt(min=0, max=100) - Random integer',
    '$guid': 'Random UUID/GUID',
    '$date': '$date, $date("format"), or $date(format="yyyy-MM-dd") - Current date',
    '$time': '$time, $time("format"), or $time(format="HH:mm:ss") - Current time',
    '$datetime': '$datetime, $datetime("format"), or $datetime(format="yyyy-MM-dd HH:mm:ss") - Current datetime',
    '$randomAlpha': '$randomAlpha, $randomAlpha(length), or $randomAlpha(length=10) - Random letters',
    '$randomNumeric': '$randomNumeric, $randomNumeric(length), or $randomNumeric(length=10) - Random digits',
    '$randomUppercase': '$randomUppercase, $randomUppercase(length), or $randomUppercase(length=10) - Random uppercase',
    '$randomLowercase': '$randomLowercase, $randomLowercase(length), or $randomLowercase(length=10) - Random lowercase',
    '$randomAlphanumeric': '$randomAlphanumeric, $randomAlphanumeric(length), or $randomAlphanumeric(length=10) - Random letters and digits',
    '$randomChinese': '$randomChinese, $randomChinese(length), or $randomChinese(length=10) - Random Chinese characters',
    '$sequence': '$sequence, $sequence(100), $sequence(start=100), $sequence(step=10), or $sequence(name=myseq, start=100, step=10) - Auto-increment'
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
    
    // 检查是否正在输入函数参数（包含左括号）
    const functionMatch = variableText.match(/^(\$\w+)\s*\(/);
    if (functionMatch) {
      const funcName = functionMatch[1];
      if (parameterHints[funcName]) {
        // 显示参数提示
        showParameterHint.value = true;
        parameterHintContent.value = funcName;
        showSuggestions.value = false;
      } else {
        showParameterHint.value = false;
        showSuggestions.value = true;
      }
    } else {
      // 显示变量建议
      showParameterHint.value = false;
      showSuggestions.value = true;
    }
    
    selectedSuggestionIndex.value = 0; // 重置选中索引
  } else {
    showSuggestions.value = false;
    showParameterHint.value = false;
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
    showParameterHint.value = false;
    selectedSuggestionIndex.value = 0;
  }, 200);
};

// 检查变量是否存在
const checkVariableExists = (varName) => {
  // 检查是否是 $sequence 函数调用格式
  const sequenceMatch = varName.match(/^\$sequence(?:\s*\(\s*[^)]*\s*\))?$/);
  if (sequenceMatch) {
    return true; // $sequence 或 $sequence(...) 格式是有效的
  }
  
  // 检查是否是 $randomInt 函数调用格式
  const randomIntMatch = varName.match(/^\$randomInt\s*\(\s*\d+\s*,\s*\d+\s*\)$/);
  if (randomIntMatch) {
    return true; // $randomInt(start, end) 格式是有效的
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
    
    <!-- Parameter Hint Panel -->
    <div
      v-if="showParameterHint && parameterHints[parameterHintContent]"
      class="absolute z-50 mt-1 bg-surface-0 dark:bg-surface-900 border border-primary-300 dark:border-primary-700 rounded shadow-lg p-4 min-w-96 max-w-2xl"
      style="left: 0; right: auto;"
    >
      <div class="flex flex-col gap-3">
        <!-- Title -->
        <div class="flex items-center gap-2 border-b border-surface-200 dark:border-surface-700 pb-2">
          <i class="pi pi-info-circle text-primary"></i>
          <span class="font-semibold text-surface-900 dark:text-surface-50">
            {{ parameterHints[parameterHintContent].title }}
          </span>
        </div>
        
        <!-- Description -->
        <div v-if="parameterHints[parameterHintContent].description" class="text-sm text-surface-600 dark:text-surface-400">
          {{ parameterHints[parameterHintContent].description }}
        </div>
        
        <!-- Parameters Table -->
        <div v-if="parameterHints[parameterHintContent].params" class="text-xs">
          <div class="font-semibold text-surface-700 dark:text-surface-300 mb-2">Parameters:</div>
          <table class="w-full">
            <thead>
              <tr class="border-b border-surface-200 dark:border-surface-700">
                <th class="text-left py-1 px-2 text-surface-600 dark:text-surface-400">Name</th>
                <th class="text-left py-1 px-2 text-surface-600 dark:text-surface-400">Type</th>
                <th class="text-left py-1 px-2 text-surface-600 dark:text-surface-400">Default</th>
                <th class="text-left py-1 px-2 text-surface-600 dark:text-surface-400">Description</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="param in parameterHints[parameterHintContent].params" 
                :key="param.name"
                class="border-b border-surface-100 dark:border-surface-800"
              >
                <td class="py-1 px-2 font-mono text-primary">{{ param.name }}</td>
                <td class="py-1 px-2 text-surface-500 dark:text-surface-400">{{ param.type }}</td>
                <td class="py-1 px-2 font-mono text-surface-500 dark:text-surface-400">{{ param.default }}</td>
                <td class="py-1 px-2 text-surface-600 dark:text-surface-400">{{ param.desc }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <!-- Examples -->
        <div v-if="parameterHints[parameterHintContent].examples" class="text-xs">
          <div class="font-semibold text-surface-700 dark:text-surface-300 mb-2">Examples:</div>
          <div class="space-y-1">
            <div 
              v-for="(example, idx) in parameterHints[parameterHintContent].examples" 
              :key="idx"
              class="flex items-start gap-2 p-2 bg-surface-50 dark:bg-surface-800 rounded"
            >
              <code class="text-primary font-mono flex-shrink-0">{{ example.syntax }}</code>
              <span class="text-surface-500 dark:text-surface-400">- {{ example.desc }}</span>
            </div>
          </div>
        </div>
        
        <div class="text-xs text-surface-500 dark:text-surface-400 italic pt-2 border-t border-surface-200 dark:border-surface-700">
          Press Esc to close this hint
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
