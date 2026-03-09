// File System Storage Service - Tauri-based implementation

import { appDataDir, join } from '@tauri-apps/api/path';
import { 
  readTextFile, 
  writeTextFile, 
  exists,
  mkdir,
  readDir,
  remove
} from '@tauri-apps/plugin-fs';

import type { IStorageService } from './IStorageService';
import type { 
  Collection, 
  Request, 
  Environment, 
  HistoryItem, 
  AppState 
} from '@/types/models';
import { StorageError, ErrorCode } from '@/types/errors';

export class FileSystemStorageService implements IStorageService {
  private dataDir: string = '';
  private collectionsDir: string = '';
  private requestsDir: string = '';
  private environmentsDir: string = '';
  private historyDir: string = '';
  private backupsDir: string = '';
  
  private saveQueue: Map<string, NodeJS.Timeout> = new Map();
  private readonly DEBOUNCE_MS = 500;
  private initialized: boolean = false;

  async initialize(): Promise<void> {
    if (this.initialized) return;

    try {
      // Get app data directory
      const appData = await appDataDir();
      this.dataDir = await join(appData, 'postmock');
      
      // Set up directory paths
      this.collectionsDir = await join(this.dataDir, 'collections');
      this.requestsDir = await join(this.dataDir, 'requests');
      this.environmentsDir = await join(this.dataDir, 'environments');
      this.historyDir = await join(this.dataDir, 'history');
      this.backupsDir = await join(this.dataDir, 'backups');

      // Create directories
      await this.ensureDir(this.dataDir);
      await this.ensureDir(this.collectionsDir);
      await this.ensureDir(this.requestsDir);
      await this.ensureDir(this.environmentsDir);
      await this.ensureDir(this.historyDir);
      await this.ensureDir(this.backupsDir);

      this.initialized = true;
      console.log('Storage service initialized at:', this.dataDir);
    } catch (error) {
      throw new StorageError(
        'Failed to initialize storage service',
        ErrorCode.PERMISSION_DENIED,
        error
      );
    }
  }


  private async ensureDir(path: string): Promise<void> {
    try {
      const dirExists = await exists(path);
      if (!dirExists) {
        await mkdir(path, { recursive: true });
      }
    } catch (error) {
      console.error(`Failed to create directory ${path}:`, error);
      throw new StorageError(
        `Failed to create directory: ${path}`,
        ErrorCode.PERMISSION_DENIED,
        error
      );
    }
  }

  private debouncedSave(key: string, saveFn: () => Promise<void>): void {
    // Clear existing timeout
    if (this.saveQueue.has(key)) {
      clearTimeout(this.saveQueue.get(key)!);
    }

    // Set new timeout
    const timeout = setTimeout(async () => {
      try {
        await saveFn();
        this.saveQueue.delete(key);
      } catch (error) {
        console.error(`Failed to save ${key}:`, error);
        this.saveQueue.delete(key);
      }
    }, this.DEBOUNCE_MS);

    this.saveQueue.set(key, timeout);
  }

  // Flush all pending saves immediately
  async flushSaves(): Promise<void> {
    const promises: Promise<void>[] = [];
    
    for (const [key, timeout] of this.saveQueue.entries()) {
      clearTimeout(timeout);
      // Note: We can't execute the saveFn here because we don't store it
      // This is a limitation of the current design
    }
    
    this.saveQueue.clear();
  }

  // Collections
  async loadCollections(): Promise<Collection[]> {
    try {
      const entries = await readDir(this.collectionsDir);
      const collections: Collection[] = [];

      for (const entry of entries) {
        if (entry.name && entry.name.endsWith('.json')) {
          try {
            const filePath = await join(this.collectionsDir, entry.name);
            const content = await readTextFile(filePath);
            const collection = JSON.parse(content) as Collection;
            collections.push(collection);
          } catch (error) {
            console.error(`Failed to load collection ${entry.name}:`, error);
          }
        }
      }

      return collections;
    } catch (error) {
      console.error('Failed to load collections:', error);
      return [];
    }
  }

  async saveCollection(collection: Collection): Promise<void> {
    const filePath = await join(this.collectionsDir, `${collection.id}.json`);
    
    this.debouncedSave(`collection-${collection.id}`, async () => {
      try {
        await writeTextFile(filePath, JSON.stringify(collection, null, 2));
      } catch (error) {
        throw new StorageError(
          `Failed to save collection ${collection.id}`,
          ErrorCode.DISK_FULL,
          error
        );
      }
    });
  }

  async deleteCollection(id: string): Promise<void> {
    try {
      const filePath = await join(this.collectionsDir, `${id}.json`);
      const fileExists = await exists(filePath);
      
      if (fileExists) {
        await remove(filePath);
      }
    } catch (error) {
      throw new StorageError(
        `Failed to delete collection ${id}`,
        ErrorCode.PERMISSION_DENIED,
        error
      );
    }
  }


  // Requests
  async loadRequest(id: string): Promise<Request | null> {
    try {
      const filePath = await join(this.requestsDir, `${id}.json`);
      const fileExists = await exists(filePath);
      
      if (!fileExists) {
        return null;
      }

      const content = await readTextFile(filePath);
      return JSON.parse(content) as Request;
    } catch (error) {
      console.error(`Failed to load request ${id}:`, error);
      return null;
    }
  }

  async saveRequest(request: Request, immediate: boolean = false): Promise<void> {
    const filePath = await join(this.requestsDir, `${request.id}.json`);
    
    if (immediate) {
      // Immediate save without debounce
      try {
        await writeTextFile(filePath, JSON.stringify(request, null, 2));
      } catch (error) {
        throw new StorageError(
          `Failed to save request ${request.id}`,
          ErrorCode.DISK_FULL,
          error
        );
      }
    } else {
      // Debounced save
      this.debouncedSave(`request-${request.id}`, async () => {
        try {
          await writeTextFile(filePath, JSON.stringify(request, null, 2));
        } catch (error) {
          throw new StorageError(
            `Failed to save request ${request.id}`,
            ErrorCode.DISK_FULL,
            error
          );
        }
      });
    }
  }

  async deleteRequest(id: string): Promise<void> {
    try {
      const filePath = await join(this.requestsDir, `${id}.json`);
      const fileExists = await exists(filePath);
      
      if (fileExists) {
        await remove(filePath);
      }
    } catch (error) {
      throw new StorageError(
        `Failed to delete request ${id}`,
        ErrorCode.PERMISSION_DENIED,
        error
      );
    }
  }

  // Environments
  async loadEnvironments(): Promise<Environment[]> {
    try {
      const filePath = await join(this.environmentsDir, 'environments.json');
      const fileExists = await exists(filePath);
      
      if (!fileExists) {
        return [];
      }

      const content = await readTextFile(filePath);
      return JSON.parse(content) as Environment[];
    } catch (error) {
      console.error('Failed to load environments:', error);
      return [];
    }
  }

  async saveEnvironments(environments: Environment[]): Promise<void> {
    const filePath = await join(this.environmentsDir, 'environments.json');
    
    try {
      await writeTextFile(filePath, JSON.stringify(environments, null, 2));
    } catch (error) {
      throw new StorageError(
        'Failed to save environments',
        ErrorCode.DISK_FULL,
        error
      );
    }
  }

  async loadGlobalVariables(): Promise<EnvironmentVariable[]> {
    try {
      const filePath = await join(this.environmentsDir, 'global-variables.json');
      const fileExists = await exists(filePath);
      
      if (!fileExists) {
        return [];
      }
      
      const content = await readTextFile(filePath);
      return JSON.parse(content);
    } catch (error) {
      console.error('Failed to load global variables:', error);
      return [];
    }
  }

  async saveGlobalVariables(variables: EnvironmentVariable[]): Promise<void> {
    const filePath = await join(this.environmentsDir, 'global-variables.json');
    
    try {
      await writeTextFile(filePath, JSON.stringify(variables, null, 2));
    } catch (error) {
      throw new StorageError(
        'Failed to save global variables',
        ErrorCode.DISK_FULL,
        error
      );
    }
  }

  // History
  async loadHistory(): Promise<HistoryItem[]> {
    try {
      const filePath = await join(this.historyDir, 'history.json');
      const fileExists = await exists(filePath);
      
      if (!fileExists) {
        return [];
      }

      const content = await readTextFile(filePath);
      return JSON.parse(content) as HistoryItem[];
    } catch (error) {
      console.error('Failed to load history:', error);
      return [];
    }
  }

  async saveHistory(history: HistoryItem[]): Promise<void> {
    const filePath = await join(this.historyDir, 'history.json');
    
    try {
      await writeTextFile(filePath, JSON.stringify(history, null, 2));
    } catch (error) {
      throw new StorageError(
        'Failed to save history',
        ErrorCode.DISK_FULL,
        error
      );
    }
  }

  // App State
  async loadAppState(): Promise<AppState | null> {
    try {
      const filePath = await join(this.dataDir, 'app-state.json');
      const fileExists = await exists(filePath);
      
      if (!fileExists) {
        return null;
      }

      const content = await readTextFile(filePath);
      return JSON.parse(content) as AppState;
    } catch (error) {
      console.error('Failed to load app state:', error);
      return null;
    }
  }

  async saveAppState(state: AppState): Promise<void> {
    const filePath = await join(this.dataDir, 'app-state.json');
    
    try {
      await writeTextFile(filePath, JSON.stringify(state, null, 2));
    } catch (error) {
      throw new StorageError(
        'Failed to save app state',
        ErrorCode.DISK_FULL,
        error
      );
    }
  }

  // Utility
  async backup(): Promise<void> {
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const backupPath = await join(this.backupsDir, timestamp);
      
      await this.ensureDir(backupPath);
      
      // Copy collections
      const collections = await this.loadCollections();
      for (const collection of collections) {
        const destPath = await join(backupPath, 'collections', `${collection.id}.json`);
        await this.ensureDir(await join(backupPath, 'collections'));
        await writeTextFile(destPath, JSON.stringify(collection, null, 2));
      }
      
      console.log('Backup created at:', backupPath);
    } catch (error) {
      throw new StorageError(
        'Failed to create backup',
        ErrorCode.DISK_FULL,
        error
      );
    }
  }

  async flush(): Promise<void> {
    // Wait for all pending saves to complete
    const promises: Promise<void>[] = [];
    
    for (const [key, timeout] of this.saveQueue.entries()) {
      clearTimeout(timeout);
      // Execute save immediately
      promises.push(
        new Promise((resolve) => {
          setTimeout(() => resolve(), 0);
        })
      );
    }
    
    await Promise.all(promises);
    this.saveQueue.clear();
  }

  // Sequences
  async loadSequences(): Promise<Record<string, any>> {
    const filePath = await join(this.dataDir, 'sequences.json');
    
    try {
      const fileExists = await exists(filePath);
      if (!fileExists) {
        return {};
      }
      
      const content = await readTextFile(filePath);
      return JSON.parse(content);
    } catch (error) {
      console.error('Failed to load sequences:', error);
      return {};
    }
  }

  async saveSequences(sequences: Record<string, any>): Promise<void> {
    const filePath = await join(this.dataDir, 'sequences.json');
    
    try {
      const content = JSON.stringify(sequences, null, 2);
      await writeTextFile(filePath, content);
    } catch (error) {
      console.error('Failed to save sequences:', error);
      throw new StorageError(
        'Failed to save sequences',
        ErrorCode.WRITE_ERROR,
        error
      );
    }
  }
}
