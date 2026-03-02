#!/bin/bash

# PostMock Data Cleanup Script
# This script removes all stored data to start fresh

echo "🧹 Cleaning PostMock data..."

# Determine the data directory based on OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    DATA_DIR="$HOME/.local/share/postmock"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    DATA_DIR="$HOME/Library/Application Support/postmock"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    DATA_DIR="$APPDATA/postmock"
else
    echo "❌ Unsupported operating system"
    exit 1
fi

echo "📁 Data directory: $DATA_DIR"

# Check if directory exists
if [ -d "$DATA_DIR" ]; then
    echo "🗑️  Removing data directory..."
    rm -rf "$DATA_DIR"
    echo "✅ Data directory removed successfully"
else
    echo "ℹ️  Data directory does not exist (already clean)"
fi

echo ""
echo "✨ PostMock data has been cleaned!"
echo "🚀 You can now start the application with a fresh state"
