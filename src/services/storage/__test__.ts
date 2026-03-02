// Quick test for storage service
// This file can be imported in a component to test the storage service

import { storageService } from './index';
import { generateId } from '@/utils/id-generator';
import type { Collection, Request } from '@/types/models';

export async function testStorageService() {
  console.log('=== Testing Storage Service ===');
  
  try {
    // 1. Initialize
    console.log('1. Initializing storage service...');
    await storageService.initialize();
    console.log('✓ Storage service initialized');

    // 2. Test Collection Save/Load
    console.log('\n2. Testing Collection save/load...');
    const testCollection: Collection = {
      id: generateId(),
      name: 'Test Collection',
      description: 'A test collection',
      folders: [],
      requests: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    await storageService.saveCollection(testCollection);
    console.log('✓ Collection saved:', testCollection.id);
    
    // Wait for debounce
    await new Promise(resolve => setTimeout(resolve, 600));
    
    const loadedCollections = await storageService.loadCollections();
    console.log('✓ Collections loaded:', loadedCollections.length);
    
    const found = loadedCollections.find(c => c.id === testCollection.id);
    if (found) {
      console.log('✓ Test collection found:', found.name);
    } else {
      console.error('✗ Test collection not found!');
    }

    // 3. Test Request Save/Load
    console.log('\n3. Testing Request save/load...');
    const testRequest: Request = {
      id: generateId(),
      name: 'Test Request',
      method: 'GET',
      url: 'https://api.example.com/test',
      params: [],
      headers: [],
      body: {
        type: 'none',
        raw: '',
        formData: [],
        urlencoded: []
      },
      auth: {
        type: 'none',
        token: '',
        username: '',
        password: ''
      },
      tests: {
        statusCodeTests: [],
        jsonFieldTests: [],
        globalVariables: []
      },
      collectionId: testCollection.id,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    await storageService.saveRequest(testRequest);
    console.log('✓ Request saved:', testRequest.id);
    
    // Wait for debounce
    await new Promise(resolve => setTimeout(resolve, 600));
    
    const loadedRequest = await storageService.loadRequest(testRequest.id);
    if (loadedRequest) {
      console.log('✓ Request loaded:', loadedRequest.name);
    } else {
      console.error('✗ Request not found!');
    }

    // 4. Test Environments
    console.log('\n4. Testing Environments save/load...');
    const testEnvironments = [
      {
        id: generateId(),
        name: 'Development',
        variables: [
          { key: 'API_URL', value: 'http://localhost:3000', enabled: true }
        ],
        isActive: true
      }
    ];
    
    await storageService.saveEnvironments(testEnvironments);
    console.log('✓ Environments saved');
    
    const loadedEnvs = await storageService.loadEnvironments();
    console.log('✓ Environments loaded:', loadedEnvs.length);

    // 5. Test AppState
    console.log('\n5. Testing AppState save/load...');
    const testAppState = {
      openRequests: [testRequest.id],
      activeRequestIndex: 0,
      sidebarWidth: 320,
      footerHeight: 200,
      lastSavedAt: new Date().toISOString()
    };
    
    await storageService.saveAppState(testAppState);
    console.log('✓ AppState saved');
    
    const loadedState = await storageService.loadAppState();
    if (loadedState) {
      console.log('✓ AppState loaded, open requests:', loadedState.openRequests.length);
    }

    // 6. Test Cleanup
    console.log('\n6. Testing cleanup...');
    await storageService.deleteRequest(testRequest.id);
    console.log('✓ Request deleted');
    
    await storageService.deleteCollection(testCollection.id);
    console.log('✓ Collection deleted');

    console.log('\n=== All tests passed! ===');
    return true;
  } catch (error) {
    console.error('✗ Test failed:', error);
    return false;
  }
}
