@echo off
REM PostMock Data Cleanup Script for Windows
REM This script removes all stored data to start fresh

echo 🧹 Cleaning PostMock data...

set DATA_DIR=%APPDATA%\postmock

echo 📁 Data directory: %DATA_DIR%

if exist "%DATA_DIR%" (
    echo 🗑️  Removing data directory...
    rmdir /s /q "%DATA_DIR%"
    echo ✅ Data directory removed successfully
) else (
    echo ℹ️  Data directory does not exist (already clean)
)

echo.
echo ✨ PostMock data has been cleaned!
echo 🚀 You can now start the application with a fresh state
pause
