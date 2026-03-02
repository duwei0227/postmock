# Postmock Codebase Instructions

## Project Overview
Postmock is a **Tauri desktop application** combining a **Vue 3 frontend** with a **Rust backend**. It uses **PrimeVue** for UI components, **Tailwind CSS** for styling, and **Vite** for bundling.

**Key Architecture**: Frontend-backend separation via Tauri's IPC (`invoke()` calls) - the Rust backend is the single source of truth.

## Product Goals & Requirements

### Primary Objectives
1. **Postman-like HTTP Client**: Provide an interface and functionality similar to Postman for initiating and managing HTTP requests
2. **Mock Server Simulation**: Extend the HTTP client with mock functionality to simulate server-defined interfaces, allowing developers to define and test API endpoints without a real backend

### Use Cases
- Send HTTP requests and inspect responses (like Postman)
- Define mock APIs with custom responses for local development and testing
- Single desktop application replacing separate HTTP client + mock server tools

## Development Workflow

### Starting Development
```bash
npm run tauri dev  # Runs both Vite dev server (port 1420) and Tauri app
```
- Vite serves Vue components with hot reload
- Tauri watches Rust code; recompiles on changes
- Frontend and backend run simultaneously in development

### Building
```bash
npm run tauri build  # Compiles frontend (→ dist/) then packages binary
```
- Frontend: `npm run build` creates optimized bundle in `dist/`
- Backend: Cargo compiles Rust code; result referenced in `tauri.conf.json` as `frontendDist`

### Project Commands
- `npm run dev` - Frontend-only dev server (no Tauri)
- `npm run build` - Frontend build only
- `npm run preview` - Preview built frontend locally
- `npm run tauri` - Run Tauri CLI directly

## Key File Locations

| Component | Path |
|-----------|------|
| **Rust backend** | `src-tauri/src/lib.rs` - Add Tauri commands here |
| **Frontend root** | `src/App.vue` - Main Vue component |
| **Backend config** | `src-tauri/tauri.conf.json` - App settings, window size, bundle config |
| **Frontend config** | `vite.config.js` - Vite + Vue setup; prevents Vite from watching `src-tauri/**` |
| **Styling** | `tailwind.config.js` - Tailwind + PrimeUI theme setup; `src/style.css` - global styles |
| **UI theme** | `src/presets/Noir.js` - Custom PrimeUI color preset (dark mode theme) |

## Communication Pattern: Frontend ↔ Backend

### Adding a Tauri Command (Rust → Frontend)
1. Define function in [src-tauri/src/lib.rs](src-tauri/src/lib.rs):
   ```rust
   #[tauri::command]
   fn my_command(param: &str) -> String {
       format!("Result: {}", param)
   }
   ```
2. Register in `invoke_handler!` macro in `run()` function
3. Call from Vue: `await invoke("my_command", { param: "value" })`

Example: [src-tauri/src/lib.rs](src-tauri/src/lib.rs) has `greet` command; [src/App.vue](src/App.vue) calls it via `invoke("greet", { name })`

### Frontend State Pattern
- Use Vue 3's `<script setup>` with `ref()` for reactive state
- PrimeVue components auto-import via `unplugin-vue-components` (no manual imports needed)
- Example: [src/App.vue](src/App.vue) uses `ref()` for form inputs

## Build Configuration Details

### Tauri Configuration [src-tauri/tauri.conf.json](src-tauri/tauri.conf.json)
- **beforeDevCommand**: `npm run dev` - Starts Vite dev server before Tauri dev
- **devUrl**: `http://localhost:1420` - Tauri loads this URL in dev mode
- **beforeBuildCommand**: `npm run build` - Builds frontend for release
- **frontendDist**: `../dist` - Path to built frontend (created by `npm run build`)
- **Window settings**: Default 800×600 desktop window

### Vite Specifics [vite.config.js](vite.config.js)
- **Port 1420**: Hard-coded and required by Tauri dev setup
- **Ignore rule**: `watch.ignored: ["**/src-tauri/**"]` - Prevents Vite from watching Rust code
- **HMR** (hot module replacement): Configured for Tauri dev environment
- **Component auto-import**: Configured to auto-import PrimeVue components from `unplugin-vue-components`

## Styling Convention

- **Tailwind + PrimeUI**: Tailwind handles utility classes; PrimeUI components styled via `tailwindcss-primeui` plugin
- **Dark mode**: Triggered by `.p-dark` class selector (set in [main.js](src/main.js) config)
- **Custom colors**: Edit [src/presets/Noir.js](src/presets/Noir.js) to modify theme

## Dependencies & Versions
- **Frontend**: Vue 3.5, Tauri API v2, PrimeVue 4.5, Tailwind 3, Vite 6
- **Backend**: Tauri 2, serde/serde_json (JSON serialization), tauri-plugin-opener
- **IDE**: VS Code with Volar (Vue), rust-analyzer, Tauri extension recommended

## Common Pitfalls

1. **Tauri command not registered**: Add to `invoke_handler!` macro in [src-tauri/src/lib.rs](src-tauri/src/lib.rs) `run()`
2. **Frontend not updating**: Run `npm run tauri dev` not `npm run dev` (latter lacks Rust backend)
3. **Build fails**: Ensure `npm run build` completes before `npm run tauri build`
4. **Port 1420 in use**: Vite requires this exact port; kill conflicting process or change `tauri.conf.json` devUrl
5. **Import paths**: Use `@` alias (resolves to `src/`) in frontend code per `vite.config.js`

## Testing & Debugging

- **Frontend**: Use Vue DevTools browser extension (in dev mode) to inspect component state
- **Backend**: Rust compiler output shows in Tauri dev terminal; use `println!` or `eprintln!` macros for debugging
- **IPC calls**: Check browser console (F12) for `invoke()` errors and responses

## Communication

- **Language**: Respond to user requests in Chinese (中文)
