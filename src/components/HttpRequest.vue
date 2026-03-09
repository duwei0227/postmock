<script setup>
import { ref, watch, computed, inject, onMounted, onUnmounted } from 'vue';
import JsonEditor from './JsonEditor.vue';
import CodeEditor from './CodeEditor.vue';
import VariableInput from './VariableInput.vue';
import { fetch } from '@tauri-apps/plugin-http';

const props = defineProps({
  request: {
    type: Object,
    default: () => ({
      id: null,
      name: 'Untitled Request',
      method: 'GET',
      url: '',
      params: [{ key: '', value: '', enabled: true }],
      headers: [{ key: '', value: '', enabled: true }],
      body: {
        type: 'none',
        raw: '',
        formData: [{ key: '', value: '', type: 'text', enabled: true }],
        urlencoded: [{ key: '', value: '', enabled: true }]
      },
      auth: { 
        type: 'none',
        token: '',
        username: '',
        password: ''
      },
      tests: '',
      saved: false // 是否已保存
    })
  },
  environmentManager: {
    type: Object,
    default: null
  },
  collections: {
    type: Array,
    default: () => []
  }
});

const emit = defineEmits(['update:request', 'close', 'add-console-log', 'save-request']);

// Tests 相关数据
const testsAccordion = ref(['0', '1', '2']); // 默认展开所有面板
const statusCodeTests = ref([
  { enabled: true, operator: 'equals', expectedValue: '200', description: '' }
]);
const jsonFieldTests = ref([
  { enabled: false, jsonPath: '', operator: 'equals', expectedValue: '', description: '' }
]);
const globalVariables = ref([
  { enabled: false, variableName: '', valueType: 'jsonPath', jsonPath: '', customValue: '', description: '' }
]);

// 操作符选项
const operatorOptions = [
  { label: '等于 (=)', value: 'equals' },
  { label: '不等于 (≠)', value: 'notEquals' },
  { label: '大于 (>)', value: 'greaterThan' },
  { label: '小于 (<)', value: 'lessThan' },
  { label: '大于等于 (≥)', value: 'greaterThanOrEquals' },
  { label: '小于等于 (≤)', value: 'lessThanOrEquals' },
  { label: '包含', value: 'contains' },
  { label: '不包含', value: 'notContains' },
  { label: '存在', value: 'exists' },
  { label: '不存在', value: 'notExists' }
];

// 添加测试行
const addStatusCodeTest = () => {
  statusCodeTests.value.push({ enabled: true, operator: 'equals', expectedValue: '', description: '' });
};

const addJsonFieldTest = () => {
  jsonFieldTests.value.push({ enabled: true, jsonPath: '', operator: 'equals', expectedValue: '', description: '' });
};

const addGlobalVariable = () => {
  globalVariables.value.push({ enabled: true, variableName: '', valueType: 'jsonPath', jsonPath: '', customValue: '', description: '' });
};

// 删除测试行
const removeStatusCodeTest = (index) => {
  if (statusCodeTests.value.length > 1) {
    statusCodeTests.value.splice(index, 1);
  }
};

const removeJsonFieldTest = (index) => {
  if (jsonFieldTests.value.length > 1) {
    jsonFieldTests.value.splice(index, 1);
  }
};

const removeGlobalVariable = (index) => {
  if (globalVariables.value.length > 1) {
    globalVariables.value.splice(index, 1);
  }
};

// 从JSON路径提取值
const extractValueFromJsonPath = (jsonData, path) => {
  try {
    // 移除开头的 $. 或 $
    let cleanPath = path.replace(/^\$\.?/, '');
    
    // 分割路径
    const parts = cleanPath.split(/\.|\[|\]/).filter(p => p);
    
    let value = jsonData;
    for (const part of parts) {
      if (value === null || value === undefined) {
        return undefined;
      }
      value = value[part];
    }
    
    return value;
  } catch (error) {
    console.error('Error extracting value from JSON path:', error);
    return undefined;
  }
};

// 执行测试
const executeTests = (responseData) => {
  const results = {
    statusCode: [],
    jsonFields: [],
    globalVars: []
  };
  
  // 1. 状态码测试
  statusCodeTests.value.forEach((test, index) => {
    if (!test.enabled) return;
    
    const actualStatus = responseData.status;
    const expectedStatus = parseInt(test.expectedValue);
    let passed = false;
    
    switch (test.operator) {
      case 'equals':
        passed = actualStatus === expectedStatus;
        break;
      case 'notEquals':
        passed = actualStatus !== expectedStatus;
        break;
      case 'greaterThan':
        passed = actualStatus > expectedStatus;
        break;
      case 'lessThan':
        passed = actualStatus < expectedStatus;
        break;
      case 'greaterThanOrEquals':
        passed = actualStatus >= expectedStatus;
        break;
      case 'lessThanOrEquals':
        passed = actualStatus <= expectedStatus;
        break;
    }
    
    results.statusCode.push({
      index,
      passed,
      message: `Status code ${actualStatus} ${test.operator} ${expectedStatus}`,
      description: test.description
    });
  });
  
  // 2. JSON字段测试
  let jsonData = null;
  try {
    jsonData = JSON.parse(responseData.rawBody);
  } catch (e) {
    console.error('Response is not valid JSON');
  }
  
  if (jsonData) {
    jsonFieldTests.value.forEach((test, index) => {
      if (!test.enabled || !test.jsonPath) return;
      
      const actualValue = extractValueFromJsonPath(jsonData, test.jsonPath);
      let passed = false;
      
      switch (test.operator) {
        case 'equals':
          passed = String(actualValue) === String(test.expectedValue);
          break;
        case 'notEquals':
          passed = String(actualValue) !== String(test.expectedValue);
          break;
        case 'contains':
          passed = String(actualValue).includes(test.expectedValue);
          break;
        case 'notContains':
          passed = !String(actualValue).includes(test.expectedValue);
          break;
        case 'exists':
          passed = actualValue !== undefined && actualValue !== null;
          break;
        case 'notExists':
          passed = actualValue === undefined || actualValue === null;
          break;
        case 'greaterThan':
          passed = Number(actualValue) > Number(test.expectedValue);
          break;
        case 'lessThan':
          passed = Number(actualValue) < Number(test.expectedValue);
          break;
        case 'greaterThanOrEquals':
          passed = Number(actualValue) >= Number(test.expectedValue);
          break;
        case 'lessThanOrEquals':
          passed = Number(actualValue) <= Number(test.expectedValue);
          break;
      }
      
      results.jsonFields.push({
        index,
        passed,
        message: `${test.jsonPath}: ${actualValue} ${test.operator} ${test.expectedValue}`,
        description: test.description,
        actualValue,
        operator: test.operator,
        expectedValue: test.expectedValue,
        jsonPath: test.jsonPath
      });
    });
    
    // 3. 设置全局变量
    globalVariables.value.forEach((variable, index) => {
      if (!variable.enabled || !variable.variableName) return;
      
      let value;
      
      // 根据类型决定值的来源
      if (variable.valueType === 'customValue') {
        // 使用自定义值
        value = variable.customValue;
      } else {
        // 使用JSON路径提取值
        if (!variable.jsonPath || !jsonData) return;
        value = extractValueFromJsonPath(jsonData, variable.jsonPath);
      }
      
      if (value !== undefined && props.environmentManager) {
        const manager = props.environmentManager.value;
        if (manager && typeof manager.setGlobalVariable === 'function') {
          manager.setGlobalVariable(variable.variableName, value);
          
          results.globalVars.push({
            index,
            success: true,
            message: `Set ${variable.variableName} = ${value}`,
            description: variable.description
          });
        }
      }
    });
  }
  
  return results;
};

// 深拷贝创建完全独立的本地请求实例
const localRequest = ref(JSON.parse(JSON.stringify(props.request)));
const activeParamTab = ref(0);
const activeResponseTab = ref(0); // 0: Body, 1: Headers, 2: Test Results
const activeBodyViewTab = ref(0); // 0: Pretty, 1: Raw
const response = ref(null);
const isLoading = ref(false);
const isEditingName = ref(false);
const responseHeight = ref(300); // 默认响应区域高度
const isResizing = ref(false);
const isResponseCollapsed = ref(true); // 默认收起
const testResults = ref(null); // 存储测试结果
let abortController = null; // 用于取消请求

// 监听 props.request.name 的变化，同步更新 localRequest.name
watch(
  () => props.request.name,
  (newName) => {
    if (newName && newName !== localRequest.value.name) {
      console.log('[HttpRequest] Request name changed from parent, updating:', newName);
      localRequest.value.name = newName;
    }
  }
);

// 检查是否需要自动显示保存对话框
if (props.request._showSaveDialog && props.request._initialCollection) {
  // 延迟显示对话框，确保组件已完全挂载
  setTimeout(() => {
    saveRequestName.value = localRequest.value.name;
    selectedCollection.value = props.request._initialCollection;
    selectedFolder.value = props.request._initialFolder || null;
    
    // 设置选中的 key（使用 '/' 作为分隔符）
    if (selectedFolder.value) {
      // 构建 folder 的 key: collection/collectionId/folderId
      const folderKey = `collection/${selectedCollection.value.id}/${selectedFolder.value.id}`;
      selectedKeys.value = { [folderKey]: true };
    } else {
      // 只选中 collection: collection/collectionId
      const collectionKey = `collection/${selectedCollection.value.id}`;
      selectedKeys.value = { [collectionKey]: true };
    }
    
    showSaveDialog.value = true;
    
    // 立即清除临时标记，防止再次触发
    delete props.request._showSaveDialog;
    delete props.request._initialCollection;
    delete props.request._initialFolder;
  }, 100);
}

// 获取可用变量
const availableVariables = computed(() => {
  console.log('[HttpRequest] Computing availableVariables');
  console.log('[HttpRequest] props.environmentManager:', props.environmentManager);
  console.log('[HttpRequest] props.environmentManager type:', typeof props.environmentManager);
  
  if (props.environmentManager) {
    // environmentManager 可能直接是组件实例，也可能是 ref
    let manager = props.environmentManager;
    
    // 如果是 ref，通过 .value 访问
    if (manager && manager.value) {
      console.log('[HttpRequest] environmentManager is a ref, accessing .value');
      manager = manager.value;
    }
    
    console.log('[HttpRequest] Manager:', manager);
    console.log('[HttpRequest] Manager type:', typeof manager);
    console.log('[HttpRequest] Manager keys:', manager ? Object.keys(manager) : 'null');
    
    if (manager && typeof manager.getAllAvailableVariables === 'function') {
      // 访问 currentEnvironment 以建立响应式依赖
      const currentEnv = manager.currentEnvironment;
      console.log('[HttpRequest] Current environment:', currentEnv);
      const vars = manager.getAllAvailableVariables();
      console.log('[HttpRequest] Available variables:', vars);
      return vars;
    } else {
      console.log('[HttpRequest] getAllAvailableVariables is not a function');
    }
  } else {
    console.log('[HttpRequest] No environmentManager provided');
  }
  
  console.log('[HttpRequest] Returning empty variables');
  return {};
});

// 监听环境变化
watch(() => {
  let manager = props.environmentManager;
  if (manager && manager.value) {
    manager = manager.value;
  }
  return manager?.currentEnvironment;
}, (newVal) => {
  console.log('[HttpRequest] Environment changed to:', newVal);
}, { immediate: true });

// 替换变量的辅助函数
const replaceVariables = (str) => {
  if (!str || typeof str !== 'string') return str;
  
  console.log('[HttpRequest] replaceVariables called with:', str);
  
  if (props.environmentManager) {
    // environmentManager 可能直接是组件实例，也可能是 ref
    let manager = props.environmentManager;
    
    // 如果是 ref，通过 .value 访问
    if (manager && manager.value) {
      manager = manager.value;
    }
    
    console.log('[HttpRequest] Manager:', manager);
    console.log('[HttpRequest] Manager has replaceVariables:', typeof manager?.replaceVariables);
    
    if (manager && typeof manager.replaceVariables === 'function') {
      const result = manager.replaceVariables(str);
      console.log('[HttpRequest] Replaced result:', result);
      return result;
    }
  }
  
  console.log('[HttpRequest] No replacement, returning original:', str);
  return str;
};

const methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'];

const authTypes = [
  { label: 'No Auth', value: 'none' },
  { label: 'Bearer Token', value: 'bearer' },
  { label: 'Basic Auth', value: 'basic' }
];

const bodyTypes = [
  { label: 'none', value: 'none' },
  { label: 'form-data', value: 'form-data' },
  { label: 'x-www-form-urlencoded', value: 'x-www-form-urlencoded' },
  { label: 'json', value: 'json' }
];

// 常用 HTTP Headers
const commonHeaders = [
  'Accept',
  'Accept-Encoding',
  'Accept-Language',
  'Authorization',
  'Cache-Control',
  'Connection',
  'Content-Type',
  'Cookie',
  'Host',
  'Origin',
  'Referer',
  'User-Agent',
  'X-Requested-With',
  'X-Forwarded-For',
  'X-Forwarded-Proto',
  'X-Api-Key',
  'X-Auth-Token'
];

// Header 值的预设选项
const headerValueOptions = {
  'Content-Type': [
    'application/json',
    'application/xml',
    'application/x-www-form-urlencoded',
    'multipart/form-data',
    'text/plain',
    'text/html',
    'text/xml',
    'application/javascript',
    'application/pdf',
    'image/png',
    'image/jpeg',
    'image/gif'
  ],
  'Accept': [
    'application/json',
    'application/xml',
    'text/html',
    'text/plain',
    '*/*'
  ],
  'Accept-Encoding': [
    'gzip',
    'deflate',
    'br',
    'gzip, deflate, br'
  ],
  'Accept-Language': [
    'en-US',
    'en',
    'zh-CN',
    'zh',
    'en-US,en;q=0.9',
    'zh-CN,zh;q=0.9,en;q=0.8'
  ],
  'Cache-Control': [
    'no-cache',
    'no-store',
    'max-age=0',
    'max-age=3600',
    'public',
    'private'
  ],
  'Connection': [
    'keep-alive',
    'close'
  ]
};

const filteredHeaderKeys = ref([]);
const filteredHeaderValues = ref([]);
const activeHeaderKeyIndex = ref(-1);
const activeHeaderValueIndex = ref(-1);

const filterHeaderKeys = (event, index) => {
  const query = event.target.value.toLowerCase();
  if (query) {
    filteredHeaderKeys.value = commonHeaders.filter(h => 
      h.toLowerCase().includes(query)
    );
    activeHeaderKeyIndex.value = index;
  } else {
    filteredHeaderKeys.value = [];
    activeHeaderKeyIndex.value = -1;
  }
};

const selectHeaderKey = (header, index) => {
  localRequest.value.headers[index].key = header;
  filteredHeaderKeys.value = [];
  activeHeaderKeyIndex.value = -1;
  onHeaderChange();
};

const filterHeaderValues = (event, index) => {
  const headerKey = localRequest.value.headers[index].key;
  const query = event.target.value.toLowerCase();
  
  if (headerKey && headerValueOptions[headerKey]) {
    if (query) {
      filteredHeaderValues.value = headerValueOptions[headerKey].filter(v => 
        v.toLowerCase().includes(query)
      );
    } else {
      filteredHeaderValues.value = headerValueOptions[headerKey];
    }
    activeHeaderValueIndex.value = index;
  } else {
    filteredHeaderValues.value = [];
    activeHeaderValueIndex.value = -1;
  }
};

const selectHeaderValue = (value, index) => {
  localRequest.value.headers[index].value = value;
  filteredHeaderValues.value = [];
  activeHeaderValueIndex.value = -1;
  onHeaderChange();
};

const hideHeaderSuggestions = () => {
  setTimeout(() => {
    filteredHeaderKeys.value = [];
    filteredHeaderValues.value = [];
    activeHeaderKeyIndex.value = -1;
    activeHeaderValueIndex.value = -1;
  }, 200);
};

watch(localRequest, (newVal) => {
  emit('update:request', newVal);
}, { deep: true });

// 监听 body type 变化，自动更新 Content-Type
watch(() => localRequest.value.body.type, (newType, oldType) => {
  // 找到 Content-Type header 的索引
  const contentTypeIndex = localRequest.value.headers.findIndex(
    h => h.key.toLowerCase() === 'content-type'
  );
  
  if (newType === 'none') {
    // 如果选择 none，移除 Content-Type
    if (contentTypeIndex !== -1) {
      localRequest.value.headers.splice(contentTypeIndex, 1);
      // 确保至少有一个空行
      if (localRequest.value.headers.length === 0) {
        localRequest.value.headers.push({ key: '', value: '', enabled: true });
      }
    }
  } else {
    // 根据类型设置 Content-Type
    let contentType = '';
    switch (newType) {
      case 'json':
        contentType = 'application/json';
        break;
      case 'x-www-form-urlencoded':
        contentType = 'application/x-www-form-urlencoded';
        break;
      case 'form-data':
        contentType = 'multipart/form-data';
        break;
    }
    
    if (contentType) {
      if (contentTypeIndex !== -1) {
        // 更新现有的 Content-Type
        localRequest.value.headers[contentTypeIndex].value = contentType;
        localRequest.value.headers[contentTypeIndex].enabled = true;
      } else {
        // 添加新的 Content-Type（在最后一个空行之前插入）
        const lastIndex = localRequest.value.headers.length - 1;
        const lastHeader = localRequest.value.headers[lastIndex];
        
        if (lastHeader && !lastHeader.key && !lastHeader.value) {
          // 如果最后一行是空行，在它之前插入
          localRequest.value.headers.splice(lastIndex, 0, {
            key: 'Content-Type',
            value: contentType,
            enabled: true
          });
        } else {
          // 否则直接添加
          localRequest.value.headers.push({
            key: 'Content-Type',
            value: contentType,
            enabled: true
          });
          // 确保有空行
          localRequest.value.headers.push({ key: '', value: '', enabled: true });
        }
      }
    }
  }
});

// SplitButton menu items
const sendMenuItems = ref([
  {
    label: 'Send And Download',
    icon: 'pi pi-download',
    command: () => sendAndDownload()
  }
]);

// 根据 Content-Type 获取文件扩展名
const getExtensionFromContentType = (contentType) => {
  if (!contentType) return '';
  
  const mimeType = contentType.split(';')[0].trim().toLowerCase();
  const mimeToExt = {
    // 文档
    'application/pdf': '.pdf',
    'application/msword': '.doc',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': '.docx',
    'application/vnd.ms-excel': '.xls',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': '.xlsx',
    'application/vnd.ms-powerpoint': '.ppt',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation': '.pptx',
    
    // 图片
    'image/jpeg': '.jpg',
    'image/jpg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
    'image/svg+xml': '.svg',
    'image/bmp': '.bmp',
    'image/tiff': '.tiff',
    
    // 音视频
    'audio/mpeg': '.mp3',
    'audio/wav': '.wav',
    'audio/ogg': '.ogg',
    'video/mp4': '.mp4',
    'video/mpeg': '.mpeg',
    'video/webm': '.webm',
    'video/ogg': '.ogv',
    
    // 压缩文件
    'application/zip': '.zip',
    'application/x-rar-compressed': '.rar',
    'application/x-7z-compressed': '.7z',
    'application/x-tar': '.tar',
    'application/gzip': '.gz',
    
    // 文本
    'text/plain': '.txt',
    'text/html': '.html',
    'text/css': '.css',
    'text/javascript': '.js',
    'text/csv': '.csv',
    'text/xml': '.xml',
    'application/json': '.json',
    'application/xml': '.xml',
    
    // 其他
    'application/octet-stream': '.bin'
  };
  
  return mimeToExt[mimeType] || '';
};

const cancelRequest = () => {
  if (abortController) {
    abortController.abort();
    abortController = null;
    isLoading.value = false;
    
    // 生成取消请求的测试结果 - 所有断言失败
    testResults.value = {
      statusCode: statusCodeTests.value
        .filter(test => test.enabled)
        .map((test, index) => ({
          index,
          passed: false,
          message: `Request cancelled - Status code test failed`,
          description: test.description
        })),
      jsonFields: jsonFieldTests.value
        .filter(test => test.enabled && test.jsonPath)
        .map((test, index) => ({
          index,
          passed: false,
          message: `Request cancelled - JSON field test failed`,
          description: test.description,
          actualValue: undefined,
          operator: test.operator,
          expectedValue: test.expectedValue,
          jsonPath: test.jsonPath
        })),
      globalVars: []
    };
    
    if (window.$toast) {
      window.$toast.add({
        severity: 'info',
        summary: 'Cancelled',
        detail: 'Request cancelled by user',
        life: 2000
      });
    }
  }
};

const sendRequest = async () => {
  // 创建新的 AbortController
  abortController = new AbortController();
  
  isLoading.value = true;
  isResponseCollapsed.value = false; // 发送请求时展开响应区域
  const startTime = Date.now();
  
  // 准备console log数据
  const consoleLog = {
    id: Date.now(),
    startTime,
    method: localRequest.value.method,
    url: '',
    requestHeaders: {},
    requestBody: null,
    endTime: 0,
    status: 0,
    statusText: '',
    duration: '',
    responseHeaders: {},
    responseBody: ''
  };
  
  try {
    // 构建完整的 URL（包含查询参数）- 替换变量
    console.log('[HttpRequest] Original URL:', localRequest.value.url);
    let url = replaceVariables(localRequest.value.url);
    console.log('[HttpRequest] URL after variable replacement:', url);
    
    const enabledParams = localRequest.value.params.filter(p => p.enabled && p.key);
    console.log('[HttpRequest] Enabled params:', enabledParams);
    
    if (enabledParams.length > 0) {
      const queryString = enabledParams
        .map(p => {
          const key = replaceVariables(p.key);
          const value = replaceVariables(p.value);
          console.log(`[HttpRequest] Param: ${p.key} -> ${key}, ${p.value} -> ${value}`);
          return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
        })
        .join('&');
      console.log('[HttpRequest] Query string:', queryString);
      url += (url.includes('?') ? '&' : '?') + queryString;
      console.log('[HttpRequest] Final URL with params:', url);
    }
    
    consoleLog.url = url;

    // 构建请求头 - 替换变量
    const headers = {};
    localRequest.value.headers
      .filter(h => h.enabled && h.key)
      .forEach(h => {
        headers[replaceVariables(h.key)] = replaceVariables(h.value);
      });

    // 添加认证头 - 替换变量
    if (localRequest.value.auth.type === 'bearer' && localRequest.value.auth.token) {
      headers['Authorization'] = `Bearer ${replaceVariables(localRequest.value.auth.token)}`;
    } else if (localRequest.value.auth.type === 'basic' && localRequest.value.auth.username) {
      const username = replaceVariables(localRequest.value.auth.username);
      const password = replaceVariables(localRequest.value.auth.password);
      const credentials = btoa(`${username}:${password}`);
      headers['Authorization'] = `Basic ${credentials}`;
    }
    
    consoleLog.requestHeaders = { ...headers };

    // 构建请求体 - 替换变量
    let body = null;
    if (['POST', 'PUT', 'PATCH'].includes(localRequest.value.method)) {
      if (localRequest.value.body.type === 'json' && localRequest.value.body.raw) {
        headers['Content-Type'] = 'application/json';
        body = replaceVariables(localRequest.value.body.raw);
      } else if (localRequest.value.body.type === 'x-www-form-urlencoded') {
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
        const enabledData = localRequest.value.body.urlencoded.filter(r => r.enabled && r.key);
        body = enabledData
          .map(r => `${encodeURIComponent(replaceVariables(r.key))}=${encodeURIComponent(replaceVariables(r.value))}`)
          .join('&');
      } else if (localRequest.value.body.type === 'form-data') {
        // FormData 需要特殊处理，这里简化为 JSON
        const formDataObj = {};
        localRequest.value.body.formData
          .filter(r => r.enabled && r.key && r.type === 'text')
          .forEach(r => {
            formDataObj[replaceVariables(r.key)] = replaceVariables(r.value);
          });
        headers['Content-Type'] = 'application/json';
        body = JSON.stringify(formDataObj);
      }
    }
    
    consoleLog.requestBody = body;

    // 发送请求（添加 signal 支持取消）
    const fetchResponse = await fetch(url, {
      method: localRequest.value.method,
      headers,
      body,
      signal: abortController?.signal
    });

    const endTime = Date.now();
    const contentType = fetchResponse.headers.get('content-type') || '';
    
    // 检查是否是图片类型
    let responseText = '';
    let imageDataUrl = '';
    
    if (contentType.toLowerCase().includes('image/')) {
      // 处理图片响应
      const arrayBuffer = await fetchResponse.arrayBuffer();
      const blob = new Blob([arrayBuffer], { type: contentType });
      imageDataUrl = URL.createObjectURL(blob);
      responseText = `[Image: ${contentType}]`;
    } else {
      // 处理文本响应
      responseText = await fetchResponse.text();
    }
    
    // 尝试解析为 JSON
    let responseBody = responseText;
    if (!contentType.includes('image/')) {
      try {
        const jsonData = JSON.parse(responseText);
        responseBody = JSON.stringify(jsonData, null, 2);
      } catch (e) {
        // 不是 JSON，保持原样
      }
    }

    // 计算响应大小
    const size = new Blob([responseText]).size;
    const sizeStr = size < 1024 
      ? `${size}B` 
      : size < 1024 * 1024 
        ? `${(size / 1024).toFixed(2)}KB` 
        : `${(size / (1024 * 1024)).toFixed(2)}MB`;

    response.value = {
      status: fetchResponse.status,
      statusText: fetchResponse.statusText,
      time: `${endTime - startTime}ms`,
      size: sizeStr,
      body: responseBody,
      rawBody: responseText,
      headers: Object.fromEntries(fetchResponse.headers.entries()),
      contentType: contentType,
      imageDataUrl: imageDataUrl
    };
    
    // 更新console log
    consoleLog.endTime = endTime;
    consoleLog.status = fetchResponse.status;
    consoleLog.statusText = fetchResponse.statusText;
    consoleLog.duration = `${endTime - startTime}ms`;
    consoleLog.responseHeaders = Object.fromEntries(fetchResponse.headers.entries());
    consoleLog.responseBody = responseText.substring(0, 1000); // 限制长度
    
    emit('add-console-log', consoleLog);
    
    // 执行测试并保存结果
    if (response.value) {
      testResults.value = executeTests(response.value);
      console.log('Test Results:', testResults.value);
    }
  } catch (error) {
    const endTime = Date.now();
    
    // 检查是否是用户取消的请求
    if (error.name === 'AbortError') {
      console.log('Request was cancelled by user');
      return; // 用户取消，不显示错误
    }
    
    response.value = {
      status: 0,
      statusText: 'Error',
      time: `${endTime - startTime}ms`,
      size: '0B',
      body: `Error: ${error.message || error}`,
      rawBody: `Error: ${error.message || error}`,
      headers: {},
      contentType: '',
      imageDataUrl: ''
    };
    
    // 更新console log for error
    consoleLog.endTime = endTime;
    consoleLog.status = 0;
    consoleLog.statusText = 'Error';
    consoleLog.duration = `${endTime - startTime}ms`;
    consoleLog.responseBody = `Error: ${error.message || error}`;
    
    emit('add-console-log', consoleLog);
  } finally {
    isLoading.value = false;
    abortController = null; // 清理 AbortController
  }
};

const sendAndDownload = async () => {
  // 创建新的 AbortController
  abortController = new AbortController();
  
  isLoading.value = true;
  isResponseCollapsed.value = false;
  const startTime = Date.now();
  
  try {
    // 构建完整的 URL（包含查询参数）- 替换变量
    let url = replaceVariables(localRequest.value.url);
    const enabledParams = localRequest.value.params.filter(p => p.enabled && p.key);
    
    if (enabledParams.length > 0) {
      const queryString = enabledParams
        .map(p => {
          const key = replaceVariables(p.key);
          const value = replaceVariables(p.value);
          return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
        })
        .join('&');
      url += (url.includes('?') ? '&' : '?') + queryString;
    }

    // 构建请求头 - 替换变量
    const headers = {};
    localRequest.value.headers
      .filter(h => h.enabled && h.key)
      .forEach(h => {
        headers[replaceVariables(h.key)] = replaceVariables(h.value);
      });

    // 添加认证头 - 替换变量
    if (localRequest.value.auth.type === 'bearer' && localRequest.value.auth.token) {
      headers['Authorization'] = `Bearer ${replaceVariables(localRequest.value.auth.token)}`;
    } else if (localRequest.value.auth.type === 'basic' && localRequest.value.auth.username) {
      const username = replaceVariables(localRequest.value.auth.username);
      const password = replaceVariables(localRequest.value.auth.password);
      const credentials = btoa(`${username}:${password}`);
      headers['Authorization'] = `Basic ${credentials}`;
    }

    // 构建请求体 - 替换变量
    let body = null;
    if (['POST', 'PUT', 'PATCH'].includes(localRequest.value.method)) {
      if (localRequest.value.body.type === 'json' && localRequest.value.body.raw) {
        headers['Content-Type'] = 'application/json';
        body = replaceVariables(localRequest.value.body.raw);
      } else if (localRequest.value.body.type === 'x-www-form-urlencoded') {
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
        const enabledData = localRequest.value.body.urlencoded.filter(r => r.enabled && r.key);
        body = enabledData
          .map(r => `${encodeURIComponent(replaceVariables(r.key))}=${encodeURIComponent(replaceVariables(r.value))}`)
          .join('&');
      } else if (localRequest.value.body.type === 'form-data') {
        const formDataObj = {};
        localRequest.value.body.formData
          .filter(r => r.enabled && r.key && r.type === 'text')
          .forEach(r => {
            formDataObj[replaceVariables(r.key)] = replaceVariables(r.value);
          });
        headers['Content-Type'] = 'application/json';
        body = JSON.stringify(formDataObj);
      }
    }

    // 发送请求（添加 signal 支持取消）
    const fetchResponse = await fetch(url, {
      method: localRequest.value.method,
      headers,
      body,
      signal: abortController?.signal
    });

    const endTime = Date.now();
    const contentType = fetchResponse.headers.get('content-type') || '';
    
    // 获取响应数据
    const arrayBuffer = await fetchResponse.arrayBuffer();
    const blob = new Blob([arrayBuffer], { type: contentType });
    
    // 动态导入 Tauri 插件
    const { save } = await import('@tauri-apps/plugin-dialog');
    const { writeFile } = await import('@tauri-apps/plugin-fs');
    
    // 从 Content-Disposition 或 URL 中提取文件名
    let suggestedFileName = 'download';
    const contentDisposition = fetchResponse.headers.get('content-disposition');
    
    if (contentDisposition) {
      // 尝试多种 Content-Disposition 格式
      // 格式1: filename="example.pdf"
      // 格式2: filename=example.pdf
      // 格式3: filename*=UTF-8''example.pdf
      const fileNameMatch = contentDisposition.match(/filename\*?=['"]?(?:UTF-\d['"]*)?([^;\r\n"']*)['"]?/i);
      if (fileNameMatch && fileNameMatch[1]) {
        suggestedFileName = decodeURIComponent(fileNameMatch[1].trim());
      }
    }
    
    // 如果 Content-Disposition 没有提供文件名，从 URL 中提取
    if (suggestedFileName === 'download') {
      try {
        const urlObj = new URL(url);
        // 移除查询参数，只保留路径
        const urlPath = urlObj.pathname;
        const urlFileName = urlPath.substring(urlPath.lastIndexOf('/') + 1);
        
        // 如果 URL 路径有文件名（包含扩展名）
        if (urlFileName && urlFileName.includes('.')) {
          suggestedFileName = decodeURIComponent(urlFileName);
        } else if (urlFileName) {
          // 如果有路径但没有扩展名，根据 Content-Type 添加扩展名
          suggestedFileName = decodeURIComponent(urlFileName);
          const extension = getExtensionFromContentType(contentType);
          if (extension && !suggestedFileName.includes('.')) {
            suggestedFileName += extension;
          }
        } else {
          // URL 路径为空，使用 Content-Type 生成文件名
          const extension = getExtensionFromContentType(contentType);
          suggestedFileName = `download${extension}`;
        }
      } catch (e) {
        console.error('Error parsing URL:', e);
        // 使用 Content-Type 生成默认文件名
        const extension = getExtensionFromContentType(contentType);
        suggestedFileName = `download${extension}`;
      }
    }
    
    console.log('Suggested file name:', suggestedFileName);
    console.log('Content-Type:', contentType);
    console.log('Content-Disposition:', contentDisposition);
    
    // 打开保存对话框
    const filePath = await save({
      defaultPath: suggestedFileName,
      filters: []
    });
    
    if (filePath) {
      // 将 Blob 转换为 Uint8Array
      const uint8Array = new Uint8Array(arrayBuffer);
      
      // 写入文件
      await writeFile(filePath, uint8Array);
      
      // 显示成功消息
      if (window.$toast) {
        window.$toast.add({
          severity: 'success',
          summary: 'Download Complete',
          detail: `File saved to ${filePath}`,
          life: 3000
        });
      }
      
      // 更新响应显示
      const size = arrayBuffer.byteLength;
      const sizeStr = size < 1024 
        ? `${size}B` 
        : size < 1024 * 1024 
          ? `${(size / 1024).toFixed(2)}KB` 
          : `${(size / (1024 * 1024)).toFixed(2)}MB`;

      response.value = {
        status: fetchResponse.status,
        statusText: fetchResponse.statusText,
        time: `${endTime - startTime}ms`,
        size: sizeStr,
        body: `File downloaded successfully to:\n${filePath}`,
        rawBody: `File downloaded successfully to:\n${filePath}`,
        headers: Object.fromEntries(fetchResponse.headers.entries()),
        contentType: contentType,
        imageDataUrl: ''
      };
    } else {
      // 用户取消了保存
      if (window.$toast) {
        window.$toast.add({
          severity: 'info',
          summary: 'Download Cancelled',
          detail: 'File download was cancelled',
          life: 2000
        });
      }
    }
  } catch (error) {
    const endTime = Date.now();
    
    // 检查是否是用户取消的请求
    if (error.name === 'AbortError') {
      console.log('Download request was cancelled by user');
      return; // 用户取消，不显示错误
    }
    
    response.value = {
      status: 0,
      statusText: 'Error',
      time: `${endTime - startTime}ms`,
      size: '0B',
      body: `Error: ${error.message || error}`,
      rawBody: `Error: ${error.message || error}`,
      headers: {},
      contentType: '',
      imageDataUrl: ''
    };
    
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Download Failed',
        detail: error.message || 'Failed to download file',
        life: 3000
      });
    }
  } finally {
    isLoading.value = false;
    abortController = null; // 清理 AbortController
  }
};

const addParam = () => {
  localRequest.value.params.push({ key: '', value: '', enabled: true });
};

const removeParam = (index) => {
  if (localRequest.value.params.length > 1) {
    localRequest.value.params.splice(index, 1);
  }
};

const onParamChange = () => {
  // 如果最后一行有内容，自动添加新的空行
  const lastParam = localRequest.value.params[localRequest.value.params.length - 1];
  if (lastParam && (lastParam.key || lastParam.value)) {
    // 检查是否已经有空行
    const hasEmptyRow = localRequest.value.params.some(p => !p.key && !p.value);
    if (!hasEmptyRow) {
      addParam();
    }
  }
};

const addHeader = () => {
  localRequest.value.headers.push({ key: '', value: '', enabled: true });
};

const removeHeader = (index) => {
  if (localRequest.value.headers.length > 1) {
    localRequest.value.headers.splice(index, 1);
  }
};

const onHeaderChange = () => {
  // 如果最后一行有内容，自动添加新的空行
  const lastHeader = localRequest.value.headers[localRequest.value.headers.length - 1];
  if (lastHeader && (lastHeader.key || lastHeader.value)) {
    // 检查是否已经有空行
    const hasEmptyRow = localRequest.value.headers.some(h => !h.key && !h.value);
    if (!hasEmptyRow) {
      addHeader();
    }
  }
};

const addFormDataRow = () => {
  localRequest.value.body.formData.push({ key: '', value: '', type: 'text', enabled: true });
};

const removeFormDataRow = (index) => {
  if (localRequest.value.body.formData.length > 1) {
    localRequest.value.body.formData.splice(index, 1);
  }
};

const onFormDataChange = () => {
  const lastRow = localRequest.value.body.formData[localRequest.value.body.formData.length - 1];
  if (lastRow && (lastRow.key || lastRow.value)) {
    const hasEmptyRow = localRequest.value.body.formData.some(r => !r.key && !r.value);
    if (!hasEmptyRow) {
      addFormDataRow();
    }
  }
};

const addUrlencodedRow = () => {
  localRequest.value.body.urlencoded.push({ key: '', value: '', enabled: true });
};

const removeUrlencodedRow = (index) => {
  if (localRequest.value.body.urlencoded.length > 1) {
    localRequest.value.body.urlencoded.splice(index, 1);
  }
};

const onUrlencodedChange = () => {
  const lastRow = localRequest.value.body.urlencoded[localRequest.value.body.urlencoded.length - 1];
  if (lastRow && (lastRow.key || lastRow.value)) {
    const hasEmptyRow = localRequest.value.body.urlencoded.some(r => !r.key && !r.value);
    if (!hasEmptyRow) {
      addUrlencodedRow();
    }
  }
};

const handleFileSelect = (event, row) => {
  const file = event.target.files[0];
  if (file) {
    row.value = file.name;
    row.file = file;
  }
};

const beautifyJson = () => {
  try {
    const parsed = JSON.parse(localRequest.value.body.raw);
    localRequest.value.body.raw = JSON.stringify(parsed, null, 2);
  } catch (error) {
    console.error('Invalid JSON:', error);
    // 可以添加错误提示
  }
};

const copyRequestBody = async () => {
  try {
    await navigator.clipboard.writeText(localRequest.value.body.raw);
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Copied',
        detail: 'Request body copied to clipboard',
        life: 2000
      });
    }
  } catch (error) {
    console.error('Failed to copy:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to copy to clipboard',
        life: 3000
      });
    }
  }
};

const copyResponseBody = async () => {
  try {
    await navigator.clipboard.writeText(response.value.body);
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Copied',
        detail: 'Response body copied to clipboard',
        life: 2000
      });
    }
  } catch (error) {
    console.error('Failed to copy:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to copy to clipboard',
        life: 3000
      });
    }
  }
};

const copyRawResponseBody = async () => {
  try {
    await navigator.clipboard.writeText(response.value.rawBody);
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Copied',
        detail: 'Raw response copied to clipboard',
        life: 2000
      });
    }
  } catch (error) {
    console.error('Failed to copy:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to copy to clipboard',
        life: 3000
      });
    }
  }
};

// 搜索相关
const showSearchBox = ref(false);
const searchQuery = ref('');
const searchCaseSensitive = ref(false);
const searchRegex = ref(false);
const searchMatches = ref([]);
const currentMatchIndex = ref(-1);

const toggleSearchBox = () => {
  showSearchBox.value = !showSearchBox.value;
  if (showSearchBox.value) {
    // 打开搜索框时，聚焦输入框
    setTimeout(() => {
      const searchInput = document.querySelector('.response-search-input');
      if (searchInput) searchInput.focus();
    }, 100);
  } else {
    // 关闭搜索框时，清除搜索
    clearSearch();
  }
};

const performSearch = () => {
  if (!response.value || !searchQuery.value) {
    searchMatches.value = [];
    currentMatchIndex.value = -1;
    return;
  }

  // 根据当前视图选择搜索内容
  const content = activeBodyViewTab.value === 0 ? response.value.body : response.value.rawBody;
  searchMatches.value = [];
  
  try {
    if (searchRegex.value) {
      // 正则表达式搜索
      const flags = searchCaseSensitive.value ? 'g' : 'gi';
      const regex = new RegExp(searchQuery.value, flags);
      let match;
      while ((match = regex.exec(content)) !== null) {
        searchMatches.value.push({
          index: match.index,
          length: match[0].length,
          text: match[0]
        });
      }
    } else {
      // 普通文本搜索
      const searchText = searchCaseSensitive.value ? searchQuery.value : searchQuery.value.toLowerCase();
      const contentToSearch = searchCaseSensitive.value ? content : content.toLowerCase();
      
      let startIndex = 0;
      while (true) {
        const index = contentToSearch.indexOf(searchText, startIndex);
        if (index === -1) break;
        
        searchMatches.value.push({
          index: index,
          length: searchQuery.value.length,
          text: content.substr(index, searchQuery.value.length)
        });
        
        startIndex = index + 1;
      }
    }
    
    if (searchMatches.value.length > 0) {
      currentMatchIndex.value = 0;
      scrollToMatch(0);
    } else {
      currentMatchIndex.value = -1;
    }
  } catch (error) {
    console.error('Search error:', error);
    searchMatches.value = [];
    currentMatchIndex.value = -1;
  }
};

const clearSearch = () => {
  searchQuery.value = '';
  searchMatches.value = [];
  currentMatchIndex.value = -1;
};

const nextMatch = () => {
  if (searchMatches.value.length === 0) return;
  currentMatchIndex.value = (currentMatchIndex.value + 1) % searchMatches.value.length;
  scrollToMatch(currentMatchIndex.value);
};

const prevMatch = () => {
  if (searchMatches.value.length === 0) return;
  currentMatchIndex.value = currentMatchIndex.value <= 0 
    ? searchMatches.value.length - 1 
    : currentMatchIndex.value - 1;
  scrollToMatch(currentMatchIndex.value);
};

const scrollToMatch = (index) => {
  // 这个函数会在下一个 tick 中执行，确保 DOM 已更新
  setTimeout(() => {
    const matchElement = document.querySelector(`.search-match-${index}`);
    if (matchElement) {
      matchElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, 100);
};

const highlightedResponseBody = computed(() => {
  if (!response.value || searchMatches.value.length === 0) {
    return activeBodyViewTab.value === 0 ? response.value?.body : response.value?.rawBody;
  }

  const content = activeBodyViewTab.value === 0 ? response.value.body : response.value.rawBody;
  let result = '';
  let lastIndex = 0;

  searchMatches.value.forEach((match, idx) => {
    // 添加匹配前的文本
    result += escapeHtml(content.substring(lastIndex, match.index));
    
    // 添加高亮的匹配文本
    const isCurrentMatch = idx === currentMatchIndex.value;
    const highlightClass = isCurrentMatch 
      ? 'bg-orange-400 dark:bg-orange-600 text-white search-match-' + idx
      : 'bg-yellow-200 dark:bg-yellow-700 search-match-' + idx;
    result += `<span class="${highlightClass}">${escapeHtml(match.text)}</span>`;
    
    lastIndex = match.index + match.length;
  });

  // 添加剩余的文本
  result += escapeHtml(content.substring(lastIndex));

  return result;
});

const escapeHtml = (text) => {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
};

// 监听搜索参数变化
watch([searchQuery, searchCaseSensitive, searchRegex], () => {
  if (searchQuery.value) {
    performSearch();
  } else {
    clearSearch();
  }
});

// 监听 activeBodyViewTab 变化，重新搜索
watch(activeBodyViewTab, () => {
  if (searchQuery.value) {
    performSearch();
  }
});

const startResize = (event) => {
  isResizing.value = true;
  const startY = event.clientY;
  const startHeight = responseHeight.value;

  const onMouseMove = (e) => {
    const deltaY = startY - e.clientY;
    const newHeight = Math.max(200, Math.min(600, startHeight + deltaY));
    responseHeight.value = newHeight;
  };

  const onMouseUp = () => {
    isResizing.value = false;
    document.removeEventListener('mousemove', onMouseMove);
    document.removeEventListener('mouseup', onMouseUp);
  };

  document.addEventListener('mousemove', onMouseMove);
  document.addEventListener('mouseup', onMouseUp);
};

const toggleResponseCollapse = () => {
  isResponseCollapsed.value = !isResponseCollapsed.value;
};

const isJsonResponse = computed(() => {
  if (!response.value) return false;
  try {
    JSON.parse(response.value.rawBody);
    return true;
  } catch {
    return false;
  }
});

const isImageResponse = computed(() => {
  if (!response.value) return false;
  const contentType = response.value.contentType.toLowerCase();
  return contentType.includes('image/');
});

const responseLanguage = computed(() => {
  if (!response.value) return 'text';
  const contentType = response.value.contentType.toLowerCase();
  
  if (contentType.includes('json')) return 'json';
  if (contentType.includes('xml')) return 'xml';
  if (contentType.includes('html')) return 'html';
  
  // 尝试从内容判断
  const body = response.value.rawBody.trim();
  if (body.startsWith('<?xml') || body.startsWith('<') && body.includes('</')) {
    if (body.toLowerCase().includes('<!doctype html') || body.toLowerCase().includes('<html')) {
      return 'html';
    }
    return 'xml';
  }
  
  return 'text';
});

const shouldUseCodeEditor = computed(() => {
  return ['json', 'xml', 'html'].includes(responseLanguage.value);
});

// 测试结果统计
const testResultsSummary = computed(() => {
  if (!testResults.value) return null;
  
  const statusTests = testResults.value.statusCode || [];
  const jsonTests = testResults.value.jsonFields || [];
  const globalVars = testResults.value.globalVars || [];
  
  const totalTests = statusTests.length + jsonTests.length;
  const passedTests = statusTests.filter(t => t.passed).length + jsonTests.filter(t => t.passed).length;
  const failedTests = totalTests - passedTests;
  
  return {
    total: totalTests,
    passed: passedTests,
    failed: failedTests,
    globalVarsSet: globalVars.length,
    hasTests: totalTests > 0
  };
});

// 获取操作符的显示文本
const getOperatorLabel = (operatorValue) => {
  const operator = operatorOptions.find(op => op.value === operatorValue);
  return operator ? operator.label : operatorValue;
};

// cURL 生成和导入相关
const curlInput = ref('');
const activeCodeTab = ref(0); // 0: Export, 1: Import

// 保存相关
const showSaveDialog = ref(false);
const saveRequestName = ref('');
const selectedCollection = ref(null);
const selectedFolder = ref(null);
const collections = ref([]); // 从父组件获取的collections数据
const selectedKeys = ref({}); // Tree组件的选中状态

// 检查请求名称是否在同一目录下重复
const isRequestNameDuplicate = (collectionId, folderId, requestName, excludeRequestId = null) => {
  const collection = props.collections.find(c => c.id === collectionId);
  if (!collection) return false;
  
  // 获取目标目录下的所有请求
  let requests = [];
  if (folderId) {
    // 在指定 folder 中查找
    const findFolder = (folders, targetId) => {
      for (const folder of folders) {
        if (folder.id === targetId) return folder;
        if (folder.folders && folder.folders.length > 0) {
          const found = findFolder(folder.folders, targetId);
          if (found) return found;
        }
      }
      return null;
    };
    const folder = findFolder(collection.folders || [], folderId);
    requests = folder?.requests || [];
  } else {
    // 在 collection 根目录下查找
    requests = collection.requests || [];
  }
  
  // 检查是否有同名请求（排除当前请求自己）
  return requests.some(req => 
    req.name.toLowerCase() === requestName.toLowerCase() && 
    req.id !== excludeRequestId
  );
};

const generateCurl = () => {
  let curl = `curl -X ${localRequest.value.method}`;
  
  // 构建完整的 URL（包含查询参数）
  let url = localRequest.value.url;
  const enabledParams = localRequest.value.params.filter(p => p.enabled && p.key);
  if (enabledParams.length > 0) {
    const queryString = enabledParams
      .map(p => `${encodeURIComponent(p.key)}=${encodeURIComponent(p.value)}`)
      .join('&');
    url += (url.includes('?') ? '&' : '?') + queryString;
  }
  
  curl += ` '${url}'`;
  
  // 添加请求头
  const headers = {};
  localRequest.value.headers
    .filter(h => h.enabled && h.key)
    .forEach(h => {
      headers[h.key] = h.value;
    });
  
  // 添加认证头
  if (localRequest.value.auth.type === 'bearer' && localRequest.value.auth.token) {
    headers['Authorization'] = `Bearer ${localRequest.value.auth.token}`;
  } else if (localRequest.value.auth.type === 'basic' && localRequest.value.auth.username) {
    const credentials = btoa(`${localRequest.value.auth.username}:${localRequest.value.auth.password}`);
    headers['Authorization'] = `Basic ${credentials}`;
  }
  
  // 添加所有 headers
  Object.entries(headers).forEach(([key, value]) => {
    curl += ` \\\n  -H '${key}: ${value}'`;
  });
  
  // 添加请求体
  if (['POST', 'PUT', 'PATCH'].includes(localRequest.value.method)) {
    if (localRequest.value.body.type === 'json' && localRequest.value.body.raw) {
      curl += ` \\\n  -H 'Content-Type: application/json'`;
      const escapedBody = localRequest.value.body.raw.replace(/'/g, "'\\''");
      curl += ` \\\n  -d '${escapedBody}'`;
    } else if (localRequest.value.body.type === 'x-www-form-urlencoded') {
      curl += ` \\\n  -H 'Content-Type: application/x-www-form-urlencoded'`;
      const enabledData = localRequest.value.body.urlencoded.filter(r => r.enabled && r.key);
      const body = enabledData
        .map(r => `${encodeURIComponent(r.key)}=${encodeURIComponent(r.value)}`)
        .join('&');
      curl += ` \\\n  -d '${body}'`;
    } else if (localRequest.value.body.type === 'form-data') {
      const enabledData = localRequest.value.body.formData.filter(r => r.enabled && r.key);
      enabledData.forEach(r => {
        if (r.type === 'text') {
          curl += ` \\\n  -F '${r.key}=${r.value}'`;
        } else if (r.type === 'file' && r.file) {
          curl += ` \\\n  -F '${r.key}=@${r.value}'`;
        }
      });
    }
  }
  
  return curl;
};

const copyCurl = async () => {
  try {
    await navigator.clipboard.writeText(generateCurl());
    // 显示成功提示
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Copied',
        detail: 'cURL command copied to clipboard',
        life: 2000
      });
    }
  } catch (error) {
    console.error('Failed to copy:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to copy to clipboard',
        life: 3000
      });
    }
  }
};

const parseCurl = (curlCommand) => {
  try {
    // 清理命令：移除换行符和多余空格
    let cmd = curlCommand.replace(/\\\n/g, ' ').replace(/\s+/g, ' ').trim();
    
    // 移除开头的 curl
    cmd = cmd.replace(/^curl\s+/i, '');
    
    // 提取 method
    let method = 'GET';
    const methodMatch = cmd.match(/-X\s+([A-Z]+)/i);
    if (methodMatch) {
      method = methodMatch[1].toUpperCase();
      cmd = cmd.replace(/-X\s+[A-Z]+/i, '');
    }
    
    // 提取 URL
    let url = '';
    const urlMatch = cmd.match(/['"]([^'"]+)['"]/);
    if (urlMatch) {
      url = urlMatch[1];
      cmd = cmd.replace(/['"]([^'"]+)['"]/, '');
    } else {
      // 尝试匹配不带引号的 URL
      const simpleUrlMatch = cmd.match(/https?:\/\/[^\s]+/);
      if (simpleUrlMatch) {
        url = simpleUrlMatch[0];
        cmd = cmd.replace(simpleUrlMatch[0], '');
      }
    }
    
    // 提取 headers
    const headers = [];
    const headerRegex = /-H\s+['"]([^:]+):\s*([^'"]+)['"]/g;
    let headerMatch;
    while ((headerMatch = headerRegex.exec(cmd)) !== null) {
      headers.push({ key: headerMatch[1].trim(), value: headerMatch[2].trim(), enabled: true });
    }
    
    // 提取 body
    let body = null;
    let bodyType = 'none';
    const dataMatch = cmd.match(/-d\s+['"](.+?)['"]/);
    const formMatch = cmd.match(/-F\s+['"](.+?)['"]/g);
    
    if (dataMatch) {
      const bodyContent = dataMatch[1];
      // 检查是否是 JSON
      try {
        JSON.parse(bodyContent);
        bodyType = 'json';
        body = bodyContent;
      } catch {
        // 可能是 form-urlencoded
        if (bodyContent.includes('=') && bodyContent.includes('&')) {
          bodyType = 'x-www-form-urlencoded';
          body = bodyContent;
        } else {
          bodyType = 'json';
          body = bodyContent;
        }
      }
    } else if (formMatch) {
      bodyType = 'form-data';
      body = formMatch.map(f => {
        const match = f.match(/-F\s+['"]([^=]+)=(.+?)['"]/);
        if (match) {
          return { key: match[1], value: match[2], type: 'text', enabled: true };
        }
        return null;
      }).filter(Boolean);
    }
    
    // 清空所有现有数据并更新 localRequest
    localRequest.value.method = method;
    localRequest.value.url = url;
    
    // 清空并重置 params
    localRequest.value.params = [{ key: '', value: '', enabled: true }];
    
    // 清空并重置 headers
    if (headers.length > 0) {
      localRequest.value.headers = [...headers, { key: '', value: '', enabled: true }];
    } else {
      localRequest.value.headers = [{ key: '', value: '', enabled: true }];
    }
    
    // 清空并重置 auth
    localRequest.value.auth = {
      type: 'none',
      token: '',
      username: '',
      password: ''
    };
    
    // 清空并重置 body
    if (bodyType === 'json') {
      localRequest.value.body = {
        type: 'json',
        raw: body,
        formData: [{ key: '', value: '', type: 'text', enabled: true }],
        urlencoded: [{ key: '', value: '', enabled: true }]
      };
    } else if (bodyType === 'x-www-form-urlencoded') {
      const pairs = body.split('&');
      const urlencoded = pairs.map(pair => {
        const [key, value] = pair.split('=');
        return {
          key: decodeURIComponent(key || ''),
          value: decodeURIComponent(value || ''),
          enabled: true
        };
      });
      urlencoded.push({ key: '', value: '', enabled: true });
      
      localRequest.value.body = {
        type: 'x-www-form-urlencoded',
        raw: '',
        formData: [{ key: '', value: '', type: 'text', enabled: true }],
        urlencoded: urlencoded
      };
    } else if (bodyType === 'form-data') {
      localRequest.value.body = {
        type: 'form-data',
        raw: '',
        formData: [...body, { key: '', value: '', type: 'text', enabled: true }],
        urlencoded: [{ key: '', value: '', enabled: true }]
      };
    } else {
      localRequest.value.body = {
        type: 'none',
        raw: '',
        formData: [{ key: '', value: '', type: 'text', enabled: true }],
        urlencoded: [{ key: '', value: '', enabled: true }]
      };
    }
    
    // 清空 tests
    localRequest.value.tests = '';
    
    // 清空输入框并切换到 Params 标签页
    curlInput.value = '';
    activeParamTab.value = 0; // 切换到 Params tab
    
    // 显示成功提示
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Imported',
        detail: 'cURL command imported successfully',
        life: 2000
      });
    }
  } catch (error) {
    console.error('Failed to parse cURL:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to parse cURL command. Please check the format.',
        life: 3000
      });
    }
  }
};

const importCurl = () => {
  if (curlInput.value.trim()) {
    parseCurl(curlInput.value);
  }
};

// 保存相关方法
const handleSaveClick = () => {
  // 如果请求还没有分配 collection，显示对话框让用户选择
  if (!localRequest.value.collectionId) {
    openSaveDialog();
  } else {
    // 已经有 collection，直接保存
    saveRequestDirectly();
  }
};

const openSaveDialog = () => {
  saveRequestName.value = localRequest.value.name;
  selectedCollection.value = null;
  selectedFolder.value = null;
  selectedKeys.value = {};
  showSaveDialog.value = true;
};

const saveRequestDirectly = () => {
  // 直接保存到已有的 collection/folder
  const collection = props.collections.find(c => c.id === localRequest.value.collectionId);
  
  if (!collection) {
    console.error('Collection not found:', localRequest.value.collectionId);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Collection not found',
        life: 3000
      });
    }
    return;
  }
  
  // 查找 folder（如果有）
  let folder = null;
  if (localRequest.value.folderId) {
    const findFolder = (folders, folderId) => {
      for (const f of folders) {
        if (f.id === folderId) return f;
        if (f.folders && f.folders.length > 0) {
          const found = findFolder(f.folders, folderId);
          if (found) return found;
        }
      }
      return null;
    };
    folder = findFolder(collection.folders || [], localRequest.value.folderId);
  }
  
  const requestToSave = {
    id: localRequest.value.id,
    name: localRequest.value.name,
    method: localRequest.value.method,
    url: localRequest.value.url,
    params: localRequest.value.params.filter(p => p.key || p.value),
    headers: localRequest.value.headers.filter(h => h.key || h.value),
    body: { ...localRequest.value.body },
    auth: { ...localRequest.value.auth },
    tests: localRequest.value.tests,
    collectionId: localRequest.value.collectionId,
    folderId: localRequest.value.folderId,
    createdAt: localRequest.value.createdAt,
    updatedAt: new Date().toISOString()
  };

  const saveData = {
    request: requestToSave,
    collection: collection,
    folder: folder
  };

  // 发出保存事件（不移动位置，只更新内容）
  emit('save-request', saveData);

  // 显示成功提示
  if (window.$toast) {
    window.$toast.add({
      severity: 'success',
      summary: 'Saved',
      detail: `Request "${localRequest.value.name}" saved successfully`,
      life: 2000
    });
  }
};

const saveRequest = () => {
  if (!saveRequestName.value.trim() || !selectedCollection.value) {
    return;
  }

  // 检查名称是否重复
  const targetFolderId = selectedFolder.value?.id || null;
  if (isRequestNameDuplicate(selectedCollection.value.id, targetFolderId, saveRequestName.value.trim(), localRequest.value.id)) {
    if (window.$toast) {
      window.$toast.add({
        severity: 'warn',
        summary: 'Duplicate Name',
        detail: 'A request with this name already exists in the same location',
        life: 3000
      });
    }
    return;
  }

  const requestToSave = {
    id: localRequest.value.id || Date.now(),
    name: saveRequestName.value.trim(),
    method: localRequest.value.method,
    url: localRequest.value.url,
    params: localRequest.value.params.filter(p => p.key || p.value),
    headers: localRequest.value.headers.filter(h => h.key || h.value),
    body: { ...localRequest.value.body },
    auth: { ...localRequest.value.auth },
    tests: localRequest.value.tests,
    collectionId: localRequest.value.collectionId,  // 保留旧位置信息
    folderId: localRequest.value.folderId,          // 保留旧位置信息
    createdAt: localRequest.value.createdAt,
    updatedAt: new Date().toISOString()
  };

  const saveData = {
    request: requestToSave,
    collection: selectedCollection.value,
    folder: selectedFolder.value
  };

  // 更新本地请求状态
  localRequest.value.name = saveRequestName.value.trim();
  localRequest.value.saved = true;
  localRequest.value.id = requestToSave.id;
  // 更新 collectionId 和 folderId
  localRequest.value.collectionId = selectedCollection.value.id;
  localRequest.value.folderId = selectedFolder.value?.id || null;

  // 发出保存事件
  emit('save-request', saveData);

  // 关闭对话框
  showSaveDialog.value = false;

  // 显示成功提示
  if (window.$toast) {
    window.$toast.add({
      severity: 'success',
      summary: 'Saved',
      detail: `Request "${saveRequestName.value}" saved successfully`,
      life: 2000
    });
  }
};

// 构建树形结构用于选择保存位置
const treeData = computed(() => {
  const buildTreeNode = (item, type = 'collection', parentKey = '') => {
    // 使用 '/' 作为分隔符，因为 ID 中可能包含 '-'
    const key = parentKey ? `${parentKey}/${item.id}` : `${type}/${item.id}`;
    
    const node = {
      key,
      label: item.name,
      data: { ...item, type },
      icon: type === 'collection' ? 'pi pi-folder' : 'pi pi-folder-open',
      children: []
    };
    
    // 递归处理子文件夹
    if (item.folders && item.folders.length > 0) {
      node.children = item.folders.map(folder => 
        buildTreeNode(folder, 'folder', key)
      );
    }
    
    return node;
  };

  return props.collections.map(collection => buildTreeNode(collection));
});

const onNodeSelect = (node) => {
  console.log('[onNodeSelect] Node selected:', node);
  console.log('[onNodeSelect] Node key:', node.key);
  console.log('[onNodeSelect] Node data:', node.data);
  
  const nodeData = node.data;
  
  if (nodeData.type === 'collection') {
    selectedCollection.value = nodeData;
    selectedFolder.value = null;
    console.log('[onNodeSelect] Collection selected:', nodeData.name);
  } else if (nodeData.type === 'folder') {
    // 使用 '/' 分割 key
    const parts = node.key.split('/');
    console.log('[onNodeSelect] Key parts:', parts);
    
    // parts[0] = 'collection'
    // parts[1] = collection ID
    // parts[2+] = folder IDs (可能有多层)
    
    const collectionId = parts[1];
    const parentCollection = props.collections.find(c => String(c.id) === collectionId);
    
    if (!parentCollection) {
      console.log('[onNodeSelect] Parent collection not found for ID:', collectionId);
      return;
    }
    
    console.log('[onNodeSelect] Found parent collection:', parentCollection.name);
    
    // 递归查找文件夹对象
    const findFolderByPath = (folders, pathParts, startIndex) => {
      if (startIndex >= pathParts.length) {
        return null;
      }
      
      const currentFolderId = pathParts[startIndex];
      console.log('[findFolderByPath] Looking for folder ID:', currentFolderId, 'in', folders.length, 'folders');
      
      const folder = folders.find(f => {
        console.log('[findFolderByPath] Comparing:', String(f.id), '===', currentFolderId);
        return String(f.id) === currentFolderId;
      });
      
      if (!folder) {
        console.log('[findFolderByPath] Folder not found at index', startIndex);
        return null;
      }
      
      console.log('[findFolderByPath] Found folder:', folder.name);
      
      // 如果这是最后一个 ID，返回这个 folder
      if (startIndex === pathParts.length - 1) {
        console.log('[findFolderByPath] This is the target folder');
        return folder;
      }
      
      // 否则继续在子文件夹中查找
      if (folder.folders && folder.folders.length > 0) {
        console.log('[findFolderByPath] Searching in subfolders');
        return findFolderByPath(folder.folders, pathParts, startIndex + 1);
      }
      
      console.log('[findFolderByPath] No subfolders to search');
      return null;
    };
    
    // 从 parts[2] 开始是 folder IDs
    const folderPath = parts.slice(2);
    console.log('[onNodeSelect] Folder path:', folderPath);
    
    const folder = findFolderByPath(parentCollection.folders || [], folderPath, 0);
    
    if (folder) {
      selectedCollection.value = parentCollection;
      selectedFolder.value = folder;
      console.log('[onNodeSelect] Folder selected:', folder.name, 'in collection:', parentCollection.name);
    } else {
      console.log('[onNodeSelect] Folder not found in collection');
    }
  }
  
  // 更新选中状态
  selectedKeys.value = { [node.key]: true };
};

// 构建选中位置的完整路径显示
const selectedPath = computed(() => {
  if (!selectedCollection.value) {
    return '';
  }
  
  const parts = [selectedCollection.value.name];
  
  if (selectedFolder.value) {
    // 需要找到从 collection 到 selectedFolder 的完整路径
    const findPath = (folders, targetId, currentPath = []) => {
      for (const folder of folders) {
        const newPath = [...currentPath, folder.name];
        
        if (String(folder.id) === String(targetId)) {
          return newPath;
        }
        
        if (folder.folders && folder.folders.length > 0) {
          const found = findPath(folder.folders, targetId, newPath);
          if (found) {
            return found;
          }
        }
      }
      return null;
    };
    
    const folderPath = findPath(selectedCollection.value.folders || [], selectedFolder.value.id);
    if (folderPath) {
      parts.push(...folderPath);
    }
  }
  
  return parts.join(' / ');
});

// Keyboard shortcut handler for Ctrl+S
const handleKeyDown = (event) => {
  // Check for Ctrl+S (or Cmd+S on Mac)
  if ((event.ctrlKey || event.metaKey) && event.key === 's') {
    event.preventDefault(); // Prevent browser's default save dialog
    handleSaveClick();
  }
};

// Add keyboard event listener on mount
onMounted(() => {
  window.addEventListener('keydown', handleKeyDown);
});

// Remove keyboard event listener on unmount
onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown);
});

// 暴露方法供父组件调用
defineExpose({
  openSaveDialog
});
</script>

<template>
  <div class="http-request flex flex-col h-full">
    <!-- Title Bar -->
    <div class="flex items-center px-4 py-3 border-b border-surface-200 dark:border-surface-700">
      <div class="flex items-center gap-2 flex-1">
        <InputText 
          v-model="localRequest.name"
          class="text-sm font-medium border-0 p-0 focus:ring-0 flex-1"
          placeholder="Request Name"
        />
        <span v-if="!localRequest.collectionId" class="text-xs text-surface-400">(未保存)</span>
      </div>
    </div>

    <!-- Request Section -->
    <div class="flex-1 flex flex-col overflow-hidden">
      <!-- Method + URL -->
      <div class="p-4 py-3 border-b border-surface-200 dark:border-surface-700">
        <div class="flex gap-2">
          <Dropdown 
            v-model="localRequest.method"
            :options="methods"
            class="w-32"
          />
          <VariableInput 
            v-model="localRequest.url"
            placeholder="Enter request URL"
            class="flex-1"
            :availableVariables="availableVariables"
          />
          <SplitButton 
            label="Send"
            :loading="isLoading"
            :model="sendMenuItems"
            @click="sendRequest"
          />
          <Button 
            label="Save"
            icon="pi pi-save"
            severity="secondary"
            @click="handleSaveClick"
          />
        </div>
      </div>

      <!-- Params Tabs -->
      <div class="flex-1 flex flex-col overflow-hidden">
        <TabView v-model:activeIndex="activeParamTab" class="request-tabs">
          <template #end>
            <Button 
              icon="pi pi-code"
              text
              rounded
              size="small"
              class="mr-2"
              @click="activeParamTab = 5"
              title="Code"
            />
          </template>
          
          <TabPanel header="Params">
            <div class="p-4">
              <div class="mb-3">
                <h4 class="text-sm font-medium text-surface-700 dark:text-surface-300 mb-2">Query Params</h4>
              </div>
              
              <!-- Table Header -->
              <div class="flex gap-2 mb-2 text-sm font-bold text-surface-700 dark:text-surface-300 px-2">
                <div style="width: 40px;"></div>
                <div class="flex-1">KEY</div>
                <div class="flex-1">VALUE</div>
                <div style="width: 40px;"></div>
              </div>
              
              <!-- Table Rows -->
              <div class="space-y-1">
                <div 
                  v-for="(param, index) in localRequest.params"
                  :key="index"
                  class="flex gap-2 items-center"
                >
                  <div class="flex justify-center" style="width: 40px;">
                    <Checkbox v-model="param.enabled" :binary="true" />
                  </div>
                  <div class="flex-1">
                    <VariableInput 
                      v-model="param.key"
                      placeholder="Key"
                      size="small"
                      :availableVariables="availableVariables"
                      @input="onParamChange"
                    />
                  </div>
                  <div class="flex-1">
                    <VariableInput 
                      v-model="param.value"
                      placeholder="Value"
                      size="small"
                      :availableVariables="availableVariables"
                      @input="onParamChange"
                    />
                  </div>
                  <div class="flex justify-center" style="width: 40px;">
                    <Button 
                      v-if="localRequest.params.length > 1 || param.key || param.value"
                      icon="pi pi-trash"
                      text
                      rounded
                      size="small"
                      severity="danger"
                      @click="removeParam(index)"
                    />
                  </div>
                </div>
              </div>
            </div>
          </TabPanel>

          <TabPanel header="Authorization">
            <div class="p-4">
              <div class="mb-4">
                <label class="block text-sm font-medium mb-2">Type</label>
                <Dropdown 
                  v-model="localRequest.auth.type"
                  :options="authTypes"
                  optionLabel="label"
                  optionValue="value"
                  class="w-full"
                />
              </div>
              
              <!-- Bearer Token -->
              <div v-if="localRequest.auth.type === 'bearer'" class="space-y-4">
                <div>
                  <label class="block text-sm font-medium mb-2">Token</label>
                  <VariableInput 
                    v-model="localRequest.auth.token"
                    placeholder="Enter bearer token"
                    :availableVariables="availableVariables"
                  />
                </div>
              </div>
              
              <!-- Basic Auth -->
              <div v-if="localRequest.auth.type === 'basic'" class="space-y-4">
                <div>
                  <label class="block text-sm font-medium mb-2">Username</label>
                  <VariableInput 
                    v-model="localRequest.auth.username"
                    placeholder="Enter username"
                    :availableVariables="availableVariables"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium mb-2">Password</label>
                  <Password 
                    v-model="localRequest.auth.password"
                    placeholder="Enter password"
                    :feedback="false"
                    toggleMask
                    inputClass="w-full"
                    class="w-full password-full-width"
                  />
                </div>
              </div>
              
              <!-- No Auth -->
              <div v-if="localRequest.auth.type === 'none'" class="text-sm text-surface-500 dark:text-surface-400">
                This request does not use any authorization.
              </div>
            </div>
          </TabPanel>

          <TabPanel header="Headers">
            <div class="p-4">
              <div class="mb-3">
                <h4 class="text-sm font-medium text-surface-700 dark:text-surface-300 mb-2">Headers</h4>
              </div>
              
              <!-- Table Header -->
              <div class="flex gap-2 mb-2 text-sm font-bold text-surface-700 dark:text-surface-300 px-2">
                <div style="width: 40px;"></div>
                <div class="flex-1">KEY</div>
                <div class="flex-1">VALUE</div>
                <div style="width: 40px;"></div>
              </div>
              
              <!-- Table Rows -->
              <div class="space-y-1">
                <div 
                  v-for="(header, index) in localRequest.headers"
                  :key="index"
                  class="flex gap-2 items-center"
                >
                  <div class="flex justify-center" style="width: 40px;">
                    <Checkbox v-model="header.enabled" :binary="true" />
                  </div>
                  <div class="flex-1 relative">
                    <VariableInput 
                      v-model="header.key"
                      placeholder="Key"
                      size="small"
                      :availableVariables="availableVariables"
                      @input="(e) => { onHeaderChange(); filterHeaderKeys(e, index); }"
                      @focus="(e) => filterHeaderKeys(e, index)"
                      @blur="hideHeaderSuggestions"
                    />
                    <!-- Key Autocomplete Dropdown -->
                    <div 
                      v-if="filteredHeaderKeys.length > 0 && activeHeaderKeyIndex === index"
                      class="absolute z-50 w-full mt-1 bg-surface-0 dark:bg-surface-900 border border-surface-300 dark:border-surface-700 rounded shadow-lg max-h-48 overflow-y-auto"
                    >
                      <div 
                        v-for="suggestion in filteredHeaderKeys"
                        :key="suggestion"
                        @mousedown="selectHeaderKey(suggestion, index)"
                        class="px-3 py-2 text-sm cursor-pointer hover:bg-surface-100 dark:hover:bg-surface-800 text-surface-900 dark:text-surface-50"
                      >
                        {{ suggestion }}
                      </div>
                    </div>
                  </div>
                  <div class="flex-1 relative">
                    <VariableInput 
                      v-model="header.value"
                      placeholder="Value"
                      size="small"
                      :availableVariables="availableVariables"
                      @input="(e) => { onHeaderChange(); filterHeaderValues(e, index); }"
                      @focus="(e) => filterHeaderValues(e, index)"
                      @blur="hideHeaderSuggestions"
                    />
                    <!-- Value Autocomplete Dropdown -->
                    <div 
                      v-if="filteredHeaderValues.length > 0 && activeHeaderValueIndex === index"
                      class="absolute z-50 w-full mt-1 bg-surface-0 dark:bg-surface-900 border border-surface-300 dark:border-surface-700 rounded shadow-lg max-h-48 overflow-y-auto"
                    >
                      <div 
                        v-for="suggestion in filteredHeaderValues"
                        :key="suggestion"
                        @mousedown="selectHeaderValue(suggestion, index)"
                        class="px-3 py-2 text-sm cursor-pointer hover:bg-surface-100 dark:hover:bg-surface-800 text-surface-900 dark:text-surface-50"
                      >
                        {{ suggestion }}
                      </div>
                    </div>
                  </div>
                  <div class="flex justify-center" style="width: 40px;">
                    <Button 
                      v-if="localRequest.headers.length > 1 || header.key || header.value"
                      icon="pi pi-trash"
                      text
                      rounded
                      size="small"
                      severity="danger"
                      @click="removeHeader(index)"
                    />
                  </div>
                </div>
              </div>
            </div>
          </TabPanel>

          <TabPanel header="Body">
            <div class="p-4">
              <div class="mb-4 flex justify-between items-center">
                <div class="flex gap-4">
                  <div 
                    v-for="type in bodyTypes" 
                    :key="type.value"
                    class="flex items-center"
                  >
                    <RadioButton 
                      v-model="localRequest.body.type" 
                      :inputId="type.value" 
                      :value="type.value" 
                    />
                    <label :for="type.value" class="ml-2 text-sm cursor-pointer">
                      {{ type.label }}
                    </label>
                  </div>
                </div>
                <div v-if="localRequest.body.type === 'json'" class="flex gap-2">
                  <Button 
                    icon="pi pi-copy"
                    size="small"
                    text
                    title="Copy JSON"
                    @click="copyRequestBody"
                  />
                  <Button 
                    label="Beautify"
                    size="small"
                    text
                    class="beautify-btn"
                    @click="beautifyJson"
                  />
                </div>
              </div>

              <!-- None -->
              <div v-if="localRequest.body.type === 'none'" class="text-sm text-surface-500 dark:text-surface-400">
                This request does not have a body.
              </div>

              <!-- Form Data -->
              <div v-else-if="localRequest.body.type === 'form-data'">
                <!-- Table Header -->
                <div class="grid grid-cols-12 gap-2 mb-2 text-sm font-bold text-surface-700 dark:text-surface-300 px-2">
                  <div class="col-span-1"></div>
                  <div class="col-span-4">KEY</div>
                  <div class="col-span-6">VALUE</div>
                  <div class="col-span-1"></div>
                </div>
                
                <!-- Table Rows -->
                <div class="space-y-1">
                  <div 
                    v-for="(row, index) in localRequest.body.formData"
                    :key="index"
                    class="grid grid-cols-12 gap-2 items-center"
                  >
                    <div class="col-span-1 flex justify-center">
                      <Checkbox v-model="row.enabled" :binary="true" />
                    </div>
                    <div class="col-span-4">
                      <div class="flex gap-1">
                        <VariableInput 
                          v-model="row.key"
                          placeholder="Key"
                          size="small"
                          :availableVariables="availableVariables"
                          @input="onFormDataChange"
                        />
                        <Dropdown 
                          v-model="row.type"
                          :options="[{label: 'Text', value: 'text'}, {label: 'File', value: 'file'}]"
                          optionLabel="label"
                          optionValue="value"
                          class="w-20"
                          size="small"
                        />
                      </div>
                    </div>
                    <div class="col-span-6">
                      <VariableInput 
                        v-if="row.type === 'text'"
                        v-model="row.value"
                        placeholder="Value"
                        size="small"
                        :availableVariables="availableVariables"
                        @input="onFormDataChange"
                      />
                      <div v-else class="flex items-center gap-2">
                        <input 
                          type="file"
                          @change="handleFileSelect($event, row)"
                          class="text-xs text-surface-700 dark:text-surface-300 file:mr-2 file:py-1 file:px-2 file:rounded file:border-0 file:text-xs file:bg-surface-200 dark:file:bg-surface-700 file:text-surface-900 dark:file:text-surface-50 hover:file:bg-surface-300 dark:hover:file:bg-surface-600"
                        />
                        <span v-if="row.value" class="text-xs text-surface-500">{{ row.value }}</span>
                      </div>
                    </div>
                    <div class="col-span-1 flex justify-center">
                      <Button 
                        v-if="localRequest.body.formData.length > 1 || row.key || row.value"
                        icon="pi pi-trash"
                        text
                        rounded
                        size="small"
                        severity="danger"
                        @click="removeFormDataRow(index)"
                      />
                    </div>
                  </div>
                </div>
              </div>

              <!-- URL Encoded -->
              <div v-else-if="localRequest.body.type === 'x-www-form-urlencoded'">
                <!-- Table Header -->
                <div class="grid grid-cols-12 gap-2 mb-2 text-sm font-bold text-surface-700 dark:text-surface-300 px-2">
                  <div class="col-span-1"></div>
                  <div class="col-span-5">KEY</div>
                  <div class="col-span-5">VALUE</div>
                  <div class="col-span-1"></div>
                </div>
                
                <!-- Table Rows -->
                <div class="space-y-1">
                  <div 
                    v-for="(row, index) in localRequest.body.urlencoded"
                    :key="index"
                    class="grid grid-cols-12 gap-2 items-center"
                  >
                    <div class="col-span-1 flex justify-center">
                      <Checkbox v-model="row.enabled" :binary="true" />
                    </div>
                    <div class="col-span-5">
                      <VariableInput 
                        v-model="row.key"
                        placeholder="Key"
                        size="small"
                        :availableVariables="availableVariables"
                        @input="onUrlencodedChange"
                      />
                    </div>
                    <div class="col-span-5">
                      <VariableInput 
                        v-model="row.value"
                        placeholder="Value"
                        size="small"
                        :availableVariables="availableVariables"
                        @input="onUrlencodedChange"
                      />
                    </div>
                    <div class="col-span-1 flex justify-center">
                      <Button 
                        v-if="localRequest.body.urlencoded.length > 1 || row.key || row.value"
                        icon="pi pi-trash"
                        text
                        rounded
                        size="small"
                        severity="danger"
                        @click="removeUrlencodedRow(index)"
                      />
                    </div>
                  </div>
                </div>
              </div>

              <!-- JSON / Raw -->
              <div v-else-if="localRequest.body.type === 'json'">
                <JsonEditor 
                  v-model="localRequest.body.raw"
                  placeholder='{"key": "value"}'
                  :availableVariables="availableVariables"
                />
              </div>
            </div>
          </TabPanel>

          <TabPanel header="Tests">
            <div class="p-4">
              <Accordion v-model:value="testsAccordion" multiple>
                <!-- 1. 响应码期望值判断 -->
                <AccordionPanel value="0">
                  <AccordionHeader>
                    <span class="flex items-center gap-2">
                      <i class="pi pi-check-circle"></i>
                      <span class="font-semibold">状态码断言</span>
                      <Badge :value="statusCodeTests.filter(t => t.enabled).length" severity="info" class="ml-2" />
                    </span>
                  </AccordionHeader>
                  <AccordionContent>
                    <div class="space-y-3">
                      <p class="text-sm text-surface-600 dark:text-surface-400 mb-3">
                        验证HTTP响应状态码是否符合预期
                      </p>
                      
                      <!-- Table Header -->
                      <div class="grid grid-cols-12 gap-2 mb-2 text-sm font-bold text-surface-700 dark:text-surface-300 px-2">
                        <div class="col-span-1"></div>
                        <div class="col-span-3">操作符</div>
                        <div class="col-span-2">期望值</div>
                        <div class="col-span-5">描述</div>
                        <div class="col-span-1"></div>
                      </div>
                      
                      <!-- Table Rows -->
                      <div class="space-y-2">
                        <div 
                          v-for="(test, index) in statusCodeTests"
                          :key="index"
                          class="grid grid-cols-12 gap-2 items-center"
                        >
                          <div class="col-span-1 flex justify-center">
                            <Checkbox v-model="test.enabled" :binary="true" />
                          </div>
                          <div class="col-span-3">
                            <Dropdown 
                              v-model="test.operator"
                              :options="operatorOptions"
                              optionLabel="label"
                              optionValue="value"
                              class="w-full"
                              size="small"
                            />
                          </div>
                          <div class="col-span-2">
                            <InputText 
                              v-model="test.expectedValue"
                              placeholder="200"
                              class="w-full"
                              size="small"
                            />
                          </div>
                          <div class="col-span-5">
                            <InputText 
                              v-model="test.description"
                              placeholder="描述（可选）"
                              class="w-full"
                              size="small"
                            />
                          </div>
                          <div class="col-span-1 flex justify-center">
                            <Button 
                              v-if="statusCodeTests.length > 1"
                              icon="pi pi-trash"
                              text
                              rounded
                              size="small"
                              severity="danger"
                              @click="removeStatusCodeTest(index)"
                            />
                          </div>
                        </div>
                      </div>
                      
                      <Button 
                        label="添加断言"
                        icon="pi pi-plus"
                        size="small"
                        text
                        @click="addStatusCodeTest"
                        class="mt-2"
                      />
                    </div>
                  </AccordionContent>
                </AccordionPanel>

                <!-- 2. JSON字段断言 -->
                <AccordionPanel value="1">
                  <AccordionHeader>
                    <span class="flex items-center gap-2">
                      <i class="pi pi-code"></i>
                      <span class="font-semibold">JSON字段断言</span>
                      <Badge :value="jsonFieldTests.filter(t => t.enabled).length" severity="success" class="ml-2" />
                    </span>
                  </AccordionHeader>
                  <AccordionContent>
                    <div class="space-y-3">
                      <p class="text-sm text-surface-600 dark:text-surface-400 mb-3">
                        使用JSONPath提取并验证响应字段值。使用 <code class="px-1 py-0.5 bg-surface-100 dark:bg-surface-800 rounded">$</code> 表示根节点，
                        <code class="px-1 py-0.5 bg-surface-100 dark:bg-surface-800 rounded">[index]</code> 访问数组元素，
                        <code class="px-1 py-0.5 bg-surface-100 dark:bg-surface-800 rounded">.</code> 访问对象属性
                      </p>
                      
                      <!-- Table Header -->
                      <div class="grid grid-cols-12 gap-2 mb-2 text-sm font-bold text-surface-700 dark:text-surface-300 px-2">
                        <div class="col-span-1"></div>
                        <div class="col-span-3">JSON路径</div>
                        <div class="col-span-2">操作符</div>
                        <div class="col-span-2">期望值</div>
                        <div class="col-span-3">描述</div>
                        <div class="col-span-1"></div>
                      </div>
                      
                      <!-- Table Rows -->
                      <div class="space-y-2">
                        <div 
                          v-for="(test, index) in jsonFieldTests"
                          :key="index"
                          class="grid grid-cols-12 gap-2 items-center"
                        >
                          <div class="col-span-1 flex justify-center">
                            <Checkbox v-model="test.enabled" :binary="true" />
                          </div>
                          <div class="col-span-3">
                            <InputText 
                              v-model="test.jsonPath"
                              placeholder="$.data.id"
                              class="w-full font-mono text-xs"
                              size="small"
                            />
                          </div>
                          <div class="col-span-2">
                            <Dropdown 
                              v-model="test.operator"
                              :options="operatorOptions"
                              optionLabel="label"
                              optionValue="value"
                              class="w-full"
                              size="small"
                            />
                          </div>
                          <div class="col-span-2">
                            <InputText 
                              v-model="test.expectedValue"
                              placeholder="期望值"
                              class="w-full"
                              size="small"
                            />
                          </div>
                          <div class="col-span-3">
                            <InputText 
                              v-model="test.description"
                              placeholder="描述（可选）"
                              class="w-full"
                              size="small"
                            />
                          </div>
                          <div class="col-span-1 flex justify-center">
                            <Button 
                              v-if="jsonFieldTests.length > 1"
                              icon="pi pi-trash"
                              text
                              rounded
                              size="small"
                              severity="danger"
                              @click="removeJsonFieldTest(index)"
                            />
                          </div>
                        </div>
                      </div>
                      
                      <Button 
                        label="添加断言"
                        icon="pi pi-plus"
                        size="small"
                        text
                        @click="addJsonFieldTest"
                        class="mt-2"
                      />
                    </div>
                  </AccordionContent>
                </AccordionPanel>

                <!-- 3. 全局变量设置 -->
                <AccordionPanel value="2">
                  <AccordionHeader>
                    <span class="flex items-center gap-2">
                      <i class="pi pi-globe"></i>
                      <span class="font-semibold">全局变量设置</span>
                      <Badge :value="globalVariables.filter(v => v.enabled).length" severity="warning" class="ml-2" />
                    </span>
                  </AccordionHeader>
                  <AccordionContent>
                    <div class="space-y-3">
                      <p class="text-sm text-surface-600 dark:text-surface-400 mb-3">
                        从响应中提取字段值并保存到全局变量，可在后续请求中使用
                      </p>
                      
                      <!-- Table Header -->
                      <div class="grid grid-cols-12 gap-2 mb-2 text-sm font-bold text-surface-700 dark:text-surface-300 px-2">
                        <div class="col-span-1"></div>
                        <div class="col-span-2">变量名</div>
                        <div class="col-span-2">类型</div>
                        <div class="col-span-3">值</div>
                        <div class="col-span-3">描述</div>
                        <div class="col-span-1"></div>
                      </div>
                      
                      <!-- Table Rows -->
                      <div class="space-y-2">
                        <div 
                          v-for="(variable, index) in globalVariables"
                          :key="index"
                          class="grid grid-cols-12 gap-2 items-center"
                        >
                          <div class="col-span-1 flex justify-center">
                            <Checkbox v-model="variable.enabled" :binary="true" />
                          </div>
                          <div class="col-span-2">
                            <InputText 
                              v-model="variable.variableName"
                              placeholder="token"
                              class="w-full font-mono text-xs"
                              size="small"
                            />
                          </div>
                          <div class="col-span-2">
                            <Select 
                              v-model="variable.valueType"
                              :options="[
                                { label: 'JSON路径', value: 'jsonPath' },
                                { label: '自定义值', value: 'customValue' }
                              ]"
                              optionLabel="label"
                              optionValue="value"
                              class="w-full"
                              size="small"
                            />
                          </div>
                          <div class="col-span-3">
                            <InputText 
                              v-if="variable.valueType === 'jsonPath'"
                              v-model="variable.jsonPath"
                              placeholder="$.data.token"
                              class="w-full font-mono text-xs"
                              size="small"
                            />
                            <InputText 
                              v-else
                              v-model="variable.customValue"
                              placeholder="自定义值"
                              class="w-full text-xs"
                              size="small"
                            />
                          </div>
                          <div class="col-span-3">
                            <InputText 
                              v-model="variable.description"
                              placeholder="描述（可选）"
                              class="w-full"
                              size="small"
                            />
                          </div>
                          <div class="col-span-1 flex justify-center">
                            <Button 
                              v-if="globalVariables.length > 1"
                              icon="pi pi-trash"
                              text
                              rounded
                              size="small"
                              severity="danger"
                              @click="removeGlobalVariable(index)"
                            />
                          </div>
                        </div>
                      </div>
                      
                      <Button 
                        label="添加变量"
                        icon="pi pi-plus"
                        size="small"
                        text
                        @click="addGlobalVariable"
                        class="mt-2"
                      />
                    </div>
                  </AccordionContent>
                </AccordionPanel>
              </Accordion>
            </div>
          </TabPanel>

          <TabPanel header="Code">
            <div class="p-4">
              <TabView v-model:activeIndex="activeCodeTab">
                <TabPanel header="Export">
                  <div class="space-y-3 pt-3">
                    <div class="flex justify-between items-center">
                      <h4 class="text-sm font-medium text-surface-700 dark:text-surface-300">cURL Command</h4>
                      <Button 
                        label="Copy"
                        icon="pi pi-copy"
                        size="small"
                        @click="copyCurl"
                      />
                    </div>
                    <pre class="p-4 bg-surface-100 dark:bg-surface-900 rounded text-xs font-mono whitespace-pre-wrap overflow-x-auto border border-surface-200 dark:border-surface-700 max-h-96">{{ generateCurl() }}</pre>
                  </div>
                </TabPanel>

                <TabPanel header="Import">
                  <div class="space-y-3 pt-3">
                    <div class="flex justify-between items-center">
                      <h4 class="text-sm font-medium text-surface-700 dark:text-surface-300">Paste cURL Command</h4>
                      <Button 
                        label="Import"
                        icon="pi pi-download"
                        size="small"
                        @click="importCurl"
                        :disabled="!curlInput.trim()"
                      />
                    </div>
                    <Textarea 
                      v-model="curlInput"
                      rows="10"
                      class="w-full font-mono text-xs"
                      placeholder="curl -X GET 'https://api.example.com/users' -H 'Authorization: Bearer token'"
                    />
                  </div>
                </TabPanel>
              </TabView>
            </div>
          </TabPanel>
        </TabView>
      </div>

      <!-- Response Section -->
      <div class="border-t border-surface-200 dark:border-surface-700 bg-surface-0 dark:bg-surface-950 flex flex-col relative" :style="{ height: isResponseCollapsed ? '40px' : `${responseHeight}px` }">
        <!-- Loading Overlay - 覆盖整个 Response 区域 -->
        <div 
          v-if="isLoading && !isResponseCollapsed"
          class="absolute inset-0 bg-surface-0/50 dark:bg-surface-950/50 backdrop-blur-[2px] z-50 flex items-center justify-center"
        >
          <div class="flex flex-col items-center gap-4 p-6 bg-surface-0 dark:bg-surface-900 rounded-lg shadow-lg border border-surface-200 dark:border-surface-700">
            <div class="flex items-center gap-3">
              <i class="pi pi-spin pi-spinner text-2xl text-primary"></i>
              <span class="text-lg font-medium text-surface-900 dark:text-surface-50">Sending Request...</span>
            </div>
            <Button 
              label="Cancel"
              icon="pi pi-times"
              severity="danger"
              outlined
              @click="cancelRequest"
            />
          </div>
        </div>
        
        <!-- Resize Handle (only when expanded) -->
        <div 
          v-if="!isResponseCollapsed"
          @mousedown="startResize"
          class="h-1 bg-surface-200 dark:bg-surface-700 hover:bg-primary cursor-ns-resize transition"
          :class="{ 'bg-primary': isResizing }"
        ></div>

        <!-- Response Header with Status and Time -->
        <div 
          @click="toggleResponseCollapse"
          class="px-4 py-2 flex items-center justify-between cursor-pointer hover:bg-surface-100 dark:hover:bg-surface-800 transition" 
          :class="{ 'border-b border-surface-200 dark:border-surface-700': !isResponseCollapsed }"
        >
          <div class="flex items-center gap-2 text-sm">
            <span class="font-medium">Response</span>
            <i :class="['pi text-xs', isResponseCollapsed ? 'pi-chevron-up' : 'pi-chevron-down']"></i>
          </div>
          <div v-if="response && !isResponseCollapsed" class="flex items-center gap-4 text-sm">
            <span :class="['font-semibold', response.status >= 200 && response.status < 300 ? 'text-green-600' : response.status === 0 ? 'text-red-600' : 'text-red-600']">
              Status: {{ response.status }} {{ response.statusText }}
            </span>
            <span class="text-surface-500">Time: {{ response.time }}</span>
            <span class="text-surface-500">Size: {{ response.size }}</span>
          </div>
        </div>

        <!-- Collapsed or Expanded Content -->
        <div v-if="!isResponseCollapsed" class="flex-1 overflow-hidden flex flex-col">
          <!-- Empty State or Response Content -->
          <div v-if="!response" class="flex-1 flex items-center justify-center">
            <div class="text-center text-surface-400 dark:text-surface-500">
              <i class="pi pi-send text-4xl mb-3"></i>
              <p class="text-sm">Send a request to see the response</p>
            </div>
          </div>

          <!-- Response Tabs -->
          <TabView v-else v-model:activeIndex="activeResponseTab" class="response-tabs flex-1">
            <TabPanel header="Body">
              <div class="flex flex-col h-full">
                <!-- Body View Tabs -->
                <div class="flex items-center justify-between border-b border-surface-200 dark:border-surface-700 bg-surface-0 dark:bg-surface-950">
                  <div class="flex">
                    <button 
                      @click="activeBodyViewTab = 0"
                      :class="[
                        'px-4 py-2 text-sm font-medium transition',
                        activeBodyViewTab === 0 
                          ? 'text-primary border-b-2 border-primary' 
                          : 'text-surface-600 dark:text-surface-400 hover:text-surface-900 dark:hover:text-surface-50'
                      ]"
                    >
                      Pretty
                    </button>
                    <button 
                      @click="activeBodyViewTab = 1"
                      :class="[
                        'px-4 py-2 text-sm font-medium transition',
                        activeBodyViewTab === 1 
                          ? 'text-primary border-b-2 border-primary' 
                          : 'text-surface-600 dark:text-surface-400 hover:text-surface-900 dark:hover:text-surface-50'
                      ]"
                    >
                      Raw
                    </button>
                  </div>
                  
                  <div class="flex items-center gap-2 mr-2">
                    <!-- Search Button -->
                    <Button 
                      v-if="!isImageResponse"
                      icon="pi pi-search"
                      size="small"
                      text
                      :class="{ 'text-primary': showSearchBox }"
                      title="Search in response"
                      @click="toggleSearchBox"
                    />
                    
                    <!-- Copy Button -->
                    <Button 
                      v-if="!isImageResponse"
                      icon="pi pi-copy"
                      size="small"
                      text
                      :title="activeBodyViewTab === 0 ? 'Copy Response' : 'Copy Raw Response'"
                      @click="activeBodyViewTab === 0 ? copyResponseBody() : copyRawResponseBody()"
                    />
                  </div>
                </div>

                <!-- Search Box -->
                <div v-if="showSearchBox && !isImageResponse" class="p-2 border-b border-surface-200 dark:border-surface-700 bg-surface-50 dark:bg-surface-900">
                  <div class="flex items-center gap-2">
                    <InputText 
                      v-model="searchQuery"
                      placeholder="Search..."
                      size="small"
                      class="flex-1 response-search-input"
                      @keyup.enter="performSearch"
                      @keyup.esc="toggleSearchBox"
                    />
                    
                    <!-- Case Sensitive Toggle -->
                    <Button 
                      label="Aa"
                      size="small"
                      :severity="searchCaseSensitive ? 'primary' : 'secondary'"
                      :outlined="!searchCaseSensitive"
                      :class="{ 'search-toggle-active': searchCaseSensitive }"
                      title="Match case"
                      @click="searchCaseSensitive = !searchCaseSensitive"
                    />
                    
                    <!-- Regex Toggle -->
                    <Button 
                      label=".*"
                      size="small"
                      :severity="searchRegex ? 'primary' : 'secondary'"
                      :outlined="!searchRegex"
                      :class="{ 'search-toggle-active': searchRegex }"
                      title="Use regular expression"
                      @click="searchRegex = !searchRegex"
                    />
                    
                    <!-- Match Counter -->
                    <span v-if="searchMatches.length > 0" class="text-xs text-surface-600 dark:text-surface-400 whitespace-nowrap">
                      {{ currentMatchIndex + 1 }} / {{ searchMatches.length }}
                    </span>
                    <span v-else-if="searchQuery" class="text-xs text-surface-600 dark:text-surface-400">
                      No matches
                    </span>
                    
                    <!-- Navigation Buttons -->
                    <Button 
                      icon="pi pi-chevron-up"
                      size="small"
                      text
                      :disabled="searchMatches.length === 0"
                      title="Previous match"
                      @click="prevMatch"
                    />
                    <Button 
                      icon="pi pi-chevron-down"
                      size="small"
                      text
                      :disabled="searchMatches.length === 0"
                      title="Next match"
                      @click="nextMatch"
                    />
                    
                    <!-- Close Button -->
                    <Button 
                      icon="pi pi-times"
                      size="small"
                      text
                      severity="secondary"
                      title="Close search"
                      @click="toggleSearchBox"
                    />
                  </div>
                </div>

                <!-- Pretty View -->
                <div v-if="activeBodyViewTab === 0" class="flex-1 overflow-y-auto p-4">
                  <!-- Image Response -->
                  <div v-if="isImageResponse" class="flex items-center justify-center">
                    <img 
                      :src="response.imageDataUrl" 
                      :alt="response.contentType"
                      class="max-w-full max-h-full object-contain"
                      style="max-height: 500px;"
                    />
                  </div>
                  <!-- Code Response (JSON/XML/HTML) - 始终使用 CodeEditor，支持搜索高亮 -->
                  <CodeEditor 
                    v-else-if="shouldUseCodeEditor"
                    :modelValue="response.body"
                    :language="responseLanguage"
                    :readOnly="true"
                    :searchMatches="searchMatches"
                    :currentMatchIndex="currentMatchIndex"
                  />
                  <!-- Text Response with search highlighting -->
                  <pre v-else-if="searchMatches.length > 0" class="text-xs font-mono whitespace-pre-wrap" v-html="highlightedResponseBody"></pre>
                  <!-- Text Response without search -->
                  <pre v-else class="text-xs font-mono whitespace-pre-wrap">{{ response.body }}</pre>
                </div>

                <!-- Raw View -->
                <div v-else class="flex-1 overflow-y-auto p-4">
                  <!-- Text with search highlighting -->
                  <pre v-if="searchMatches.length > 0" class="text-xs font-mono whitespace-pre-wrap" v-html="highlightedResponseBody"></pre>
                  <!-- Text without search -->
                  <pre v-else class="text-xs font-mono whitespace-pre-wrap">{{ response.rawBody }}</pre>
                </div>
              </div>
            </TabPanel>

            <TabPanel header="Headers">
              <div class="p-4 overflow-y-auto">
                <!-- Headers Table -->
                <div class="grid grid-cols-2 gap-2 text-sm">
                  <div class="font-bold text-surface-700 dark:text-surface-300 pb-2 border-b border-surface-200 dark:border-surface-700">
                    KEY
                  </div>
                  <div class="font-bold text-surface-700 dark:text-surface-300 pb-2 border-b border-surface-200 dark:border-surface-700">
                    VALUE
                  </div>
                  <template v-for="(value, key) in response.headers" :key="key">
                    <div class="py-2 text-surface-700 dark:text-surface-300 border-b border-surface-100 dark:border-surface-800">
                      {{ key }}
                    </div>
                    <div class="py-2 text-surface-600 dark:text-surface-400 border-b border-surface-100 dark:border-surface-800 break-all">
                      {{ value }}
                    </div>
                  </template>
                </div>
              </div>
            </TabPanel>

            <TabPanel>
              <template #header>
                <span class="flex items-center gap-2">
                  <span>Test Results</span>
                  <Badge 
                    v-if="testResultsSummary && testResultsSummary.hasTests"
                    :value="`${testResultsSummary.passed}/${testResultsSummary.total}`"
                    :severity="testResultsSummary.failed === 0 ? 'success' : 'danger'"
                  />
                </span>
              </template>
              
              <div class="h-full overflow-y-auto">
                <div class="p-4 pb-20">
                  <!-- No Tests -->
                  <div v-if="!testResultsSummary || !testResultsSummary.hasTests" class="text-center text-surface-400 dark:text-surface-500 py-8">
                    <i class="pi pi-info-circle text-4xl mb-3"></i>
                    <p class="text-sm">No tests configured. Go to the Tests tab to add assertions.</p>
                  </div>

                  <!-- Test Results -->
                  <div v-else class="space-y-4">
                    <!-- Summary -->
                    <div class="flex items-center gap-4 p-3 bg-surface-100 dark:bg-surface-800 rounded">
                      <div class="flex items-center gap-2">
                        <i class="pi pi-check-circle text-green-600 dark:text-green-400"></i>
                        <span class="text-sm font-medium">Passed: {{ testResultsSummary.passed }}</span>
                      </div>
                      <div class="flex items-center gap-2">
                        <i class="pi pi-times-circle text-red-600 dark:text-red-400"></i>
                        <span class="text-sm font-medium">Failed: {{ testResultsSummary.failed }}</span>
                      </div>
                      <div v-if="testResultsSummary.globalVarsSet > 0" class="flex items-center gap-2">
                        <i class="pi pi-globe text-blue-600 dark:text-blue-400"></i>
                        <span class="text-sm font-medium">Variables Set: {{ testResultsSummary.globalVarsSet }}</span>
                      </div>
                    </div>

                    <!-- Status Code Tests -->
                    <div v-if="testResults.statusCode.length > 0">
                      <h4 class="text-sm font-semibold text-surface-700 dark:text-surface-300 mb-3 flex items-center gap-2">
                        <i class="pi pi-check-circle"></i>
                        Status Code Assertions
                      </h4>
                      <div class="space-y-2">
                        <div 
                          v-for="(result, index) in testResults.statusCode"
                          :key="index"
                          class="flex items-start gap-3 p-3 rounded border"
                          :class="result.passed 
                            ? 'bg-green-50 dark:bg-green-950 border-green-200 dark:border-green-800' 
                            : 'bg-red-50 dark:bg-red-950 border-red-200 dark:border-red-800'"
                        >
                          <i 
                            :class="result.passed ? 'pi pi-check text-green-600 dark:text-green-400' : 'pi pi-times text-red-600 dark:text-red-400'"
                            class="mt-0.5 flex-shrink-0"
                          ></i>
                          <div class="flex-1 min-w-0">
                            <div class="text-sm font-medium mb-1" :class="result.passed ? 'text-green-700 dark:text-green-300' : 'text-red-700 dark:text-red-300'">
                              {{ result.message }}
                            </div>
                            <div v-if="result.description" class="text-xs text-surface-600 dark:text-surface-400">
                              {{ result.description }}
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- JSON Field Tests -->
                    <div v-if="testResults.jsonFields.length > 0">
                      <h4 class="text-sm font-semibold text-surface-700 dark:text-surface-300 mb-3 flex items-center gap-2">
                        <i class="pi pi-code"></i>
                        JSON Field Assertions
                      </h4>
                      <div class="space-y-3">
                        <div 
                          v-for="(result, index) in testResults.jsonFields"
                          :key="index"
                          class="p-3 rounded border"
                          :class="result.passed 
                            ? 'bg-green-50 dark:bg-green-950 border-green-200 dark:border-green-800' 
                            : 'bg-red-50 dark:bg-red-950 border-red-200 dark:border-red-800'"
                        >
                          <div class="flex items-start gap-3 mb-2">
                            <i 
                              :class="result.passed ? 'pi pi-check text-green-600 dark:text-green-400' : 'pi pi-times text-red-600 dark:text-red-400'"
                              class="mt-0.5 flex-shrink-0"
                            ></i>
                            <div class="flex-1 min-w-0">
                              <div class="text-xs font-semibold text-surface-500 dark:text-surface-400 mb-1">
                                JSON Path
                              </div>
                              <div class="font-mono text-sm mb-2 break-all" :class="result.passed ? 'text-green-700 dark:text-green-300' : 'text-red-700 dark:text-red-300'">
                                {{ result.jsonPath }}
                              </div>
                              
                              <div class="grid grid-cols-3 gap-3 text-xs">
                                <div>
                                  <div class="font-semibold text-surface-500 dark:text-surface-400 mb-1">Actual Value</div>
                                  <div class="font-mono p-2 bg-surface-100 dark:bg-surface-900 rounded break-all">
                                    {{ result.actualValue !== undefined ? result.actualValue : 'undefined' }}
                                  </div>
                                </div>
                                <div>
                                  <div class="font-semibold text-surface-500 dark:text-surface-400 mb-1">Operator</div>
                                  <div class="font-mono p-2 bg-surface-100 dark:bg-surface-900 rounded text-center">
                                    {{ getOperatorLabel(result.operator) }}
                                  </div>
                                </div>
                                <div>
                                  <div class="font-semibold text-surface-500 dark:text-surface-400 mb-1">Expected Value</div>
                                  <div class="font-mono p-2 bg-surface-100 dark:bg-surface-900 rounded break-all">
                                    {{ result.expectedValue }}
                                  </div>
                                </div>
                              </div>
                              
                              <div v-if="result.description" class="text-xs text-surface-600 dark:text-surface-400 mt-2 pt-2 border-t border-surface-200 dark:border-surface-700">
                                <span class="font-semibold">Description:</span> {{ result.description }}
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Global Variables -->
                    <div v-if="testResults.globalVars.length > 0">
                      <h4 class="text-sm font-semibold text-surface-700 dark:text-surface-300 mb-3 flex items-center gap-2">
                        <i class="pi pi-globe"></i>
                        Global Variables Set
                      </h4>
                      <div class="space-y-2">
                        <div 
                          v-for="(result, index) in testResults.globalVars"
                          :key="index"
                          class="flex items-start gap-3 p-3 rounded border bg-blue-50 dark:bg-blue-950 border-blue-200 dark:border-blue-800"
                        >
                          <i class="pi pi-check text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0"></i>
                          <div class="flex-1 min-w-0">
                            <div class="text-sm font-medium text-blue-700 dark:text-blue-300 mb-1 break-all">
                              {{ result.message }}
                            </div>
                            <div v-if="result.description" class="text-xs text-surface-600 dark:text-surface-400">
                              {{ result.description }}
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </TabPanel>
          </TabView>
        </div>
      </div>
    </div>

    <!-- Save Request Dialog -->
    <Dialog 
      v-model:visible="showSaveDialog"
      header="Save Request"
      :modal="true"
      :style="{ width: '500px' }"
    >
      <div class="flex flex-col gap-4">
        <!-- Request Name -->
        <div>
          <label for="requestName" class="block text-sm font-medium mb-2">
            Request Name
          </label>
          <InputText 
            id="requestName"
            v-model="saveRequestName"
            placeholder="Enter request name"
            class="w-full"
            autofocus
          />
        </div>

        <!-- Collection Selection -->
        <div>
          <label class="block text-sm font-medium mb-2">
            Save to Collection
          </label>
          
          <!-- Tree Component with built-in search -->
          <div class="border border-surface-300 dark:border-surface-600 rounded p-3 max-h-64 overflow-y-auto">
            <Tree 
              :value="treeData"
              v-model:selectionKeys="selectedKeys"
              selectionMode="single"
              @node-select="onNodeSelect"
              :filter="true"
              :filterBy="'label'"
              :filterMode="'lenient'"
              :filterPlaceholder="'Search collections...'"
              class="w-full"
            >
              <template #default="{ node }">
                <span>{{ node.label }}</span>
              </template>
            </Tree>
          </div>
          
          <!-- Selected Location Display -->
          <div v-if="selectedCollection" class="mt-2 p-2 bg-surface-100 dark:bg-surface-800 rounded text-sm">
            <span class="font-medium">Selected: </span>
            <span>{{ selectedPath }}</span>
          </div>
        </div>
      </div>
      
      <template #footer>
        <Button 
          label="Cancel" 
          severity="secondary" 
          @click="showSaveDialog = false" 
        />
        <Button 
          label="Save" 
          @click="saveRequest"
          :disabled="!saveRequestName.trim() || !selectedCollection"
        />
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
:deep(.request-tabs) {
  display: flex;
  flex-direction: column;
  flex: 1;
  overflow: hidden;
}

:deep(.request-tabs .p-tabview-panels) {
  flex: 1;
  overflow-y: auto;
  padding: 0;
}

:deep(.request-tabs .p-tabview-panel) {
  padding: 0;
}

/* Checkbox 选中时背景色为黑色 */
:deep(.p-checkbox .p-checkbox-box.p-highlight) {
  background: #000000;
  border-color: #000000;
}

:deep(.p-dark .p-checkbox .p-checkbox-box.p-highlight) {
  background: #ffffff;
  border-color: #ffffff;
}

:deep(.p-dark .p-checkbox .p-checkbox-box.p-highlight .p-checkbox-icon) {
  color: #000000;
}

/* Password 组件占满宽度 */
:deep(.password-full-width) {
  width: 100%;
}

:deep(.password-full-width .p-password-input) {
  width: 100%;
}

/* Radio 选中时颜色 */
:deep(.p-radiobutton .p-radiobutton-box.p-highlight) {
  background: #3b82f6;
  border-color: #3b82f6;
}

:deep(.p-radiobutton .p-radiobutton-box.p-highlight .p-radiobutton-icon) {
  background: #fca5a5;
}

:deep(.p-dark .p-radiobutton .p-radiobutton-box.p-highlight) {
  background: #60a5fa;
  border-color: #60a5fa;
}

:deep(.p-dark .p-radiobutton .p-radiobutton-box.p-highlight .p-radiobutton-icon) {
  background: #fca5a5;
}

/* Beautify 按钮样式 */
:deep(.beautify-btn) {
  color: #fb923c !important;
}

:deep(.beautify-btn:hover) {
  color: #f97316 !important;
  background: rgba(251, 146, 60, 0.1) !important;
}

/* Response tabs 样式 */
:deep(.response-tabs) {
  display: flex;
  flex-direction: column;
  flex: 1;
  overflow: hidden;
}

:deep(.response-tabs .p-tabview-panels) {
  flex: 1;
  overflow-y: auto;
  padding: 0;
  background: transparent;
}

:deep(.response-tabs .p-tabview-panel) {
  padding: 0;
  height: 100%;
}

/* Search toggle button active state */
.search-toggle-active {
  font-weight: 700 !important;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.5) !important;
}

:deep(.search-toggle-active.p-button) {
  background: #3b82f6 !important;
  border-color: #3b82f6 !important;
  color: white !important;
}

:deep(.p-dark .search-toggle-active.p-button) {
  background: #60a5fa !important;
  border-color: #60a5fa !important;
  color: #1e293b !important;
}
</style>
