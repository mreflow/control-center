@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Control Center
cd /d "%~dp0"

if not defined CC_KEEPOPEN (
    set "CC_KEEPOPEN=1"
    cmd /k "%~f0" %*
    exit /b
)

set "PULL_MODEL="
for %%A in (%*) do (
    set "ARG=%%~A"
    if /i "!ARG:~0,7!"=="/model=" set "PULL_MODEL=!ARG:~7!"
)

set "REPO_URL=https://github.com/mreflow/control-center.git"
set "REPO_ZIP=https://github.com/mreflow/control-center/archive/refs/heads/main.zip"
set "NODE_VER=24.20.0"
set "NODE_HOME=%LOCALAPPDATA%\ControlCenter-Runtime\node"
set "DATA_DIR=%LOCALAPPDATA%\Control Center"
set "OLLAMA_URL=http://127.0.0.1:11434"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

rem In-repo: setup.bat sits next to package.json.
rem Outside-repo: setup.bat sits beside a control-center folder.
if exist "%SCRIPT_DIR%\package.json" (
    findstr /C:"self-hosted-control-center" "%SCRIPT_DIR%\package.json" >nul 2>&1
    if not errorlevel 1 (
        set "INSTALL_DIR=%SCRIPT_DIR%"
        goto HAVE_DIR
    )
)
if exist "%SCRIPT_DIR%\control-center\package.json" (
    set "INSTALL_DIR=%SCRIPT_DIR%\control-center"
    goto HAVE_DIR
)
set "INSTALL_DIR=%SCRIPT_DIR%\control-center"

:HAVE_DIR
echo.
echo  Control Center setup
echo  Project: %INSTALL_DIR%
echo.

set "PORTABLE_HOME=%LOCALAPPDATA%\ControlCenter-Runtime\node"
set "NODE_HOME=%PORTABLE_HOME%"

if exist "%PORTABLE_HOME%\node.exe" (
    call :node_new_enough "%PORTABLE_HOME%"
    if not errorlevel 1 goto NODE_OK
    echo Portable Node is older than 24.19.0. Replacing it...
)

if exist "%ProgramFiles%\nodejs\node.exe" (
    call :node_new_enough "%ProgramFiles%\nodejs"
    if not errorlevel 1 (
        set "NODE_HOME=%ProgramFiles%\nodejs"
        goto NODE_OK
    )
    echo System Node is older than 24.19.0. Installing portable %NODE_VER%...
)

rem Incompatible binary may live under Program Files. Always install into the portable folder.
set "NODE_HOME=%PORTABLE_HOME%"
echo Downloading portable Node.js %NODE_VER%...
set "ARCH=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm64"
set "ZIP=%TEMP%\node-v%NODE_VER%-win-%ARCH%.zip"
if not exist "%ZIP%" curl.exe -L --fail -o "%ZIP%" "https://nodejs.org/dist/v%NODE_VER%/node-v%NODE_VER%-win-%ARCH%.zip"
if not exist "%ZIP%" goto FAIL
set "EXTRACT=%TEMP%\cc-node-unpack"
if exist "%EXTRACT%" rmdir /s /q "%EXTRACT%"
mkdir "%EXTRACT%"
tar.exe --force-local -xf "%ZIP%" -C "%EXTRACT%" 2>nul
if not exist "%EXTRACT%\node-v%NODE_VER%-win-%ARCH%\node.exe" (
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%EXTRACT%' -Force"
)
if not exist "%NODE_HOME%" mkdir "%NODE_HOME%"
robocopy "%EXTRACT%\node-v%NODE_VER%-win-%ARCH%" "%NODE_HOME%" /E /NFL /NDL /NJH /NJS /NP >nul
if not exist "%NODE_HOME%\node.exe" goto FAIL

:NODE_OK
set "PATH=%NODE_HOME%;%LOCALAPPDATA%\Programs\Ollama;%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\WindowsPowerShell\v1.0"
echo Node:
"%NODE_HOME%\node.exe" -v

if exist "%INSTALL_DIR%\package.json" goto SOURCE_OK
echo Downloading Control Center...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
where git >nul 2>&1
if not errorlevel 1 (
    git clone --depth 1 "%REPO_URL%" "%INSTALL_DIR%"
    if not errorlevel 1 goto SOURCE_OK
)
set "APPZIP=%TEMP%\control-center-main.zip"
curl.exe -L --fail -o "%APPZIP%" "%REPO_ZIP%"
tar.exe --force-local -xf "%APPZIP%" -C "%TEMP%" 2>nul
if exist "%TEMP%\control-center-main\package.json" xcopy /e /i /y /q "%TEMP%\control-center-main\*" "%INSTALL_DIR%\" >nul
if not exist "%INSTALL_DIR%\package.json" goto FAIL

:SOURCE_OK
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if exist "%INSTALL_DIR%\.env.example" if not exist "%INSTALL_DIR%\.env.local" copy /y "%INSTALL_DIR%\.env.example" "%INSTALL_DIR%\.env.local" >nul
if exist "%SCRIPT_DIR%\start.bat" if /i not "%SCRIPT_DIR%"=="%INSTALL_DIR%" copy /y "%SCRIPT_DIR%\start.bat" "%INSTALL_DIR%\start.bat" >nul
if exist "%SCRIPT_DIR%\REQUIREMENTS.md" if /i not "%SCRIPT_DIR%"=="%INSTALL_DIR%" copy /y "%SCRIPT_DIR%\REQUIREMENTS.md" "%INSTALL_DIR%\REQUIREMENTS.md" >nul
echo Source ready.

set "PATH=%LOCALAPPDATA%\Programs\Ollama;%ProgramFiles%\Ollama;%PATH%"
where ollama >nul 2>&1
if errorlevel 1 (
    echo Installing Ollama...
    where winget >nul 2>&1
    if not errorlevel 1 winget install --id Ollama.Ollama -e --accept-package-agreements --accept-source-agreements
    set "PATH=%LOCALAPPDATA%\Programs\Ollama;%ProgramFiles%\Ollama;%PATH%"
)
where ollama >nul 2>&1
if errorlevel 1 (
    echo Downloading OllamaSetup.exe...
    curl.exe -L --fail -o "%TEMP%\OllamaSetup.exe" "https://ollama.com/download/OllamaSetup.exe"
    if not errorlevel 1 "%TEMP%\OllamaSetup.exe" /VERYSILENT /NORESTART /SUPPRESSMSGBOXES
    set "PATH=%LOCALAPPDATA%\Programs\Ollama;%ProgramFiles%\Ollama;%PATH%"
)
where ollama >nul 2>&1
if errorlevel 1 (
    echo Ollama could not be installed. Dashboard will still run.
    goto APP
)

curl.exe -s -m 2 "%OLLAMA_URL%/api/tags" >nul 2>&1
if errorlevel 1 start "Ollama" /MIN cmd /c "ollama serve"
timeout /t 3 /nobreak >nul

set "RAM_GB=16"
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%PS%" (
    for /f "delims=" %%M in ('"%PS%" -NoProfile -Command "[int]((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB)"') do set "RAM_GB=%%M"
)
set "RECOMMENDED=qwen2.5:7b"
if %RAM_GB% LSS 10 set "RECOMMENDED=gemma3:4b"
if %RAM_GB% GEQ 20 set "RECOMMENDED=qwen2.5:14b"
echo Detected about %RAM_GB% GB RAM
echo Recommended model: %RECOMMENDED%

if not "%PULL_MODEL%"=="" (
    set "MODEL=%PULL_MODEL%"
) else (
    set "MODEL=%RECOMMENDED%"
)

echo Local Ollama models:
ollama list
ollama list 2>nul | findstr /I /C:"%MODEL%" >nul
if errorlevel 1 (
    echo Downloading %MODEL% ...
    ollama pull %MODEL%
    if errorlevel 1 (
        echo Could not download %MODEL%. Dashboard will still run.
        goto APP
    )
) else (
    echo %MODEL% is already installed. Skipping download.
)

echo Using model %MODEL%
curl.exe -s -m 180 "%OLLAMA_URL%/api/generate" -H "Content-Type: application/json" -d "{\"model\":\"%MODEL%\",\"prompt\":\"ok\",\"stream\":false,\"keep_alive\":-1}" >nul 2>&1
"%NODE_HOME%\node.exe" -e "const fs=require('fs'),path=require('path');const p=path.join(process.env.LOCALAPPDATA,'Control Center','settings.json');let s={};try{s=JSON.parse(fs.readFileSync(p,'utf8').[...]

:APP
cd /d "%INSTALL_DIR%"
if exist "%DATA_DIR%\launcher.lock" del /f /q "%DATA_DIR%\launcher.lock" >nul 2>&1
"%NODE_HOME%\node.exe" -e "const fs=require('fs'),p=require('path').join(process.env.LOCALAPPDATA,'Control Center','settings.json');if(!fs.existsSync(p))process.exit(0);const b=fs.readFileSync(p)[...]

echo Installing app packages...
call "%NODE_HOME%\npm.cmd" run setup
if errorlevel 1 call "%NODE_HOME%\npm.cmd" ci
if not exist "node_modules\next\dist\bin\next" goto FAIL
if not exist ".next\BUILD_ID" (
    echo Building dashboard...
    call "%NODE_HOME%\npm.cmd" run build
    if errorlevel 1 goto FAIL
)

echo.
echo Starting server. Leave this window open.
echo Dashboard: http://127.0.0.1:3000
echo.
start "" "http://127.0.0.1:3000"
"%NODE_HOME%\node.exe" "node_modules\next\dist\bin\next" start --hostname 127.0.0.1 --port 3000
echo.
echo Server stopped.
pause
exit /b 0

:node_new_enough
"%~1\node.exe" -e "const p=process.versions.node.split('.').map(Number);process.exit((p[0]>24||(p[0]===24&&p[1]>=19))?0:1)"
exit /b %ERRORLEVEL%

:FAIL
echo.
echo Setup could not finish. Check the message above.
pause
exit /b 1
