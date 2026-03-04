import { defineStore } from 'pinia';
import { ref } from 'vue';
import { storageService } from '@/services/storage';

export interface Sequence {
  name: string;
  currentValue: number;
  startValue: number;
  step: number;
  padding: number;
  createdAt: string;
  updatedAt: string;
}

export const useSequencesStore = defineStore('sequences', () => {
  // State
  const sequences = ref<Map<string, Sequence>>(new Map());
  const isLoading = ref(false);

  // Actions
  async function loadSequences() {
    isLoading.value = true;
    try {
      const data = await storageService.read('sequences.json');
      if (data) {
        const parsed = JSON.parse(data);
        sequences.value = new Map(Object.entries(parsed));
      }
    } catch (error) {
      console.error('Failed to load sequences:', error);
    } finally {
      isLoading.value = false;
    }
  }

  async function saveSequences() {
    try {
      const obj = Object.fromEntries(sequences.value);
      await storageService.write('sequences.json', JSON.stringify(obj, null, 2));
    } catch (error) {
      console.error('Failed to save sequences:', error);
      throw error;
    }
  }

  function getNextValue(
    name: string = 'default',
    padding: number = 0,
    startValue: number = 1,
    step: number = 1
  ): string {
    let sequence = sequences.value.get(name);

    if (!sequence) {
      // Create new sequence
      sequence = {
        name,
        currentValue: startValue,
        startValue,
        step,
        padding,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      sequences.value.set(name, sequence);
    }

    const value = sequence.currentValue;
    
    // Increment for next use
    sequence.currentValue += sequence.step;
    sequence.updatedAt = new Date().toISOString();

    // Save to storage
    saveSequences();

    // Format with padding
    if (padding > 0) {
      return value.toString().padStart(padding, '0');
    }
    return value.toString();
  }

  async function resetSequence(name: string, value: number) {
    const sequence = sequences.value.get(name);
    if (sequence) {
      sequence.currentValue = value;
      sequence.updatedAt = new Date().toISOString();
      await saveSequences();
    }
  }

  async function updateSequence(name: string, updates: Partial<Sequence>) {
    const sequence = sequences.value.get(name);
    if (sequence) {
      Object.assign(sequence, updates);
      sequence.updatedAt = new Date().toISOString();
      await saveSequences();
    }
  }

  async function deleteSequence(name: string) {
    sequences.value.delete(name);
    await saveSequences();
  }

  function getAllSequences(): Sequence[] {
    return Array.from(sequences.value.values());
  }

  return {
    sequences,
    isLoading,
    loadSequences,
    saveSequences,
    getNextValue,
    resetSequence,
    updateSequence,
    deleteSequence,
    getAllSequences
  };
});
