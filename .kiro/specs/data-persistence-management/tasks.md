# Data Persistence and Management System - Tasks

## Phase 1: Core Infrastructure Setup

### 1.1 Setup Project Dependencies
- [ ] Install Pinia for state management
  ```bash
  npm install pinia
  ```
- [ ] Install Tauri file system plugin
  ```bash
  npm install @tauri-apps/plugin-fs
  ```
- [ ] Install Tauri dialog plugin
  ```bash
  npm install @tauri-apps/plugin-dialog
  ```
- [ ] Update Tauri permissions in capabilities/default.json

### 1.2 Create Type Definitions
- [ ] Create `src/types/models.ts`
  - [ ] Define Collection interface
  - [ ] Define Folder interface
  - [ ] Define Request interface
  - [ ] Define RequestReference interface
  - [ ] Define Environment interface
  - [ ] Define EnvironmentVariable interface
  - [ ] Define HistoryItem interface
  - [ ] Define AppState interface
  - [ ] Define KeyValue interface
  - [ ] Define RequestBody interface
  - [ ] Define AuthConfig interface
  - [ ] Define TestConfig interface
  - [ ] Define HttpMethod type

- [ ] Create `src/types/errors.ts`
  - [ ] Define StorageError class
  - [ ] Define ErrorCode enum
  - [ ] Define error handling types

### 1.3 Create Utility Functions
- [ ] Create `src/utils/id-generator.ts`
  - [ ] Implement generateId() function using nanoid or UUID

- [ ] Create `src/utils/debounce.ts`
  - [ ] Implement debounce utility function

- [ ] Create `src/utils/crypto.ts` (optional for sensitive data)
  - [ ] Implement encrypt() function
  - [ ] Implement decrypt() function

## Phase 2: Service Layer Implementation

### 2.1 Storage Service Interface
- [ ] Create `src/services/storage/IStorageService.ts`
  - [ ] Define IStorageService interface with all methods
  - [ ] Add JSDoc comments for each method

### 2.2 File System Storage Service
- [ ] Create `src/services/storage/FileSystemStorageService.ts`
  - [ ] Implement initialize() method
    - [ ] Get appDataDir path
    - [ ] Create directory structure
    - [ ] Handle directory creation errors
  
  - [ ] Implement ensureDir() helper method
  
  - [ ] Implement debouncedSave() helper method
    - [ ] Use Map to track pending saves
    - [ ] Clear existing timeout if exists
    - [ ] Set new timeout with save function
  
  - [ ] Implement Collections methods
    - [ ] loadCollections(): Read all collection files
    - [ ] saveCollection(): Write collection with debounce
    - [ ] deleteCollection(): Remove collection file
  
  - [ ] Implement Requests methods
    - [ ] loadRequest(): Read single request file
    - [ ] saveRequest(): Write request with debounce
    - [ ] deleteRequest(): Remove request file
  
  - [ ] Implement Environments methods
    - [ ] loadEnvironments(): Read environments.json
    - [ ] saveEnvironments(): Write environments.json
  
  - [ ] Implement History methods
    - [ ] loadHistory(): Read history.json
    - [ ] saveHistory(): Write history.json with size limit
  
  - [ ] Implement AppState methods
    - [ ] loadAppState(): Read app-state.json
    - [ ] saveAppState(): Write app-state.json
  
  - [ ] Implement backup() method
    - [ ] Create backup directory with timestamp
    - [ ] Copy all data files to backup

- [ ] Create `src/services/storage/index.ts`
  - [ ] Export storageService singleton instance
  - [ ] Initialize on first import

### 2.3 Import/Export Service
- [ ] Create `src/services/import-export/ImportExportService.ts`
  - [ ] Define ExportFormat interface
  
  - [ ] Implement exportCollection() method
    - [ ] Create export data structure
    - [ ] Show save dialog
    - [ ] Write JSON to selected file
    - [ ] Handle errors
  
  - [ ] Implement importCollection() method
    - [ ] Show open dialog
    - [ ] Read and parse JSON file
    - [ ] Validate file format and version
    - [ ] Remap IDs to avoid conflicts
    - [ ] Return collection and requests
  
  - [ ] Implement remapCollectionIds() helper
    - [ ] Generate new collection ID
    - [ ] Recursively remap folder IDs
    - [ ] Remap request references
  
  - [ ] Implement remapFolderIds() helper
    - [ ] Generate new folder ID
    - [ ] Recursively process nested folders
  
  - [ ] Implement remapRequestIds() helper
    - [ ] Generate new request ID
    - [ ] Update collectionId and folderId references

- [ ] Create `src/services/import-export/index.ts`
  - [ ] Export ImportExportService class

### 2.4 Backup Service
- [ ] Create `src/services/backup/BackupService.ts`
  - [ ] Implement createBackup() method
    - [ ] Create timestamped backup directory
    - [ ] Copy all data files
    - [ ] Clean old backups (keep last 3)
  
  - [ ] Implement restoreFromBackup() method
    - [ ] Copy files from backup to data directory
    - [ ] Reload all stores
  
  - [ ] Implement listBackups() method
    - [ ] Read backup directory
    - [ ] Return list of available backups
  
  - [ ] Implement cleanOldBackups() helper
    - [ ] Sort backups by date
    - [ ] Remove oldest backups beyond limit

- [ ] Create `src/services/backup/index.ts`
  - [ ] Export backupService singleton

### 2.5 Migration Service
- [ ] Create `src/services/migration/MigrationService.ts`
  - [ ] Implement checkAndMigrate() method
    - [ ] Read version.json
    - [ ] Compare with current version
    - [ ] Run migrations if needed
  
  - [ ] Implement migrate() method
    - [ ] Create backup before migration
    - [ ] Apply migrations in sequence
    - [ ] Update version file
  
  - [ ] Implement getMigrations() helper
    - [ ] Return list of migrations to apply

- [ ] Create `src/services/migration/index.ts`
  - [ ] Export migrationService singleton

## Phase 3: Store Layer Implementation

### 3.1 Setup Pinia
- [ ] Update `src/main.js`
  - [ ] Import and create Pinia instance
  - [ ] Register Pinia with Vue app

### 3.2 Collections Store
- [ ] Create `src/stores/collections.ts`
  - [ ] Define store with defineStore
  - [ ] Add state: collections, isLoading, error
  
  - [ ] Implement getters
    - [ ] getCollectionById
    - [ ] getCollectionByName
  
  - [ ] Implement actions
    - [ ] loadCollections(): Load from storage service
    - [ ] createCollection(): Create and save new collection
    - [ ] updateCollection(): Update and save collection
    - [ ] deleteCollection(): Delete from store and storage
    - [ ] addFolder(): Add folder to collection
    - [ ] updateFolder(): Update folder in collection
    - [ ] deleteFolder(): Remove folder from collection
    - [ ] addRequestReference(): Add request ref to collection/folder
    - [ ] removeRequestReference(): Remove request ref
    - [ ] moveRequest(): Move request between folders
  
  - [ ] Add error handling for all actions
  - [ ] Add loading states

### 3.3 Requests Store
- [ ] Create `src/stores/requests.ts`
  - [ ] Define store with defineStore
  - [ ] Add state: requests (Map), isLoading
  
  - [ ] Implement getters
    - [ ] getRequestById
    - [ ] getRequestsByCollectionId
  
  - [ ] Implement actions
    - [ ] loadRequest(): Load single request (with caching)
    - [ ] loadMultipleRequests(): Batch load requests
    - [ ] saveRequest(): Save request to storage
    - [ ] deleteRequest(): Delete from cache and storage
    - [ ] clearCache(): Clear all cached requests
  
  - [ ] Add error handling
  - [ ] Implement cache management

### 3.4 Environments Store
- [ ] Create `src/stores/environments.ts`
  - [ ] Define store with defineStore
  - [ ] Add state: environments, activeEnvironmentId, globalVariables
  
  - [ ] Implement getters
    - [ ] activeEnvironment
    - [ ] getAllAvailableVariables (merge global + active env)
  
  - [ ] Implement actions
    - [ ] loadEnvironments(): Load from storage
    - [ ] saveEnvironments(): Save to storage
    - [ ] createEnvironment(): Create new environment
    - [ ] updateEnvironment(): Update environment
    - [ ] deleteEnvironment(): Delete environment
    - [ ] setActiveEnvironment(): Set active environment
    - [ ] setGlobalVariable(): Set global variable
    - [ ] replaceVariables(): Replace {{var}} in strings
  
  - [ ] Add error handling

### 3.5 History Store
- [ ] Create `src/stores/history.ts`
  - [ ] Define store with defineStore
  - [ ] Add state: history, maxItems (default 100)
  
  - [ ] Implement getters
    - [ ] recentHistory (last N items)
    - [ ] getHistoryByRequestId
  
  - [ ] Implement actions
    - [ ] loadHistory(): Load from storage
    - [ ] addHistoryItem(): Add new item (with size limit)
    - [ ] clearHistory(): Clear all history
    - [ ] deleteHistoryItem(): Delete single item
  
  - [ ] Implement size limit enforcement
  - [ ] Add error handling

### 3.6 AppState Store
- [ ] Create `src/stores/appState.ts`
  - [ ] Define store with defineStore
  - [ ] Add state: openRequests, activeRequestIndex, sidebarWidth, etc.
  
  - [ ] Implement actions
    - [ ] loadState(): Load from storage
    - [ ] saveState(): Save to storage
    - [ ] restoreState(): Restore UI state
    - [ ] updateOpenRequests(): Update open requests list
    - [ ] setActiveRequest(): Set active request
  
  - [ ] Add debounced auto-save

## Phase 4: Component Integration

### 4.1 Update App.vue
- [ ] Import all stores
- [ ] Import storage service
- [ ] Add onMounted hook
  - [ ] Initialize storage service
  - [ ] Load all data from stores
  - [ ] Restore app state
  - [ ] Handle initialization errors
- [ ] Add onBeforeUnmount hook
  - [ ] Save app state
  - [ ] Flush pending saves
- [ ] Add error notification handling

### 4.2 Refactor CollectionsPanel.vue
- [ ] Import useCollectionsStore
- [ ] Import useRequestsStore
- [ ] Import ImportExportService
- [ ] Replace local collections ref with store
- [ ] Update all methods to use store actions
  - [ ] createCollection → store.createCollection
  - [ ] updateCollection → store.updateCollection
  - [ ] deleteCollection → store.deleteCollection
  - [ ] createFolder → store.addFolder
  - [ ] etc.
- [ ] Add export handler
  - [ ] Load all requests in collection
  - [ ] Call importExportService.exportCollection
  - [ ] Show success/error notification
- [ ] Add import handler
  - [ ] Call importExportService.importCollection
  - [ ] Save imported data to stores
  - [ ] Show success/error notification
- [ ] Add context menu items for export/import
- [ ] Add loading states
- [ ] Remove old localStorage code

### 4.3 Refactor MainContent.vue
- [ ] Import useCollectionsStore
- [ ] Import useRequestsStore
- [ ] Import useAppStateStore
- [ ] Replace local openRequests with store
- [ ] Update createNewRequest
  - [ ] Save request to store
  - [ ] Add reference to collection
- [ ] Update handleOpenRequest
  - [ ] Load request from store
  - [ ] Handle caching
- [ ] Update closeRequest
  - [ ] Update app state store
- [ ] Add auto-save for open requests state

### 4.4 Refactor HttpRequest.vue
- [ ] Import useRequestsStore
- [ ] Update request save logic
  - [ ] Save to store instead of emit
  - [ ] Debounce saves
- [ ] Add loading states
- [ ] Handle save errors

### 4.5 Refactor EnvironmentManager.vue
- [ ] Import useEnvironmentsStore
- [ ] Replace local state with store
- [ ] Update all methods to use store actions
- [ ] Add auto-save
- [ ] Remove old implementation

### 4.6 Update HistoryPanel.vue
- [ ] Import useHistoryStore
- [ ] Replace local state with store
- [ ] Update addToHistory to use store
- [ ] Add clear history button
- [ ] Add history size limit indicator

## Phase 5: UI Enhancements

### 5.1 Add Export/Import UI
- [ ] Add "Export Collection" menu item in CollectionsPanel context menu
- [ ] Add "Import Collection" button in CollectionsPanel toolbar
- [ ] Add export progress indicator
- [ ] Add import validation feedback
- [ ] Add import preview dialog (optional)

### 5.2 Add Loading States
- [ ] Add loading spinner in CollectionsPanel during load
- [ ] Add loading indicator in MainContent during request load
- [ ] Add saving indicator in HttpRequest
- [ ] Add global loading overlay for initialization

### 5.3 Add Error Notifications
- [ ] Create notification service/composable
- [ ] Add error toast for storage failures
- [ ] Add error toast for import/export failures
- [ ] Add retry mechanism for failed saves
- [ ] Add "View Details" button in error notifications

### 5.4 Add Settings UI (Optional)
- [ ] Add settings dialog
- [ ] Add history size limit setting
- [ ] Add auto-backup setting
- [ ] Add data location display
- [ ] Add "Clear All Data" button with confirmation

## Phase 6: Testing

### 6.1 Unit Tests
- [ ] Test FileSystemStorageService
  - [ ] Test initialize()
  - [ ] Test saveCollection() and loadCollections()
  - [ ] Test saveRequest() and loadRequest()
  - [ ] Test debounced saves
  - [ ] Test error handling
- [ ] Test ImportExportService
  - [ ] Test exportCollection()
  - [ ] Test importCollection()
  - [ ] Test ID remapping
  - [ ] Test format validation
- [ ] Test BackupService
  - [ ] Test createBackup()
  - [ ] Test restoreFromBackup()
  - [ ] Test cleanOldBackups()
- [ ] Test Stores
  - [ ] Test Collections store actions
  - [ ] Test Requests store caching
  - [ ] Test Environments store variable replacement
  - [ ] Test History store size limit

### 6.2 Integration Tests
- [ ] Test full save/load cycle
  - [ ] Create collection → Close app → Reopen → Verify data
- [ ] Test export/import cycle
  - [ ] Export collection → Import → Verify data integrity
- [ ] Test error recovery
  - [ ] Simulate disk full → Verify error handling
  - [ ] Simulate corrupted file → Verify backup restore
- [ ] Test migration
  - [ ] Test version upgrade path

### 6.3 Manual Testing
- [ ] Test with large collections (1000+ requests)
- [ ] Test concurrent saves
- [ ] Test app crash recovery
- [ ] Test import of Postman collections (if supported)
- [ ] Test on different OS (Windows, macOS, Linux)

## Phase 7: Documentation and Polish

### 7.1 Code Documentation
- [ ] Add JSDoc comments to all public APIs
- [ ] Add inline comments for complex logic
- [ ] Create README for services directory
- [ ] Document data file formats

### 7.2 User Documentation
- [ ] Create user guide for export/import
- [ ] Document data location
- [ ] Document backup/restore process
- [ ] Add troubleshooting guide

### 7.3 Performance Optimization
- [ ] Profile app startup time
- [ ] Optimize large collection loading
- [ ] Implement virtual scrolling if needed
- [ ] Optimize debounce timings

### 7.4 Final Polish
- [ ] Review all error messages for clarity
- [ ] Add keyboard shortcuts for export/import
- [ ] Add drag-and-drop import support
- [ ] Add recent files list
- [ ] Add data statistics display

## Phase 8: Deployment

### 8.1 Pre-release Checklist
- [ ] All tests passing
- [ ] No console errors
- [ ] Performance benchmarks met
- [ ] Documentation complete
- [ ] Backup existing user data

### 8.2 Migration Plan
- [ ] Create migration script for existing users
- [ ] Test migration on sample data
- [ ] Prepare rollback plan
- [ ] Create backup before first run

### 8.3 Release
- [ ] Update version number
- [ ] Create release notes
- [ ] Tag release in git
- [ ] Deploy to users

## Notes

### Priority Levels
- **P0 (Critical)**: Core persistence functionality
- **P1 (High)**: Export/import, error handling
- **P2 (Medium)**: Backup/restore, optimization
- **P3 (Low)**: Advanced features, polish

### Estimated Timeline
- Phase 1-2: 2-3 days (Core infrastructure)
- Phase 3: 2-3 days (Store layer)
- Phase 4: 3-4 days (Component integration)
- Phase 5: 1-2 days (UI enhancements)
- Phase 6: 2-3 days (Testing)
- Phase 7-8: 1-2 days (Documentation and deployment)

**Total: ~12-17 days**

### Dependencies
- Tauri file system plugin must be properly configured
- Pinia must be set up before store implementation
- Type definitions must be complete before service implementation
- Services must be tested before component integration
