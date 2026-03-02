<script setup>
import { ref } from 'vue';
import { testStorageService } from '@/services/storage/__test__';

const isRunning = ref(false);
const testResult = ref(null);
const testOutput = ref([]);

const runTests = async () => {
  isRunning.value = true;
  testOutput.value = [];
  
  // Capture console.log
  const originalLog = console.log;
  const originalError = console.error;
  
  console.log = (...args) => {
    testOutput.value.push({ type: 'log', message: args.join(' ') });
    originalLog(...args);
  };
  
  console.error = (...args) => {
    testOutput.value.push({ type: 'error', message: args.join(' ') });
    originalError(...args);
  };
  
  try {
    const result = await testStorageService();
    testResult.value = result ? 'success' : 'failed';
  } catch (error) {
    testResult.value = 'error';
    testOutput.value.push({ type: 'error', message: error.message });
  } finally {
    console.log = originalLog;
    console.error = originalError;
    isRunning.value = false;
  }
};
</script>

<template>
  <div class="storage-test p-4">
    <h2 class="text-xl font-bold mb-4">Storage Service Test</h2>
    
    <Button 
      @click="runTests" 
      :disabled="isRunning"
      :label="isRunning ? 'Running Tests...' : 'Run Storage Tests'"
      icon="pi pi-play"
      class="mb-4"
    />
    
    <div v-if="testResult" class="mb-4">
      <div 
        :class="[
          'p-3 rounded',
          testResult === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
        ]"
      >
        {{ testResult === 'success' ? '✓ All tests passed!' : '✗ Tests failed!' }}
      </div>
    </div>
    
    <div v-if="testOutput.length > 0" class="bg-surface-900 text-surface-50 p-4 rounded font-mono text-sm overflow-auto max-h-96">
      <div 
        v-for="(output, index) in testOutput" 
        :key="index"
        :class="output.type === 'error' ? 'text-red-400' : 'text-green-400'"
      >
        {{ output.message }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.storage-test {
  max-width: 800px;
  margin: 0 auto;
}
</style>
