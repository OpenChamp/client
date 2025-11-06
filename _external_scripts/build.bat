@echo off
echo Building Godot 4 Linux Server...

REM Check if Godot is installed
where Godot_v4.5.1-stable_win64.exe >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Godot not found in PATH
    echo Please install Godot 4 and add it to your PATH
    exit /b 1
)

REM Create builds directory if it doesn't exist
if not exist "builds" mkdir builds
if not exist "builds/server" mkdir builds/server

REM Build for Linux Server
echo Building Linux Server version...
Godot_v4.5.1-stable_win64.exe --headless --log-file "builds/openchamppc_ds.log" --export-release "Linux Server" "builds/server/OpenChamp_DS_Linux.x86_64"

echo Build complete! Check the builds/ directory for output files.
pause
