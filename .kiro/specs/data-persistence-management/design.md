# Data Persistence and Management System - Design

## 1. Architecture Overview

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Vue Components                        │
│  (MainContent, CollectionsPanel, HttpRequest, etc.)     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   Store Layer (Pinia)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Collections  │  │   Requests   │  │ Environments │  │
│  │    Store     │  │    Store     │  │    Store     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │   History    │  │   AppState   │                    │
│  │    Store     │  │    Store     │                    │
│  └──────────────┘  └──────────────┘                    │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  Service Layer                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │         StorageService (Abstract)                 │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   FileSystem │  │  Import/     │  │   Backup     │  │
│  │   Service    │  │  Export      │  │   Service    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Tauri File System API                       │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Design Principles

1. **Separation of Concerns**: 组件只负责UI，Store管理状态，Service处理持久化
2. **Single Responsibility**: 每个Service只负责一个特定功能
3. **Dependency Inversion**: 依赖抽象而非具体实现
4. **Open/Closed Principle**: 易于扩展新的存储后端
5. **Error Handling First**: 所有操作都有完善的错误处理

## 2. Data Models

### 2.1 TypeScript Interfaces

```typescript
// src/types/models.ts

export interface Collection {
  id: string;
  name: string;
  description?: string;
  folders: Folder[];
  requests: RequestReference[];
  createdAt: string;
  updatedAt: string;
}

export interface Folder {
  id: string;
  name: string;
  description?: string;
  folders: Folder[];
  requests: RequestReference[];
}

export interface RequestReference {
  id: string;
  name: string;
  method: HttpMethod;
  url: string;
}

export interface Request {
  id: string;
  name: string;
  method: HttpMethod;
  url: string;
  params: KeyValue[];
  headers: KeyValue[];
  body: RequestBody;
  auth: AuthConfig;
  tests: TestConfig;
  collectionId?: string;
  folderId?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Environment {
  id: string;
  name: string;
  variables: EnvironmentVariable[];
  isActive: boolean;
}

export interface HistoryItem {
  id: string;
  requestId?: string;
  method: string;
  url: string;
  status: number;
  duration: string;
  timestamp: string;
  requestData: any;
  responseData: any;
}

export interface AppState {
  openRequests: string[]; // Request IDs
  activeRequestIndex: number;
  activeEnvironmentId?: string;
  sidebarWidth: number;
  footerHeight: number;
  lastSavedAt: string;
}
```

## 3. Store Layer (Pinia)

### 3.1 Collections Store


```typescript
// src/stores/collections.ts
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { Collection, Folder, RequestReference } from '@/types/models';
import { storageService } from '@/services/storage';

export const useCollectionsStore = defineStore('collections', () => {
  const collections = ref<Collection[]>([]);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  // Getters
  const getCollectionById = computed(() => {
    return (id: string) => collections.value.find(c => c.id === id);
  });

  // Actions
  async function loadCollections() {
    isLoading.value = true;
    error.value = null;
    try {
      collections.value = await storageService.loadCollections();
    } catch (e) {
      error.value = e.message;
      console.error('Failed to load collections:', e);
    } finally {
      isLoading.value = false;
    }
  }

  async function createCollection(name: string) {
    const newCollection: Collection = {
      id: generateId(),
      name,
      folders: [],
      requests: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    collections.value.push(newCollection);
    await saveCollection(newCollection);
    return newCollection;
  }

  async function updateCollection(id: string, updates: Partial<Collection>) {
    const index = collections.value.findIndex(c => c.id === id);
    if (index !== -1) {
      collections.value[index] = {
        ...collections.value[index],
        ...updates,
        updatedAt: new Date().toISOString()
      };
      await saveCollection(collections.value[index]);
    }
  }

  async function deleteCollection(id: string) {
    const index = collections.value.findIndex(c => c.id === id);
    if (index !== -1) {
      collections.value.splice(index, 1);
      await storageService.deleteCollection(id);
    }
  }

  async function saveCollection(collection: Collection) {
    await storageService.saveCollection(collection);
  }

  return {
    collections,
    isLoading,
    error,
    getCollectionById,
    loadCollections,
    createCollection,
    updateCollection,
    deleteCollection
  };
});
```

### 3.2 Requests Store


```typescript
// src/stores/requests.ts
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { Request } from '@/types/models';
import { storageService } from '@/services/storage';

export const useRequestsStore = defineStore('requests', () => {
  const requests = ref<Map<string, Request>>(new Map());
  const isLoading = ref(false);

  // Getters
  const getRequestById = computed(() => {
    return (id: string) => requests.value.get(id);
  });

  // Actions
  async function loadRequest(id: string) {
    if (!requests.value.has(id)) {
      const request = await storageService.loadRequest(id);
      if (request) {
        requests.value.set(id, request);
      }
    }
    return requests.value.get(id);
  }

  async function saveRequest(request: Request) {
    request.updatedAt = new Date().toISOString();
    requests.value.set(request.id, request);
    await storageService.saveRequest(request);
  }

  async function deleteRequest(id: string) {
    requests.value.delete(id);
    await storageService.deleteRequest(id);
  }

  function clearCache() {
    requests.value.clear();
  }

  return {
    requests,
    isLoading,
    getRequestById,
    loadRequest,
    saveRequest,
    deleteRequest,
    clearCache
  };
});
```

## 4. Service Layer

### 4.1 Storage Service Interface


```typescript
// src/services/storage/IStorageService.ts
export interface IStorageService {
  // Collections
  loadCollections(): Promise<Collection[]>;
  saveCollection(collection: Collection): Promise<void>;
  deleteCollection(id: string): Promise<void>;
  
  // Requests
  loadRequest(id: string): Promise<Request | null>;
  saveRequest(request: Request): Promise<void>;
  deleteRequest(id: string): Promise<void>;
  
  // Environments
  loadEnvironments(): Promise<Environment[]>;
  saveEnvironments(environments: Environment[]): Promise<void>;
  
  // History
  loadHistory(): Promise<HistoryItem[]>;
  saveHistory(history: HistoryItem[]): Promise<void>;
  
  // App State
  loadAppState(): Promise<AppState | null>;
  saveAppState(state: AppState): Promise<void>;
  
  // Utility
  initialize(): Promise<void>;
  backup(): Promise<void>;
}
```

### 4.2 File System Storage Service


```typescript
// src/services/storage/FileSystemStorageService.ts
import { appDataDir, join } from '@tauri-apps/api/path';
import { 
  readTextFile, 
  writeTextFile, 
  exists, 
  createDir,
  removeFile,
  readDir
} from '@tauri-apps/plugin-fs';
import type { IStorageService } from './IStorageService';

export class FileSystemStorageService implements IStorageService {
  private dataDir: string = '';
  private collectionsDir: string = '';
  private requestsDir: string = '';
  private saveQueue: Map<string, NodeJS.Timeout> = new Map();
  private readonly DEBOUNCE_MS = 500;

  async initialize(): Promise<void> {
    this.dataDir = await join(await appDataDir(), 'postmock');
    this.collectionsDir = await join(this.dataDir, 'collections');
    this.requestsDir = await join(this.dataDir, 'requests');
    
    // Create directories if they don't exist
    await this.ensureDir(this.dataDir);
    await this.ensureDir(this.collectionsDir);
    await this.ensureDir(this.requestsDir);
    await this.ensureDir(await join(this.dataDir, 'environments'));
    await this.ensureDir(await join(this.dataDir, 'history'));
    await this.ensureDir(await join(this.dataDir, 'backups'));
  }

  private async ensureDir(path: string): Promise<void> {
    if (!await exists(path)) {
      await createDir(path, { recursive: true });
    }
  }

  private debouncedSave(key: string, saveFn: () => Promise<void>): void {
    if (this.saveQueue.has(key)) {
      clearTimeout(this.saveQueue.get(key)!);
    }
    
    const timeout = setTimeout(async () => {
      try {
        await saveFn();
        this.saveQueue.delete(key);
      } catch (error) {
        console.error(`Failed to save ${key}:`, error);
      }
    }, this.DEBOUNCE_MS);
    
    this.saveQueue.set(key, timeout);
  }

  async loadCollections(): Promise<Collection[]> {
    try {
      const entries = await readDir(this.collectionsDir);
      const collections: Collection[] = [];
      
      for (const entry of entries) {
        if (entry.name.endsWith('.json')) {
          const filePath = await join(this.collectionsDir, entry.name);
          const content = await readTextFile(filePath);
          collections.push(JSON.parse(content));
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
      await writeTextFile(filePath, JSON.stringify(collection, null, 2));
    });
  }

  async deleteCollection(id: string): Promise<void> {
    const filePath = await join(this.collectionsDir, `${id}.json`);
    if (await exists(filePath)) {
      await removeFile(filePath);
    }
  }

  async loadRequest(id: string): Promise<Request | null> {
    try {
      const filePath = await join(this.requestsDir, `${id}.json`);
      if (await exists(filePath)) {
        const content = await readTextFile(filePath);
        return JSON.parse(content);
      }
      return null;
    } catch (error) {
      console.error(`Failed to load request ${id}:`, error);
      return null;
    }
  }

  async saveRequest(request: Request): Promise<void> {
    const filePath = await join(this.requestsDir, `${request.id}.json`);
    this.debouncedSave(`request-${request.id}`, async () => {
      await writeTextFile(filePath, JSON.stringify(request, null, 2));
    });
  }

  async deleteRequest(id: string): Promise<void> {
    const filePath = await join(this.requestsDir, `${id}.json`);
    if (await exists(filePath)) {
      await removeFile(filePath);
    }
  }

  // ... other methods implementation
}
```

### 4.3 Import/Export Service


```typescript
// src/services/import-export/ImportExportService.ts
import { save, open } from '@tauri-apps/plugin-dialog';
import { writeTextFile, readTextFile } from '@tauri-apps/plugin-fs';

export interface ExportFormat {
  version: string;
  type: 'postmock-collection';
  exportedAt: string;
  collection: Collection;
  requests: Request[];
}

export class ImportExportService {
  async exportCollection(collection: Collection, requests: Request[]): Promise<void> {
    const exportData: ExportFormat = {
      version: '1.0.0',
      type: 'postmock-collection',
      exportedAt: new Date().toISOString(),
      collection,
      requests
    };

    const filePath = await save({
      defaultPath: `${collection.name}.postmock.json`,
      filters: [{
        name: 'Postmock Collection',
        extensions: ['json']
      }]
    });

    if (filePath) {
      await writeTextFile(filePath, JSON.stringify(exportData, null, 2));
    }
  }

  async importCollection(): Promise<{ collection: Collection; requests: Request[] } | null> {
    const filePath = await open({
      multiple: false,
      filters: [{
        name: 'Postmock Collection',
        extensions: ['json']
      }]
    });

    if (!filePath) return null;

    try {
      const content = await readTextFile(filePath as string);
      const data: ExportFormat = JSON.parse(content);

      // Validate format
      if (data.type !== 'postmock-collection') {
        throw new Error('Invalid file format');
      }

      // Generate new IDs to avoid conflicts
      const idMap = new Map<string, string>();
      const newCollection = this.remapCollectionIds(data.collection, idMap);
      const newRequests = data.requests.map(req => this.remapRequestIds(req, idMap));

      return { collection: newCollection, requests: newRequests };
    } catch (error) {
      console.error('Failed to import collection:', error);
      throw error;
    }
  }

  private remapCollectionIds(collection: Collection, idMap: Map<string, string>): Collection {
    const newId = generateId();
    idMap.set(collection.id, newId);

    return {
      ...collection,
      id: newId,
      folders: collection.folders.map(f => this.remapFolderIds(f, idMap)),
      requests: collection.requests.map(r => ({
        ...r,
        id: idMap.get(r.id) || generateId()
      })),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  }

  private remapFolderIds(folder: Folder, idMap: Map<string, string>): Folder {
    const newId = generateId();
    idMap.set(folder.id, newId);

    return {
      ...folder,
      id: newId,
      folders: folder.folders.map(f => this.remapFolderIds(f, idMap)),
      requests: folder.requests.map(r => ({
        ...r,
        id: idMap.get(r.id) || generateId()
      }))
    };
  }

  private remapRequestIds(request: Request, idMap: Map<string, string>): Request {
    const oldId = request.id;
    const newId = idMap.get(oldId) || generateId();
    
    return {
      ...request,
      id: newId,
      collectionId: request.collectionId ? idMap.get(request.collectionId) : undefined,
      folderId: request.folderId ? idMap.get(request.folderId) : undefined,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  }
}
```

## 5. Component Integration

### 5.1 App.vue Integration


```typescript
// src/App.vue
<script setup>
import { onMounted, onBeforeUnmount } from 'vue';
import { useCollectionsStore } from '@/stores/collections';
import { useRequestsStore } from '@/stores/requests';
import { useEnvironmentsStore } from '@/stores/environments';
import { useHistoryStore } from '@/stores/history';
import { useAppStateStore } from '@/stores/appState';
import { storageService } from '@/services/storage';

const collectionsStore = useCollectionsStore();
const requestsStore = useRequestsStore();
const environmentsStore = useEnvironmentsStore();
const historyStore = useHistoryStore();
const appStateStore = useAppStateStore();

onMounted(async () => {
  try {
    // Initialize storage service
    await storageService.initialize();
    
    // Load all data
    await Promise.all([
      collectionsStore.loadCollections(),
      environmentsStore.loadEnvironments(),
      historyStore.loadHistory(),
      appStateStore.loadState()
    ]);
    
    // Restore app state
    await appStateStore.restoreState();
  } catch (error) {
    console.error('Failed to initialize app:', error);
    // Show error notification
  }
});

onBeforeUnmount(async () => {
  // Save app state before closing
  await appStateStore.saveState();
});
</script>
```

### 5.2 CollectionsPanel Integration


```typescript
// src/components/CollectionsPanel.vue (refactored)
<script setup>
import { computed } from 'vue';
import { storeToRefs } from 'pinia';
import { useCollectionsStore } from '@/stores/collections';
import { ImportExportService } from '@/services/import-export';

const collectionsStore = useCollectionsStore();
const { collections, isLoading } = storeToRefs(collectionsStore);
const importExportService = new ImportExportService();

// Replace local collections ref with store
// const collections = ref([]); // REMOVE THIS

// Update methods to use store
const createCollection = async (name: string) => {
  await collectionsStore.createCollection(name);
};

const updateCollection = async (id: string, updates: any) => {
  await collectionsStore.updateCollection(id, updates);
};

const deleteCollection = async (id: string) => {
  await collectionsStore.deleteCollection(id);
};

// Export/Import handlers
const handleExport = async (collection: Collection) => {
  try {
    const requests = await loadCollectionRequests(collection);
    await importExportService.exportCollection(collection, requests);
    showToast('success', 'Collection exported successfully');
  } catch (error) {
    showToast('error', 'Failed to export collection');
  }
};

const handleImport = async () => {
  try {
    const result = await importExportService.importCollection();
    if (result) {
      // Save imported collection and requests
      await collectionsStore.createCollection(result.collection);
      for (const request of result.requests) {
        await requestsStore.saveRequest(request);
      }
      showToast('success', 'Collection imported successfully');
    }
  } catch (error) {
    showToast('error', 'Failed to import collection');
  }
};
</script>
```

## 6. Data Flow

### 6.1 Create Request Flow


```
User Action (Create Request)
    ↓
MainContent.createNewRequest()
    ↓
requestsStore.saveRequest(newRequest)
    ↓
storageService.saveRequest(newRequest)
    ↓
Debounced Write to File System
    ↓
collectionsStore.addRequestReference(collectionId, requestRef)
    ↓
storageService.saveCollection(collection)
    ↓
File System Updated
```

### 6.2 Load Request Flow

```
User Action (Open Request)
    ↓
MainContent.handleOpenRequest(requestData)
    ↓
requestsStore.loadRequest(requestId)
    ↓
Check Cache (Map)
    ├─ Hit: Return from cache
    └─ Miss: Load from storage
        ↓
    storageService.loadRequest(requestId)
        ↓
    Read from File System
        ↓
    Cache in Store
        ↓
    Return Request
```

### 6.3 Export Collection Flow

```
User Action (Export Collection)
    ↓
CollectionsPanel.handleExport(collection)
    ↓
Load all requests in collection
    ↓
importExportService.exportCollection(collection, requests)
    ↓
Show Save Dialog
    ↓
User selects file path
    ↓
Write JSON to selected path
    ↓
Show success notification
```

## 7. Error Handling Strategy

### 7.1 Error Types


```typescript
// src/types/errors.ts
export class StorageError extends Error {
  constructor(message: string, public code: string, public details?: any) {
    super(message);
    this.name = 'StorageError';
  }
}

export enum ErrorCode {
  FILE_NOT_FOUND = 'FILE_NOT_FOUND',
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  DISK_FULL = 'DISK_FULL',
  INVALID_FORMAT = 'INVALID_FORMAT',
  CORRUPTED_DATA = 'CORRUPTED_DATA',
  NETWORK_ERROR = 'NETWORK_ERROR'
}
```

### 7.2 Error Handling Pattern

```typescript
// In Store
async function saveRequest(request: Request) {
  try {
    await storageService.saveRequest(request);
  } catch (error) {
    if (error instanceof StorageError) {
      switch (error.code) {
        case ErrorCode.DISK_FULL:
          showNotification('error', 'Disk space full. Please free up space.');
          break;
        case ErrorCode.PERMISSION_DENIED:
          showNotification('error', 'Permission denied. Check file permissions.');
          break;
        default:
          showNotification('error', 'Failed to save request.');
      }
    }
    throw error; // Re-throw for caller to handle
  }
}
```

### 7.3 Backup and Recovery

```typescript
// src/services/backup/BackupService.ts
export class BackupService {
  private readonly MAX_BACKUPS = 3;
  
  async createBackup(): Promise<void> {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupDir = await join(await appDataDir(), 'postmock', 'backups', timestamp);
    
    // Copy all data files to backup directory
    await this.copyDirectory(this.dataDir, backupDir);
    
    // Clean old backups
    await this.cleanOldBackups();
  }
  
  async restoreFromBackup(backupId: string): Promise<void> {
    const backupDir = await join(await appDataDir(), 'postmock', 'backups', backupId);
    
    // Restore all files from backup
    await this.copyDirectory(backupDir, this.dataDir);
    
    // Reload all stores
    await this.reloadAllStores();
  }
  
  private async cleanOldBackups(): Promise<void> {
    const backupsDir = await join(await appDataDir(), 'postmock', 'backups');
    const entries = await readDir(backupsDir);
    
    if (entries.length > this.MAX_BACKUPS) {
      // Sort by date and remove oldest
      const sorted = entries.sort((a, b) => a.name.localeCompare(b.name));
      const toRemove = sorted.slice(0, entries.length - this.MAX_BACKUPS);
      
      for (const entry of toRemove) {
        await removeDir(await join(backupsDir, entry.name), { recursive: true });
      }
    }
  }
}
```

## 8. Migration Strategy

### 8.1 Version Detection


```typescript
// src/services/migration/MigrationService.ts
export class MigrationService {
  private readonly CURRENT_VERSION = '1.0.0';
  
  async checkAndMigrate(): Promise<void> {
    const versionFile = await join(this.dataDir, 'version.json');
    
    let currentVersion = '0.0.0';
    if (await exists(versionFile)) {
      const content = await readTextFile(versionFile);
      currentVersion = JSON.parse(content).version;
    }
    
    if (currentVersion !== this.CURRENT_VERSION) {
      await this.migrate(currentVersion, this.CURRENT_VERSION);
      await writeTextFile(versionFile, JSON.stringify({ version: this.CURRENT_VERSION }));
    }
  }
  
  private async migrate(from: string, to: string): Promise<void> {
    console.log(`Migrating data from ${from} to ${to}`);
    
    // Create backup before migration
    await backupService.createBackup();
    
    // Apply migrations in sequence
    const migrations = this.getMigrations(from, to);
    for (const migration of migrations) {
      await migration.apply();
    }
  }
  
  private getMigrations(from: string, to: string): Migration[] {
    // Return list of migrations to apply
    return [];
  }
}
```

## 9. Performance Optimizations

### 9.1 Lazy Loading

```typescript
// Only load request details when needed
const openRequest = async (requestId: string) => {
  const request = await requestsStore.loadRequest(requestId);
  // Request is now cached in store
};
```

### 9.2 Debounced Saves

```typescript
// Avoid excessive file writes
private debouncedSave(key: string, saveFn: () => Promise<void>): void {
  if (this.saveQueue.has(key)) {
    clearTimeout(this.saveQueue.get(key)!);
  }
  
  const timeout = setTimeout(async () => {
    await saveFn();
    this.saveQueue.delete(key);
  }, this.DEBOUNCE_MS);
  
  this.saveQueue.set(key, timeout);
}
```

### 9.3 Batch Operations

```typescript
// Save multiple items in one operation
async function saveMultipleRequests(requests: Request[]): Promise<void> {
  await Promise.all(requests.map(r => this.saveRequest(r)));
}
```

## 10. Testing Strategy

### 10.1 Unit Tests

```typescript
// Test storage service
describe('FileSystemStorageService', () => {
  it('should save and load collection', async () => {
    const collection = createTestCollection();
    await service.saveCollection(collection);
    const loaded = await service.loadCollections();
    expect(loaded).toContainEqual(collection);
  });
  
  it('should handle file not found error', async () => {
    await expect(service.loadRequest('non-existent')).resolves.toBeNull();
  });
});
```

### 10.2 Integration Tests

```typescript
// Test store + service integration
describe('Collections Store', () => {
  it('should persist collection across store instances', async () => {
    const store1 = useCollectionsStore();
    await store1.createCollection('Test');
    
    const store2 = useCollectionsStore();
    await store2.loadCollections();
    
    expect(store2.collections).toHaveLength(1);
  });
});
```

## 11. Security Considerations

### 11.1 Sensitive Data Encryption

```typescript
// Encrypt sensitive fields before saving
import { encrypt, decrypt } from '@/utils/crypto';

async function saveRequest(request: Request): Promise<void> {
  const sanitized = {
    ...request,
    auth: {
      ...request.auth,
      token: request.auth.token ? encrypt(request.auth.token) : '',
      password: request.auth.password ? encrypt(request.auth.password) : ''
    }
  };
  
  await writeTextFile(filePath, JSON.stringify(sanitized, null, 2));
}
```

### 11.2 Export Sanitization

```typescript
// Option to exclude sensitive data from exports
async function exportCollection(
  collection: Collection, 
  requests: Request[],
  options: { excludeSensitive: boolean }
): Promise<void> {
  if (options.excludeSensitive) {
    requests = requests.map(r => ({
      ...r,
      auth: { type: 'none', token: '', username: '', password: '' }
    }));
  }
  
  // ... export logic
}
```

## 12. Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Create type definitions
- [ ] Implement IStorageService interface
- [ ] Implement FileSystemStorageService
- [ ] Add error handling utilities
- [ ] Create backup service

### Phase 2: Store Layer
- [ ] Create Collections store
- [ ] Create Requests store
- [ ] Create Environments store
- [ ] Create History store
- [ ] Create AppState store

### Phase 3: Component Integration
- [ ] Refactor App.vue for data loading
- [ ] Refactor CollectionsPanel to use store
- [ ] Refactor MainContent to use store
- [ ] Refactor HttpRequest to use store
- [ ] Refactor EnvironmentManager to use store

### Phase 4: Import/Export
- [ ] Implement ImportExportService
- [ ] Add export UI to CollectionsPanel
- [ ] Add import UI to CollectionsPanel
- [ ] Add file format validation
- [ ] Add progress indicators

### Phase 5: Testing & Polish
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Add error notifications
- [ ] Add loading states
- [ ] Performance testing
- [ ] Documentation

## 13. API Reference

### Storage Service API

```typescript
interface IStorageService {
  initialize(): Promise<void>;
  loadCollections(): Promise<Collection[]>;
  saveCollection(collection: Collection): Promise<void>;
  deleteCollection(id: string): Promise<void>;
  loadRequest(id: string): Promise<Request | null>;
  saveRequest(request: Request): Promise<void>;
  deleteRequest(id: string): Promise<void>;
  backup(): Promise<void>;
}
```

### Store API

```typescript
// Collections Store
interface CollectionsStore {
  collections: Ref<Collection[]>;
  isLoading: Ref<boolean>;
  error: Ref<string | null>;
  loadCollections(): Promise<void>;
  createCollection(name: string): Promise<Collection>;
  updateCollection(id: string, updates: Partial<Collection>): Promise<void>;
  deleteCollection(id: string): Promise<void>;
}

// Requests Store
interface RequestsStore {
  requests: Ref<Map<string, Request>>;
  loadRequest(id: string): Promise<Request | undefined>;
  saveRequest(request: Request): Promise<void>;
  deleteRequest(id: string): Promise<void>;
  clearCache(): void;
}
```

## 14. File Structure

```
src/
├── types/
│   ├── models.ts
│   └── errors.ts
├── stores/
│   ├── collections.ts
│   ├── requests.ts
│   ├── environments.ts
│   ├── history.ts
│   └── appState.ts
├── services/
│   ├── storage/
│   │   ├── IStorageService.ts
│   │   ├── FileSystemStorageService.ts
│   │   └── index.ts
│   ├── import-export/
│   │   ├── ImportExportService.ts
│   │   └── index.ts
│   ├── backup/
│   │   ├── BackupService.ts
│   │   └── index.ts
│   └── migration/
│       ├── MigrationService.ts
│       └── index.ts
└── utils/
    ├── crypto.ts
    ├── id-generator.ts
    └── debounce.ts
```
