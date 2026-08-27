@echo off
setlocal EnableExtensions
title Control Center
cd /d "%~dp0"

if not defined CC_KEEPOPEN (
    set "CC_KEEPOPEN=1"
    cmd /k "%~f0" %*
    exit /b
)

set "NODE_HOME=%LOCALAPPDATA%\ControlCenter-Runtime\node"
if not exist "%NODE_HOME%\node.exe" set "NODE_HOME=%ProgramFiles%\nodejs"
set "PATH=%NODE_HOME%;%LOCALAPPDATA%\Programs\Ollama;%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\WindowsPowerShell\v1.0"
set "DATA_DIR=%LOCALAPPDATA%\Control Center"

if not exist "%~dp0package.json" (
    echo Put start.bat in the control-center folder.
    pause
    exit /b 1
)
if not exist "%NODE_HOME%\node.exe" (
    echo Node.js not found. Run setup.bat first.
    pause
    exit /b 1
)

if exist "%DATA_DIR%\launcher.lock" del /f /q "%DATA_DIR%\launcher.lock" >nul 2>&1
"%NODE_HOME%\node.exe" -e "const fs=require('fs'),p=require('path').join(process.env.LOCALAPPDATA,'Control Center','settings.json');if(!fs.existsSync(p))process.exit(0);const b=fs.readFileSync(p);if(b[...]

where ollama >nul 2>&1
if not errorlevel 1 (
    curl.exe -s -m 2 http://127.0.0.1:11434/api/tags >nul 2>&1
    if errorlevel 1 start "Ollama" /MIN cmd /c "ollama serve"
)

if not exist "node_modules\next\dist\bin\next" (
    echo App packages missing. Run setup.bat once.
    pause
    exit /b 1
)
if not exist ".next\BUILD_ID" (
    echo Building dashboard...
    call "%NODE_HOME%\npm.cmd" run build
)

echo Starting Control Center
echo Leave this window open
echo http://127.0.0.1:3000
echo.
start "" "http://127.0.0.1:3000"
"%NODE_HOME%\node.exe" "node_modules\next\dist\bin\next" start --hostname 127.0.0.1 --port 3000
echo.
echo Server stopped.
pause
