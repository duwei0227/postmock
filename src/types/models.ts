// Core data models for Postmock

export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD' | 'OPTIONS';

export interface KeyValue {
  key: string;
  value: string;
  enabled: boolean;
}

export interface RequestBody {
  type: 'none' | 'json' | 'form-data' | 'x-www-form-urlencoded';
  raw: string;
  formData: FormDataItem[];
  urlencoded: KeyValue[];
}

export interface FormDataItem {
  key: string;
  value: string;
  type: 'text' | 'file';
  enabled: boolean;
  file?: File;
}

export interface AuthConfig {
  type: 'none' | 'bearer' | 'basic';
  token: string;
  username: string;
  password: string;
}

export interface TestConfig {
  statusCodeTests: StatusCodeTest[];
  jsonFieldTests: JsonFieldTest[];
  globalVariables: GlobalVariableConfig[];
}

export interface StatusCodeTest {
  enabled: boolean;
  operator: string;
  expectedValue: string;
  description: string;
}

export interface JsonFieldTest {
  enabled: boolean;
  jsonPath: string;
  operator: string;
  expectedValue: string;
  description: string;
}


export interface GlobalVariableConfig {
  enabled: boolean;
  variableName: string;
  valueType: 'jsonPath' | 'customValue';
  jsonPath: string;
  customValue: string;
  description: string;
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

export interface Folder {
  id: string;
  name: string;
  description?: string;
  folders: Folder[];
  requests: RequestReference[];
}

export interface Collection {
  id: string;
  name: string;
  description?: string;
  folders: Folder[];
  requests: RequestReference[];
  createdAt: string;
  updatedAt: string;
}

export interface EnvironmentVariable {
  key: string;
  value: string;
  enabled: boolean;
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
