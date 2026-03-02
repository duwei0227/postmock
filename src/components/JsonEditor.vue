<script setup>
import { ref, onMounted, watch } from 'vue';
import { EditorView, basicSetup } from 'codemirror';
import { json } from '@codemirror/lang-json';
import { oneDark } from '@codemirror/theme-one-dark';
import { EditorState } from '@codemirror/state';

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
  }
});

const emit = defineEmits(['update:modelValue']);

const editorContainer = ref(null);
let editorView = null;

const isDark = ref(false);

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
    EditorView.editable.of(!props.readOnly),
    EditorView.updateListener.of((update) => {
      if (update.docChanged && !props.readOnly) {
        emit('update:modelValue', update.state.doc.toString());
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

  // 监听主题变化并重新创建编辑器
  watch(isDark, (newVal) => {
    if (editorView) {
      const currentDoc = editorView.state.doc.toString();
      editorView.destroy();
      
      const newExtensions = [
        basicSetup,
        json(),
        EditorView.editable.of(!props.readOnly),
        EditorView.updateListener.of((update) => {
          if (update.docChanged && !props.readOnly) {
            emit('update:modelValue', update.state.doc.toString());
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
  <div 
    ref="editorContainer" 
    class="json-editor-container border border-surface-300 dark:border-surface-700 rounded"
  ></div>
</template>

<style scoped>
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
</style>
