import { save, open } from '@tauri-apps/plugin-dialog';
import { writeTextFile, readTextFile } from '@tauri-apps/plugin-fs';
import type { Collection, Request } from '@/types/models';
import { generateId } from '@/utils/id-generator';

export interface ExportFormat {
  version: string;
  exportedAt: string;
  collection: Collection;
  requests: Request[];
}

export class ImportExportService {
  private readonly EXPORT_VERSION = '1.0.0';

  async exportCollection(
    collection: Collection,
    requests: Request[]
  ): Promise<void> {
    try {
      // Create export data
      const exportData: ExportFormat = {
        version: this.EXPORT_VERSION,
        exportedAt: new Date().toISOString(),
        collection,
        requests
      };

      // Show save dialog
      const filePath = await save({
        defaultPath: `${collection.name}.json`,
        filters: [{
          name: 'JSON',
          extensions: ['json']
        }]
      });

      if (!filePath) {
        return; // User cancelled
      }

      // Write to file
      await writeTextFile(filePath, JSON.stringify(exportData, null, 2));

      console.log('Collection exported successfully:', filePath);
    } catch (error) {
      console.error('Failed to export collection:', error);
      throw new Error('Failed to export collection');
    }
  }

  async importCollection(): Promise<{
    collection: Collection;
    requests: Request[];
  } | null> {
    try {
      // Show open dialog
      const filePath = await open({
        multiple: false,
        filters: [{
          name: 'JSON',
          extensions: ['json']
        }]
      });

      if (!filePath) {
        return null; // User cancelled
      }

      // Read file
      const content = await readTextFile(filePath as string);
      const importData = JSON.parse(content) as ExportFormat;

      // Validate format
      if (!this.validateImportData(importData)) {
        throw new Error('Invalid import file format');
      }

      // Remap IDs to avoid conflicts
      const { collection, requests } = this.remapIds(
        importData.collection,
        importData.requests
      );

      console.log('Collection imported successfully');
      return { collection, requests };
    } catch (error) {
      console.error('Failed to import collection:', error);
      throw new Error('Failed to import collection');
    }
  }

  private validateImportData(data: any): data is ExportFormat {
    return (
      data &&
      typeof data.version === 'string' &&
      typeof data.exportedAt === 'string' &&
      data.collection &&
      Array.isArray(data.requests)
    );
  }

  private remapIds(
    collection: Collection,
    requests: Request[]
  ): { collection: Collection; requests: Request[] } {
    const idMap = new Map<string, string>();
    const folderIdMap = new Map<string, string>();
    const requestIdMap = new Map<string, string>();

    // Generate new collection ID
    const newCollectionId = generateId();
    idMap.set(collection.id, newCollectionId);

    // First pass: generate all folder IDs
    const generateFolderIds = (folders: any[]) => {
      for (const folder of folders) {
        const newFolderId = generateId();
        folderIdMap.set(folder.id, newFolderId);
        if (folder.folders && folder.folders.length > 0) {
          generateFolderIds(folder.folders);
        }
      }
    };
    
    if (collection.folders && collection.folders.length > 0) {
      generateFolderIds(collection.folders);
    }

    // Second pass: generate all request IDs
    for (const request of requests) {
      const newRequestId = generateId();
      requestIdMap.set(request.id, newRequestId);
    }

    // Remap folders with new IDs
    const remapFolders = (folders: any[]): any[] => {
      return folders.map(folder => ({
        ...folder,
        id: folderIdMap.get(folder.id) || folder.id,
        folders: folder.folders ? remapFolders(folder.folders) : [],
        requests: folder.requests ? folder.requests.map((req: any) => ({
          ...req,
          id: requestIdMap.get(req.id) || req.id
        })) : []
      }));
    };

    // Remap collection
    const newCollection: Collection = {
      ...collection,
      id: newCollectionId,
      folders: collection.folders ? remapFolders(collection.folders) : [],
      requests: collection.requests ? collection.requests.map(req => ({
        ...req,
        id: requestIdMap.get(req.id) || req.id
      })) : [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    // Remap requests
    const newRequests: Request[] = requests.map(request => ({
      ...request,
      id: requestIdMap.get(request.id) || request.id,
      collectionId: newCollectionId,
      folderId: request.folderId ? folderIdMap.get(request.folderId) || null : null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }));

    return { collection: newCollection, requests: newRequests };
  }
}

export const importExportService = new ImportExportService();
