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

const variableSuggestions = computed(() => {
  console.log('VariableInput - currentVariablePrefix:', currentVariablePrefix.value);
  console.log('VariableInput - availableVariables:', props.availableVariables);
  
  if (!currentVariablePrefix.value) return [];
  
  const prefix = currentVariablePrefix.value.toLowerCase();
  const suggestions = Object.keys(props.availableVariables)
    .filter(key => key.toLowerCase().includes(prefix))
    .map(key => ({
      key,
      value: props.availableVariables[key]
    }));
  
  console.log('VariableInput - suggestions:', suggestions);
  return suggestions;
});

const handleInput = (event) => {
  const value = event.target.value;
  emit('update:modelValue', value);
  emit('input', event);
  
  checkForVariableTrigger(value, event.target.selectionStart);
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
  } else {
    showSuggestions.value = false;
    currentVariablePrefix.value = '';
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
  }, 200);
};
</script>

<template>
  <div class="variable-input-wrapper relative">
    <InputText
      ref="inputRef"
      :modelValue="modelValue"
      :placeholder="placeholder"
      :size="size"
      class="w-full"
      @input="handleInput"
      @blur="hideSuggestions"
    />
    
    <!-- Variable Suggestions Dropdown -->
    <div
      v-if="showSuggestions && variableSuggestions.length > 0"
      class="absolute z-50 w-full mt-1 bg-surface-0 dark:bg-surface-900 border border-surface-300 dark:border-surface-700 rounded shadow-lg max-h-48 overflow-y-auto"
    >
      <div
        v-for="variable in variableSuggestions"
        :key="variable.key"
        @mousedown="selectVariable(variable)"
        class="px-3 py-2 cursor-pointer hover:bg-surface-100 dark:hover:bg-surface-800 transition"
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
</style>
