<script setup>
import { ref, onMounted, watch, onUnmounted } from 'vue';
import { EditorView, basicSetup } from 'codemirror';
import { json } from '@codemirror/lang-json';
import { oneDark } from '@codemirror/theme-one-dark';
import { EditorState } from '@codemirror/state';
import { autocompletion } from '@codemirror/autocomplete';

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  placeholder: {
    type: String,
    default: ''
  },
  readOnly: {
    type: Boolean,
    default: false
  },
  availableVariables: {
    type: Object,
    default: () => ({})
  }
});

const emit = defineEmits(['update:modelValue']);

const editorContainer = ref(null);
const parameterHintPanel = ref(null);
let editorView = null;

const isDark = ref(false);
const showParameterHint = ref(false);
const parameterHintContent = ref('');
const hintPosition = ref({ top: 0, left: 0 });

// 参数提示信息（与 VariableInput 保持一致）
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

// 检查是否正在输入函数参数
const checkForParameterHint = (text, cursorPos) => {
  // 查找光标前最近的 {{
  const beforeCursor = text.substring(0, cursorPos);
  const lastOpenBrace = beforeCursor.lastIndexOf('{{');
  const lastCloseBrace = beforeCursor.lastIndexOf('}}');
  
  // 如果找到 {{ 且在最后一个 }} 之后
  if (lastOpenBrace !== -1 && lastOpenBrace > lastCloseBrace) {
    const variableText = beforeCursor.substring(lastOpenBrace + 2);
    
    // 检查是否正在输入函数参数（包含左括号）
    const functionMatch = variableText.match(/^(\$\w+)\s*\(/);
    if (functionMatch) {
      const funcName = functionMatch[1];
      if (parameterHints[funcName]) {
        return funcName;
      }
    }
  }
  
  return null;
};

// 计算提示面板位置
const calculateHintPosition = () => {
  if (!editorView) return;
  
  const selection = editorView.state.selection.main;
  const coords = editorView.coordsAtPos(selection.head);
  
  if (coords) {
    const editorRect = editorContainer.value.getBoundingClientRect();
    hintPosition.value = {
      top: coords.bottom - editorRect.top + 5,
      left: coords.left - editorRect.left
    };
  }
};

// 创建变量自动完成功能
const createVariableCompletion = () => {
  return autocompletion({
    override: [
      (context) => {
        const word = context.matchBefore(/\{\{[^}]*$/);
        if (!word) return null;
        
        const variablePrefix = word.text.slice(2); // 移除 {{
        
        const options = [];
        
        // 添加所有可用变量（包括内置全局变量）
        // 先添加内置变量（以 $ 开头），再添加用户变量
        const builtInVars = [];
        const userVars = [];
        
        Object.entries(props.availableVariables).forEach(([key, value]) => {
          // 如果没有前缀，显示所有变量；如果有前缀，使用 includes 进行模糊匹配
          if (!variablePrefix || key.toLowerCase().includes(variablePrefix.toLowerCase())) {
            // 判断是否是内置变量（以 $ 开头）
            const isBuiltIn = key.startsWith('$');
            
            const option = {
              label: key, // 只使用变量名，不包含 {{}}
              type: 'variable',
              detail: isBuiltIn ? String(value) : `= ${String(value)}`,
              info: isBuiltIn ? 'Built-in variable' : 'User variable',
              boost: isBuiltIn ? 99 : 0,
              apply: (view, completion, from, to) => {
                // 计算实际的替换范围 - 从 {{ 开始
                const replaceFrom = word.from;
                
                // 检查光标后是否已经有 }}
                const textAfter = view.state.doc.sliceString(to, to + 2);
                const insert = textAfter === '}}' 
                  ? `{{${key}` // 如果后面已经有 }}，只插入到变量名
                  : `{{${key}}}`; // 否则插入完整的变量
                
                view.dispatch({
                  changes: { from: replaceFrom, to, insert }
                });
              }
            };
            
            if (isBuiltIn) {
              builtInVars.push(option);
            } else {
              userVars.push(option);
            }
          }
        });
        
        // 内置变量排在前面
        options.push(...builtInVars, ...userVars);
        
        return {
          from: word.from + 2, // 从变量名开始的位置（跳过 {{）
          options
        };
      }
    ],
    activateOnTyping: true,
    closeOnBlur: true,
    maxRenderedOptions: 50
  });
};

// 检测主题
const checkTheme = () => {
  isDark.value = document.documentElement.classList.contains('p-dark');
};

onMounted(() => {
  checkTheme();
  
  // 监听主题变化
  const observer = new MutationObserver(checkTheme);
  observer.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['class']
  });

  const lightTheme = EditorView.theme({
    '&': {
      backgroundColor: '#f8fafc',
      color: '#1e293b',
      fontSize: '14px',
      fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace'
    },
    '.cm-content': {
      caretColor: '#1e293b',
      padding: '8px 0'
    },
    '.cm-line': {
      padding: '0 8px'
    },
    '&.cm-focused': {
      outline: 'none'
    },
    '.cm-gutters': {
      backgroundColor: '#f1f5f9',
      color: '#64748b',
      border: 'none'
    }
  }, { dark: false });

  const extensions = [
    basicSetup,
    json(),
    createVariableCompletion(),
    EditorView.editable.of(!props.readOnly),
    EditorView.updateListener.of((update) => {
      if (update.docChanged && !props.readOnly) {
        emit('update:modelValue', update.state.doc.toString());
      }
      
      // 检查是否需要显示参数提示
      if (update.selectionSet || update.docChanged) {
        const text = update.state.doc.toString();
        const cursorPos = update.state.selection.main.head;
        const funcName = checkForParameterHint(text, cursorPos);
        
        if (funcName) {
          parameterHintContent.value = funcName;
          showParameterHint.value = true;
          calculateHintPosition();
        } else {
          showParameterHint.value = false;
        }
      }
    })
  ];

  // 根据主题添加相应的主题扩展
  if (isDark.value) {
    extensions.push(oneDark);
  } else {
    extensions.push(lightTheme);
  }

  editorView = new EditorView({
    state: EditorState.create({
      doc: props.modelValue,
      extensions
    }),
    parent: editorContainer.value
  });
  
  // 添加键盘事件监听
  const handleKeyDown = (event) => {
    if (event.key === 'Escape' && showParameterHint.value) {
      showParameterHint.value = false;
      event.preventDefault();
    }
  };
  
  editorContainer.value.addEventListener('keydown', handleKeyDown);
  
  // 清理函数
  onUnmounted(() => {
    if (editorContainer.value) {
      editorContainer.value.removeEventListener('keydown', handleKeyDown);
    }
  });

  // 监听主题变化并重新创建编辑器
  watch(isDark, (newVal) => {
    if (editorView) {
      const currentDoc = editorView.state.doc.toString();
      editorView.destroy();
      
      const newExtensions = [
        basicSetup,
        json(),
        createVariableCompletion(),
        EditorView.editable.of(!props.readOnly),
        EditorView.updateListener.of((update) => {
          if (update.docChanged && !props.readOnly) {
            emit('update:modelValue', update.state.doc.toString());
          }
          
          // 检查是否需要显示参数提示
          if (update.selectionSet || update.docChanged) {
            const text = update.state.doc.toString();
            const cursorPos = update.state.selection.main.head;
            const funcName = checkForParameterHint(text, cursorPos);
            
            if (funcName) {
              parameterHintContent.value = funcName;
              showParameterHint.value = true;
              calculateHintPosition();
            } else {
              showParameterHint.value = false;
            }
          }
        })
      ];

      if (newVal) {
        newExtensions.push(oneDark);
      } else {
        newExtensions.push(lightTheme);
      }

      editorView = new EditorView({
        state: EditorState.create({
          doc: currentDoc,
          extensions: newExtensions
        }),
        parent: editorContainer.value
      });
    }
  });
  
  // 监听 availableVariables 变化并重新创建编辑器
  watch(() => props.availableVariables, () => {
    if (editorView) {
      const currentDoc = editorView.state.doc.toString();
      editorView.destroy();
      
      const newExtensions = [
        basicSetup,
        json(),
        createVariableCompletion(),
        EditorView.editable.of(!props.readOnly),
        EditorView.updateListener.of((update) => {
          if (update.docChanged && !props.readOnly) {
            emit('update:modelValue', update.state.doc.toString());
          }
          
          // 检查是否需要显示参数提示
          if (update.selectionSet || update.docChanged) {
            const text = update.state.doc.toString();
            const cursorPos = update.state.selection.main.head;
            const funcName = checkForParameterHint(text, cursorPos);
            
            if (funcName) {
              parameterHintContent.value = funcName;
              showParameterHint.value = true;
              calculateHintPosition();
            } else {
              showParameterHint.value = false;
            }
          }
        })
      ];

      if (isDark.value) {
        newExtensions.push(oneDark);
      } else {
        newExtensions.push(lightTheme);
      }

      editorView = new EditorView({
        state: EditorState.create({
          doc: currentDoc,
          extensions: newExtensions
        }),
        parent: editorContainer.value
      });
    }
  }, { deep: true });
});

watch(() => props.modelValue, (newVal) => {
  if (editorView && newVal !== editorView.state.doc.toString()) {
    editorView.dispatch({
      changes: {
        from: 0,
        to: editorView.state.doc.length,
        insert: newVal
      }
    });
  }
});
</script>

<template>
  <div class="json-editor-wrapper relative">
    <div 
      ref="editorContainer" 
      class="json-editor-container border border-surface-300 dark:border-surface-700 rounded"
    ></div>
    
    <!-- Parameter Hint Panel -->
    <div
      v-if="showParameterHint && parameterHints[parameterHintContent]"
      ref="parameterHintPanel"
      class="absolute z-50 bg-surface-0 dark:bg-surface-900 border border-primary-300 dark:border-primary-700 rounded shadow-lg p-4 min-w-96 max-w-2xl"
      :style="{ top: hintPosition.top + 'px', left: hintPosition.left + 'px' }"
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
.json-editor-wrapper {
  position: relative;
}

.json-editor-container {
  min-height: 300px;
  overflow: auto;
}

:deep(.cm-editor) {
  height: 100%;
}

:deep(.cm-scroller) {
  overflow: auto;
}

/* 自定义自动完成提示样式 */
:deep(.cm-tooltip.cm-tooltip-autocomplete) {
  background-color: var(--surface-0);
  border: 1px solid var(--surface-300);
  border-radius: 6px;
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
}

:deep(.p-dark .cm-tooltip.cm-tooltip-autocomplete) {
  background-color: var(--surface-900);
  border-color: var(--surface-700);
}

/* 自动完成选项 */
:deep(.cm-completionLabel) {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  color: var(--primary-color);
}

/* 详情信息 */
:deep(.cm-completionDetail) {
  font-size: 0.75rem;
  color: var(--text-color-secondary);
  font-style: normal;
}

/* 选中的选项 */
:deep(.cm-completionIcon) {
  display: none;
}

/* 亮色主题 - 选中项 */
:deep(.cm-tooltip.cm-tooltip-autocomplete li[aria-selected="true"]) {
  background-color: #3b82f6 !important; /* 蓝色背景 */
}

:deep(.cm-tooltip.cm-tooltip-autocomplete li[aria-selected="true"] .cm-completionLabel) {
  color: #ffffff !important; /* 白色文字 */
}

:deep(.cm-tooltip.cm-tooltip-autocomplete li[aria-selected="true"] .cm-completionDetail) {
  color: #e0e7ff !important; /* 浅蓝色文字 */
}

/* 暗色主题 - 选中项 */
:deep(.p-dark .cm-tooltip.cm-tooltip-autocomplete li[aria-selected="true"]) {
  background-color: #2563eb !important; /* 深蓝色背景 */
}

:deep(.p-dark .cm-tooltip.cm-tooltip-autocomplete li[aria-selected="true"] .cm-completionLabel) {
  color: #ffffff !important; /* 白色文字 */
}

:deep(.p-dark .cm-tooltip.cm-tooltip-autocomplete li[aria-selected="true"] .cm-completionDetail) {
  color: #dbeafe !important; /* 浅蓝色文字 */
}
</style>
