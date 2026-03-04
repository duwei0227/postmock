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
      const data = await storageService.loadSequences();
      sequences.value = new Map(Object.entries(data));
    } catch (error) {
      console.error('Failed to load sequences:', error);
    } finally {
      isLoading.value = false;
    }
  }

  async function saveSequences() {
    console.log('[SequencesStore] saveSequences called');
    console.log('[SequencesStore] sequences to save:', sequences.value);
    try {
      const obj = Object.fromEntries(sequences.value);
      console.log('[SequencesStore] converted to object:', obj);
      await storageService.saveSequences(obj);
      console.log('[SequencesStore] Write completed successfully');
    } catch (error) {
      console.error('[SequencesStore] Failed to save sequences:', error);
      console.error('[SequencesStore] Error stack:', error.stack);
      throw error;
    }
  }

  function getNextValue(
    name: string = 'default',
    padding: number | null = null,
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
        padding: padding ?? 0, // 首次创建时使用传入的 padding
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      sequences.value.set(name, sequence);
    }

    const value = sequence.currentValue;
    
    // Increment for next use (使用序列自己的 step)
    sequence.currentValue += sequence.step;
    sequence.updatedAt = new Date().toISOString();

    // Save to storage
    saveSequences();

    // Format with padding
    // 如果传入了 padding 参数，使用传入的（仅用于格式化）
    // 否则使用序列配置中的 padding
    const effectivePadding = padding !== null ? padding : sequence.padding;
    
    if (effectivePadding > 0) {
      return value.toString().padStart(effectivePadding, '0');
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
    console.log('[SequencesStore] updateSequence called');
    console.log('[SequencesStore] name:', name);
    console.log('[SequencesStore] updates:', updates);
    console.log('[SequencesStore] current sequences:', Array.from(sequences.value.keys()));
    
    const sequence = sequences.value.get(name);
    console.log('[SequencesStore] found sequence:', sequence);
    
    if (sequence) {
      console.log('[SequencesStore] Updating existing sequence');
      Object.assign(sequence, updates);
      sequence.updatedAt = new Date().toISOString();
      console.log('[SequencesStore] Updated sequence:', sequence);
      await saveSequences();
      console.log('[SequencesStore] Saved to storage');
    } else {
      console.log('[SequencesStore] Creating new sequence');
      // 如果序列不存在，创建一个新的
      const newSequence: Sequence = {
        name,
        currentValue: updates.currentValue ?? 1,
        startValue: updates.startValue ?? updates.currentValue ?? 1,
        step: updates.step ?? 1,
        padding: updates.padding ?? 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      console.log('[SequencesStore] New sequence:', newSequence);
      sequences.value.set(name, newSequence);
      console.log('[SequencesStore] Added to map, now have:', Array.from(sequences.value.keys()));
      await saveSequences();
      console.log('[SequencesStore] Saved to storage');
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
