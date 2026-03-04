<script setup>
import { ref, computed, onMounted } from 'vue';
import { useConfirm } from 'primevue/useconfirm';
import { useEnvironmentsStore } from '@/stores/environments';

const confirm = useConfirm();
const environmentsStore = useEnvironmentsStore();

const showEnvDialog = ref(false);
const envDialogMode = ref('list'); // 'list', 'add', 'edit'
const editingEnv = ref({
  id: '',
  name: '',
  variables: [{ key: '', value: '', enabled: true }]
});
const hoveredVariableIndex = ref(-1);

// 使用 store 中的数据
const currentEnvironment = computed({
  get: () => environmentsStore.activeEnvironmentId,
  set: (value) => environmentsStore.setActiveEnvironment(value)
});

const environments = computed(() => environmentsStore.environments);

const environmentOptions = computed(() => {
  return [
    { label: 'No Environment', value: null },
    ...environments.value.map(env => ({ label: env.name, value: env.id }))
  ];
});

// 加载环境数据
onMounted(async () => {
  await environmentsStore.loadEnvironments();
});

// 环境管理函数
const openEnvDialog = () => {
  envDialogMode.value = 'list';
  showEnvDialog.value = true;
};

const openAddEnv = () => {
  envDialogMode.value = 'add';
  editingEnv.value = {
    id: '',
    name: '',
    variables: [{ key: '', value: '', enabled: true }]
  };
};

// Method to open create dialog directly (for global shortcut)
const openCreateDialog = () => {
  showEnvDialog.value = true;
  openAddEnv();
};

const openEditEnv = (env) => {
  envDialogMode.value = 'edit';
  editingEnv.value = JSON.parse(JSON.stringify(env));
  // 确保至少有一个空行
  if (editingEnv.value.variables.length === 0 || 
      editingEnv.value.variables[editingEnv.value.variables.length - 1].key) {
    editingEnv.value.variables.push({ key: '', value: '', enabled: true });
  }
};

const saveEnvironment = async () => {
  if (!editingEnv.value.name.trim()) {
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Environment name is required',
        life: 3000
      });
    }
    return;
  }

  try {
    // 过滤掉空的变量
    const filteredVariables = editingEnv.value.variables.filter(v => v.key.trim());

    if (envDialogMode.value === 'add') {
      await environmentsStore.createEnvironment(editingEnv.value.name.trim());
      const newEnv = environments.value[environments.value.length - 1];
      if (filteredVariables.length > 0) {
        await environmentsStore.updateEnvironment(newEnv.id, {
          variables: filteredVariables
        });
      }
      
      if (window.$toast) {
        window.$toast.add({
          severity: 'success',
          summary: 'Success',
          detail: 'Environment created successfully',
          life: 2000
        });
      }
    } else if (envDialogMode.value === 'edit') {
      await environmentsStore.updateEnvironment(editingEnv.value.id, {
        name: editingEnv.value.name.trim(),
        variables: filteredVariables
      });
      
      if (window.$toast) {
        window.$toast.add({
          severity: 'success',
          summary: 'Success',
          detail: 'Environment updated successfully',
          life: 2000
        });
      }
    }

    envDialogMode.value = 'list';
  } catch (error) {
    console.error('Failed to save environment:', error);
    if (window.$toast) {
      window.$toast.add({
        severity: 'error',
        summary: 'Error',
        detail: 'Failed to save environment',
        life: 3000
      });
    }
  }
};

const cancelEnvEdit = () => {
  envDialogMode.value = 'list';
};

const deleteEnvironment = (envId) => {
  const env = environments.value.find(e => e.id === envId);
  if (!env) return;
  
  confirm.require({
    message: `确定要删除环境 "${env.name}" 吗？`,
    header: '确认删除',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: '删除',
    rejectLabel: '取消',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        await environmentsStore.deleteEnvironment(envId);
        
        if (window.$toast) {
          window.$toast.add({
            severity: 'success',
            summary: 'Success',
            detail: 'Environment deleted successfully',
            life: 2000
          });
        }
      } catch (error) {
        console.error('Failed to delete environment:', error);
        if (window.$toast) {
          window.$toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Failed to delete environment',
            life: 3000
          });
        }
      }
    }
  });
};

const deleteVariable = (index) => {
  if (editingEnv.value.variables.length > 1) {
    editingEnv.value.variables.splice(index, 1);
  }
};

const onVariableChange = () => {
  // 如果最后一行有内容，自动添加新的空行
  const lastVar = editingEnv.value.variables[editingEnv.value.variables.length - 1];
  if (lastVar && (lastVar.key || lastVar.value)) {
    const hasEmptyRow = editingEnv.value.variables.some(v => !v.key && !v.value);
    if (!hasEmptyRow) {
      editingEnv.value.variables.push({ key: '', value: '', enabled: true });
    }
  }
};

const getEnvDialogTitle = () => {
  if (envDialogMode.value === 'list') return 'Manage Environments';
  if (envDialogMode.value === 'add') return 'Add Environment';
  return 'Edit Environment';
};

// 获取当前环境的变量（用于替换请求中的变量）
const getCurrentEnvironmentVariables = () => {
  if (!currentEnvironment.value) return {};
  const env = environments.value.find(e => e.id === currentEnvironment.value);
  if (!env) return {};
  
  const vars = {};
  env.variables.forEach(v => {
    if (v.key && v.enabled !== false) {
      vars[v.key] = v.value;
    }
  });
  return vars;
};

// 格式化日期时间的辅助函数
const formatDateTime = (date, format) => {
  const pad = (num) => String(num).padStart(2, '0');
  
  const year = date.getFullYear();
  const month = pad(date.getMonth() + 1);
  const day = pad(date.getDate());
  const hours = pad(date.getHours());
  const minutes = pad(date.getMinutes());
  const seconds = pad(date.getSeconds());
  
  return format
    .replace(/yyyy/g, year)
    .replace(/MM/g, month)
    .replace(/dd/g, day)
    .replace(/HH/g, hours)
    .replace(/mm/g, minutes)
    .replace(/ss/g, seconds);
};

// 生成随机字符串的辅助函数
const generateRandomString = (length = 10, options = { alpha: true, numeric: true, uppercase: true, lowercase: true }) => {
  let chars = '';
  
  if (options.uppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  if (options.lowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
  if (options.numeric) chars += '0123456789';
  
  // 如果没有选择任何字符类型，默认使用全部
  if (chars === '') {
    chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  }
  
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  
  return result;
};

// 生成随机中文字符串的辅助函数
const generateRandomChineseString = (length = 5) => {
  // 常用汉字 Unicode 范围：0x4E00 - 0x9FA5
  const minCode = 0x4E00;
  const maxCode = 0x9FA5;
  
  let result = '';
  for (let i = 0; i < length; i++) {
    const code = Math.floor(Math.random() * (maxCode - minCode + 1)) + minCode;
    result += String.fromCharCode(code);
  }
  
  return result;
};

// 获取所有可用变量（环境变量 + 内置变量）
const getAllAvailableVariables = () => {
  const envVars = getCurrentEnvironmentVariables();
  
  const now = new Date();
  
  // 内置变量
  // $randomInt: 默认范围 0-1000，也可以使用 $randomInt(start, end) 指定范围
  // $date: 默认格式 yyyy-MM-dd，也可以使用 $date(format) 自定义格式
  // $time: 默认格式 HH:mm:ss，也可以使用 $time(format) 自定义格式
  // $datetime: 默认格式 yyyy-MM-dd HH:mm:ss，也可以使用 $datetime(format) 自定义格式
  // $randomString: 默认长度 10，包含大小写字母和数字，可以使用 $randomString(length, options) 自定义
  const builtInVars = {
    '$timestamp': Date.now().toString(),
    '$isoTimestamp': new Date().toISOString(),
    '$randomInt': Math.floor(Math.random() * 1001).toString(), // 0-1000
    '$guid': crypto.randomUUID(),
    '$date': formatDateTime(now, 'yyyy-MM-dd'),
    '$time': formatDateTime(now, 'HH:mm:ss'),
    '$datetime': formatDateTime(now, 'yyyy-MM-dd HH:mm:ss'),
    '$randomString': generateRandomString(10),
  };
  
  return { ...envVars, ...builtInVars };
};

// 替换字符串中的变量
const replaceVariables = (str) => {
  if (!str || typeof str !== 'string') return str;
  
  const allVars = getAllAvailableVariables();
  console.log('[EnvironmentManager] replaceVariables called');
  console.log('[EnvironmentManager] Input string:', str);
  console.log('[EnvironmentManager] Available variables:', allVars);
  
  const result = str.replace(/\{\{([^}]+)\}\}/g, (match, varName) => {
    const trimmedVarName = varName.trim();
    
    // 检查是否是 $randomInt 函数调用
    const randomIntMatch = trimmedVarName.match(/^\$randomInt\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)$/);
    if (randomIntMatch) {
      const start = parseInt(randomIntMatch[1], 10);
      const end = parseInt(randomIntMatch[2], 10);
      const randomValue = Math.floor(Math.random() * (end - start + 1)) + start;
      console.log(`[EnvironmentManager] Replacing ${match} with random int between ${start} and ${end}: ${randomValue}`);
      return randomValue.toString();
    }
    
    // 检查是否是 $randomString 函数调用
    // 支持格式: $randomString(length) 或 $randomString(length, "alpha") 或 $randomString(length, "numeric") 或 $randomString(length, "alphanumeric")
    const randomStringMatch = trimmedVarName.match(/^\$randomString\s*\(\s*(\d+)(?:\s*,\s*['"]([^'"]+)['"])?\s*\)$/);
    if (randomStringMatch) {
      const length = parseInt(randomStringMatch[1], 10);
      const type = randomStringMatch[2] || 'alphanumeric';
      
      let options = { alpha: false, numeric: false, uppercase: false, lowercase: false };
      
      switch (type.toLowerCase()) {
        case 'alpha':
          options.uppercase = true;
          options.lowercase = true;
          break;
        case 'numeric':
          options.numeric = true;
          break;
        case 'alphanumeric':
          options.uppercase = true;
          options.lowercase = true;
          options.numeric = true;
          break;
        case 'uppercase':
          options.uppercase = true;
          break;
        case 'lowercase':
          options.lowercase = true;
          break;
        default:
          // 默认使用 alphanumeric
          options.uppercase = true;
          options.lowercase = true;
          options.numeric = true;
      }
      
      const randomString = generateRandomString(length, options);
      console.log(`[EnvironmentManager] Replacing ${match} with random string (length: ${length}, type: ${type}): ${randomString}`);
      return randomString;
    }
    
    // 检查是否是 $date 函数调用
    const dateMatch = trimmedVarName.match(/^\$date\s*\(\s*['"]([^'"]+)['"]\s*\)$/);
    if (dateMatch) {
      const format = dateMatch[1];
      const formattedDate = formatDateTime(new Date(), format);
      console.log(`[EnvironmentManager] Replacing ${match} with formatted date: ${formattedDate}`);
      return formattedDate;
    }
    
    // 检查是否是 $time 函数调用
    const timeMatch = trimmedVarName.match(/^\$time\s*\(\s*['"]([^'"]+)['"]\s*\)$/);
    if (timeMatch) {
      const format = timeMatch[1];
      const formattedTime = formatDateTime(new Date(), format);
      console.log(`[EnvironmentManager] Replacing ${match} with formatted time: ${formattedTime}`);
      return formattedTime;
    }
    
    // 检查是否是 $datetime 函数调用
    const datetimeMatch = trimmedVarName.match(/^\$datetime\s*\(\s*['"]([^'"]+)['"]\s*\)$/);
    if (datetimeMatch) {
      const format = datetimeMatch[1];
      const formattedDatetime = formatDateTime(new Date(), format);
      console.log(`[EnvironmentManager] Replacing ${match} with formatted datetime: ${formattedDatetime}`);
      return formattedDatetime;
    }
    
    // 普通变量替换
    const replacement = allVars[trimmedVarName] !== undefined ? allVars[trimmedVarName] : match;
    console.log(`[EnvironmentManager] Replacing ${match} with ${replacement}`);
    return replacement;
  });
  
  console.log('[EnvironmentManager] Result:', result);
  return result;
};

defineExpose({
  getCurrentEnvironmentVariables,
  getAllAvailableVariables,
  replaceVariables,
  currentEnvironment,
  openCreateDialog
});
</script>

<template>
  <div class="environment-manager flex items-center gap-2">
    <Dropdown 
      v-model="currentEnvironment"
      :options="environmentOptions"
      optionLabel="label"
      optionValue="value"
      placeholder="No Environment"
      class="w-48"
      size="small"
    />
    <Button 
      icon="pi pi-cog"
      text
      rounded
      size="small"
      severity="secondary"
      title="Manage Environments"
      @click="openEnvDialog"
    />
    
    <!-- Environment Management Dialog -->
    <Dialog 
      v-model:visible="showEnvDialog"
      :header="getEnvDialogTitle()"
      :modal="true"
      :style="{ width: '600px' }"
      :closable="envDialogMode === 'list'"
    >
      <!-- List View -->
      <div v-if="envDialogMode === 'list'" class="flex flex-col gap-4">
        <div class="flex justify-between items-center">
          <span class="text-sm font-medium text-surface-700 dark:text-surface-300">
            Environments
          </span>
          <Button 
            label="Add"
            icon="pi pi-plus"
            size="small"
            @click="openAddEnv"
          />
        </div>
        
        <div v-if="environments.length === 0" class="text-center py-8 text-surface-500 dark:text-surface-400 text-sm">
          No environments configured
        </div>
        
        <div v-else class="space-y-2">
          <div 
            v-for="env in environments"
            :key="env.id"
            class="p-3 border border-surface-200 dark:border-surface-700 rounded hover:bg-surface-50 dark:hover:bg-surface-900 cursor-pointer transition flex justify-between items-center"
            @click="openEditEnv(env)"
          >
            <div>
              <div class="text-sm font-medium text-surface-900 dark:text-surface-50">
                {{ env.name }}
              </div>
              <div class="text-xs text-surface-500 dark:text-surface-400 mt-1">
                {{ env.variables.length }} variable(s)
              </div>
            </div>
            <Button 
              icon="pi pi-trash"
              text
              rounded
              size="small"
              severity="danger"
              @click.stop="deleteEnvironment(env.id)"
            />
          </div>
        </div>
      </div>
      
      <!-- Add/Edit View -->
      <div v-else class="flex flex-col gap-4">
        <div>
          <label class="block text-sm font-medium mb-2">Environment Name</label>
          <InputText 
            v-model="editingEnv.name"
            placeholder="Enter environment name"
            class="w-full"
          />
        </div>
        
        <div>
          <label class="block text-sm font-medium mb-3">Variables</label>
          
          <!-- Table Header -->
          <div class="flex gap-2 mb-2 text-sm font-bold text-surface-700 dark:text-surface-300 px-2">
            <div class="flex-1">VARIABLE</div>
            <div class="flex-1">VALUE</div>
            <div style="width: 40px;"></div>
          </div>
          
          <!-- Table Rows -->
          <div class="space-y-1 max-h-64 overflow-y-auto">
            <div 
              v-for="(variable, index) in editingEnv.variables"
              :key="index"
              class="flex gap-2 items-center"
              @mouseenter="hoveredVariableIndex = index"
              @mouseleave="hoveredVariableIndex = -1"
            >
              <div class="flex-1">
                <InputText 
                  v-model="variable.key"
                  placeholder="Variable"
                  class="w-full"
                  size="small"
                  @input="onVariableChange"
                />
              </div>
              <div class="flex-1">
                <InputText 
                  v-model="variable.value"
                  placeholder="Value"
                  class="w-full"
                  size="small"
                  @input="onVariableChange"
                />
              </div>
              <div class="flex justify-center" style="width: 40px;">
                <Button 
                  v-if="(hoveredVariableIndex === index || variable.key || variable.value) && editingEnv.variables.length > 1"
                  icon="pi pi-times"
                  text
                  rounded
                  size="small"
                  severity="danger"
                  @click="deleteVariable(index)"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <template #footer>
        <div v-if="envDialogMode === 'list'">
          <Button label="Close" @click="showEnvDialog = false" />
        </div>
        <div v-else class="flex gap-2">
          <Button label="Cancel" severity="secondary" @click="cancelEnvEdit" />
          <Button 
            label="Save"
            @click="saveEnvironment"
            :disabled="!editingEnv.name.trim()"
          />
        </div>
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
.environment-manager {
  display: flex;
  align-items: center;
}
</style>
