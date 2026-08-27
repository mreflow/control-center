# Control Center — Windows requirements

App: https://github.com/mreflow/control-center

These three files live in the repo root:

- REQUIREMENTS.md
- setup.bat
- start.bat

## Required

- Windows 10 22H2 or Windows 11
- Internet for the first install
- A desktop browser
- About 500 MB disk for the app
- 4 GB RAM free for the dashboard

setup.bat installs Node.js 24.20 if it is missing. Git is optional.

## Optional local AI (Ollama)

setup.bat will:

- Install Ollama if it is missing (winget, then OllamaSetup.exe)
- Read installed RAM
- Pick a default model:
  - under 10 GB RAM: gemma3:4b
  - 10-19 GB RAM: qwen2.5:7b
  - 20 GB+ RAM: qwen2.5:14b
- Download that model if it is not already installed
- Point Settings at Ollama on http://127.0.0.1:11434

Override the model:

    setup.bat /model=qwen2.5:7b

If the chosen model is already on disk, it is not downloaded again.
Keep the Ollama tray app running while you use the dashboard.
In the app: Settings -> AI curation -> Ollama -> Reload models.

## Ports

- http://127.0.0.1:3000  Control Center
- http://127.0.0.1:11434 Ollama

## Folders

- App: this repo folder
- Data: %LOCALAPPDATA%\Control Center
- Portable Node: %LOCALAPPDATA%\ControlCenter-Runtime\node

## How to use

From the repo root:

    setup.bat

Later launches:

    start.bat

Leave the Command Prompt open. That window is the server.
Open http://127.0.0.1:3000 if the browser does not open.

Ctrl+C stops the server.
