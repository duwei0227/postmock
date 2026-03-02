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

    // Generate new collection ID
    const newCollectionId = generateId();
    idMap.set(collection.id, newCollectionId);

    // Remap collection
    const newCollection: Collection = {
      ...collection,
      id: newCollectionId,
      folders: this.remapFolderIds(collection.folders, idMap),
      requests: this.remapRequestReferences(collection.requests, idMap),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    // Remap requests
    const newRequests: Request[] = requests.map(request => {
      const newRequestId = generateId();
      idMap.set(request.id, newRequestId);

      return {
        ...request,
        id: newRequestId,
        collectionId: newCollectionId,
        folderId: request.folderId ? idMap.get(request.folderId) : undefined,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
    });

    return { collection: newCollection, requests: newRequests };
  }

  private remapFolderIds(
    folders: any[],
    idMap: Map<string, string>
  ): any[] {
    return folders.map(folder => {
      const newFolderId = generateId();
      idMap.set(folder.id, newFolderId);

      return {
        ...folder,
        id: newFolderId,
        folders: this.remapFolderIds(folder.folders || [], idMap),
        requests: this.remapRequestReferences(folder.requests || [], idMap)
      };
    });
  }

  private remapRequestReferences(
    requests: any[],
    idMap: Map<string, string>
  ): any[] {
    return requests.map(request => ({
      ...request,
      id: idMap.get(request.id) || request.id
    }));
  }
}

export const importExportService = new ImportExportService();
