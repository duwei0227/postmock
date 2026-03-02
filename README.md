# PostMock - API Testing Tool

A modern, desktop API testing tool built with Tauri + Vue 3.

## Features

- 🚀 **Fast & Lightweight** - Built with Tauri for native performance
- 💾 **Auto-Save** - All data automatically saved to local storage
- 📁 **Collections** - Organize requests in collections and folders
- 🌍 **Environments** - Manage multiple environments with variables
- 📜 **History** - Track all your API requests
- 🧪 **Tests** - Built-in testing and assertions
- 📤 **Import/Export** - Share collections with your team
- 🎨 **Dark Mode** - Beautiful dark theme

## Getting Started

### Prerequisites

- Node.js (v16 or higher)
- Rust (latest stable)
- npm or yarn

### Installation

```bash
# Install dependencies
npm install

# Run in development mode
npm run tauri dev

# Build for production
npm run tauri build
```

## Data Storage

All your data is stored locally on your machine:

- **Linux**: `~/.local/share/postmock/`
- **macOS**: `~/Library/Application Support/postmock/`
- **Windows**: `%APPDATA%\postmock\`

### Clean Data (Start Fresh)

If you want to remove all stored data and start fresh:

**Linux/macOS:**
```bash
./scripts/clean-data.sh
```

**Windows:**
```cmd
scripts\clean-data.bat
```

Or manually delete the data directory mentioned above.

## Usage

### Creating a Collection

1. Click "新建 Collection" in the Collections panel
2. Enter a name and description
3. Start adding requests

### Creating a Request

1. Click the "+" button in the toolbar
2. Or right-click a Collection and select "Add Request"
3. Configure your request (method, URL, params, headers, body)
4. Click "Send" to execute

### Using Environment Variables

1. Click the environment icon in the toolbar
2. Create a new environment
3. Add variables (key-value pairs)
4. Use variables in your requests: `{{variableName}}`

### Import/Export Collections

**Export:**
1. Right-click a Collection
2. Select "Export"
3. Choose save location

**Import:**
1. Click the upload icon in Collections panel
2. Select a JSON file
3. Collection will be imported automatically

## Documentation

- [User Guide](USER_GUIDE.md) - Detailed usage instructions
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md) - Technical details

## Recommended IDE Setup

- [VS Code](https://code.visualstudio.com/) + [Vue - Official](https://marketplace.visualstudio.com/items?itemName=Vue.volar) + [Tauri](https://marketplace.visualstudio.com/items?itemName=tauri-apps.tauri-vscode) + [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)

## Tech Stack

- **Frontend**: Vue 3 (Composition API)
- **UI Components**: PrimeVue
- **State Management**: Pinia
- **Desktop Framework**: Tauri v2
- **Styling**: Tailwind CSS
- **HTTP Client**: Tauri HTTP Plugin

## License

MIT
