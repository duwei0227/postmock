<script setup>
import { ref, computed } from 'vue';
import { useConfirm } from 'primevue/useconfirm';

const confirm = useConfirm();

const showEnvDialog = ref(false);
const envDialogMode = ref('list'); // 'list', 'add', 'edit'
const currentEnvironment = ref(null); // 当前选中的环境
const environments = ref([]);
const editingEnv = ref({
  name: '',
  variables: [{ key: '', value: '' }]
});
const hoveredVariableIndex = ref(-1);

const environmentOptions = computed(() => {
  return [
    { label: 'No Environment', value: null },
    ...environments.value.map(env => ({ label: env.name, value: env.id }))
  ];
});

// 环境管理函数
const openEnvDialog = () => {
  envDialogMode.value = 'list';
  showEnvDialog.value = true;
};

const openAddEnv = () => {
  envDialogMode.value = 'add';
  editingEnv.value = {
    name: '',
    variables: [{ key: '', value: '' }]
  };
};

const openEditEnv = (env) => {
  envDialogMode.value = 'edit';
  editingEnv.value = JSON.parse(JSON.stringify(env));
  // 确保至少有一个空行
  if (editingEnv.value.variables.length === 0 || 
      editingEnv.value.variables[editingEnv.value.variables.length - 1].key) {
    editingEnv.value.variables.push({ key: '', value: '' });
  }
};

const saveEnvironment = () => {
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

  // 过滤掉空的变量
  const filteredVariables = editingEnv.value.variables.filter(v => v.key.trim());

  if (envDialogMode.value === 'add') {
    const newEnv = {
      id: Date.now(),
      name: editingEnv.value.name.trim(),
      variables: filteredVariables
    };
    environments.value.push(newEnv);
    
    if (window.$toast) {
      window.$toast.add({
        severity: 'success',
        summary: 'Success',
        detail: 'Environment created successfully',
        life: 2000
      });
    }
  } else if (envDialogMode.value === 'edit') {
    const index = environments.value.findIndex(e => e.id === editingEnv.value.id);
    if (index !== -1) {
      environments.value[index] = {
        ...editingEnv.value,
        variables: filteredVariables
      };
      
      if (window.$toast) {
        window.$toast.add({
          severity: 'success',
          summary: 'Success',
          detail: 'Environment updated successfully',
          life: 2000
        });
      }
    }
  }

  envDialogMode.value = 'list';
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
    accept: () => {
      environments.value = environments.value.filter(e => e.id !== envId);
      if (currentEnvironment.value === envId) {
        currentEnvironment.value = null;
      }
      
      if (window.$toast) {
        window.$toast.add({
          severity: 'success',
          summary: 'Success',
          detail: 'Environment deleted successfully',
          life: 2000
        });
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
      editingEnv.value.variables.push({ key: '', value: '' });
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
    if (v.key) {
      vars[v.key] = v.value;
    }
  });
  return vars;
};

// 获取所有可用变量（环境变量 + 内置变量）
const getAllAvailableVariables = () => {
  const envVars = getCurrentEnvironmentVariables();
  
  // 内置变量
  const builtInVars = {
    '$timestamp': Date.now().toString(),
    '$isoTimestamp': new Date().toISOString(),
    '$randomInt': Math.floor(Math.random() * 1000).toString(),
    '$guid': crypto.randomUUID(),
  };
  
  return { ...envVars, ...builtInVars };
};

// 替换字符串中的变量
const replaceVariables = (str) => {
  if (!str || typeof str !== 'string') return str;
  
  const allVars = getAllAvailableVariables();
  
  return str.replace(/\{\{([^}]+)\}\}/g, (match, varName) => {
    const trimmedVarName = varName.trim();
    return allVars[trimmedVarName] !== undefined ? allVars[trimmedVarName] : match;
  });
};

defineExpose({
  getCurrentEnvironmentVariables,
  getAllAvailableVariables,
  replaceVariables,
  currentEnvironment
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
