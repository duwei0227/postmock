<script setup>
import { ref, onMounted, watch } from 'vue';
import { EditorView, basicSetup } from 'codemirror';
import { Decoration } from '@codemirror/view';
import { json } from '@codemirror/lang-json';
import { xml } from '@codemirror/lang-xml';
import { html } from '@codemirror/lang-html';
import { oneDark } from '@codemirror/theme-one-dark';
import { EditorState, StateEffect, StateField } from '@codemirror/state';

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
  },
  searchMatches: {
    type: Array,
    default: () => []
  },
  currentMatchIndex: {
    type: Number,
    default: -1
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

// 搜索高亮相关
const setSearchHighlights = StateEffect.define();

const searchHighlightField = StateField.define({
  create() {
    return Decoration.none;
  },
  update(highlights, tr) {
    for (let effect of tr.effects) {
      if (effect.is(setSearchHighlights)) {
        return effect.value;
      }
    }
    return highlights;
  },
  provide: f => EditorView.decorations.from(f)
});

const highlightTheme = EditorView.baseTheme({
  '.cm-searchMatch': {
    backgroundColor: '#fef08a !important',
    color: '#000 !important'
  },
  '.cm-searchMatch-current': {
    backgroundColor: '#fb923c !important',
    color: '#fff !important',
    fontWeight: 'bold !important'
  },
  '.p-dark .cm-searchMatch': {
    backgroundColor: '#a16207 !important',
    color: '#fff !important'
  },
  '.p-dark .cm-searchMatch-current': {
    backgroundColor: '#ea580c !important',
    color: '#fff !important',
    fontWeight: 'bold !important'
  }
});

const updateSearchHighlights = () => {
  if (!editorView) return;
  
  const decorations = [];
  
  props.searchMatches.forEach((match, idx) => {
    const isCurrent = idx === props.currentMatchIndex;
    const deco = Decoration.mark({
      class: isCurrent ? 'cm-searchMatch-current' : 'cm-searchMatch'
    }).range(match.index, match.index + match.length);
    decorations.push(deco);
  });
  
  const decorationSet = Decoration.set(decorations.sort((a, b) => a.from - b.from));
  
  editorView.dispatch({
    effects: setSearchHighlights.of(decorationSet)
  });
  
  // 滚动到当前匹配项
  if (props.currentMatchIndex >= 0 && props.searchMatches[props.currentMatchIndex]) {
    const match = props.searchMatches[props.currentMatchIndex];
    editorView.dispatch({
      selection: { anchor: match.index, head: match.index + match.length },
      scrollIntoView: true
    });
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
    searchHighlightField,
    highlightTheme,
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
        searchHighlightField,
        highlightTheme,
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
      
      updateSearchHighlights();
    }
  });
  
  // 监听搜索匹配变化
  watch(() => [props.searchMatches, props.currentMatchIndex], () => {
    updateSearchHighlights();
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

watch(() => props.language, () => {
  if (editorView) {
    const currentDoc = editorView.state.doc.toString();
    editorView.destroy();
    
    const newExtensions = [
      basicSetup,
      getLanguageExtension(),
      EditorView.editable.of(!props.readOnly),
      searchHighlightField,
      highlightTheme,
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
    
    updateSearchHighlights();
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
