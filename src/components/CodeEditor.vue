<script setup>
import { ref, onMounted, watch } from 'vue';
import { EditorView, basicSetup } from 'codemirror';
import { json } from '@codemirror/lang-json';
import { xml } from '@codemirror/lang-xml';
import { html } from '@codemirror/lang-html';
import { oneDark } from '@codemirror/theme-one-dark';
import { EditorState } from '@codemirror/state';

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  language: {
    type: String,
    default: 'json', // json, xml, html, text
    validator: (value) => ['json', 'xml', 'html', 'text'].includes(value)
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

const checkTheme = () => {
  isDark.value = document.documentElement.classList.contains('p-dark');
};

const getLanguageExtension = () => {
  switch (props.language) {
    case 'json':
      return json();
    case 'xml':
      return xml();
    case 'html':
      return html();
    default:
      return [];
  }
};

onMounted(() => {
  checkTheme();
  
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
    getLanguageExtension(),
    EditorView.editable.of(!props.readOnly),
    EditorView.updateListener.of((update) => {
      if (update.docChanged && !props.readOnly) {
        emit('update:modelValue', update.state.doc.toString());
      }
    })
  ];

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

  watch(isDark, (newVal) => {
    if (editorView) {
      const currentDoc = editorView.state.doc.toString();
      editorView.destroy();
      
      const newExtensions = [
        basicSetup,
        getLanguageExtension(),
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

watch(() => props.language, () => {
  if (editorView) {
    const currentDoc = editorView.state.doc.toString();
    editorView.destroy();
    
    const newExtensions = [
      basicSetup,
      getLanguageExtension(),
      EditorView.editable.of(!props.readOnly),
      EditorView.updateListener.of((update) => {
        if (update.docChanged && !props.readOnly) {
          emit('update:modelValue', update.state.doc.toString());
        }
      })
    ];

    if (isDark.value) {
      newExtensions.push(oneDark);
    } else {
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
</script>

<template>
  <div 
    ref="editorContainer" 
    class="code-editor-container border border-surface-300 dark:border-surface-700 rounded"
  ></div>
</template>

<style scoped>
.code-editor-container {
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
