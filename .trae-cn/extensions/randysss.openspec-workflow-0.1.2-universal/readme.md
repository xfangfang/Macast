# OpenSpec Extension

> Visual interface for managing OpenSpec workflows in VSCode, Cursor.

## Overview

A VSCode/Cursor extension that provides a visual dashboard for [OpenSpec](https://github.com/Fission-AI/OpenSpec), making it easier to manage changes, view specs, and track tasks without leaving your editor.

### Features

- **Visual Dashboard**: Changes and specs list, progress bars, empty states
- **Change Detail**: Tabs for Proposal, Specs, Design, Tasks; markdown viewer; task checkboxes with write-back
- **CLI Integration**: OpenSpec CLI (list, status, new, archive) with retry and timeout
- **Quick Actions**: Copy /opsx:ff, /opsx:apply; Archive; Open in Editor; Refresh
- **Commands**: Open Dashboard, Refresh Data, Create New Change, Archive Change
- **Logging**: Output panel "OpenSpec" channel

## Installation

- **From marketplace**: Install **OpenSpec** from the [VS Code Marketplace](https://marketplace.visualstudio.com/) or [Open VSX](https://open-vsx.org/) (e.g. in Cursor).
- **Requirements**: [OpenSpec CLI](https://github.com/Fission-AI/OpenSpec#quick-start) on your PATH; a workspace that contains (or will contain) `openspec/config.yaml`. The extension activates when it finds an OpenSpec workspace.

## Usage

### Commands

Open Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`):

| Command | Description |
|---------|-------------|
| **OpenSpec: Open Dashboard** | Open visual dashboard (sidebar or editor) |
| **OpenSpec: Refresh Data** | Manually refresh from CLI |
| **OpenSpec: Create New Change** | Create new change (with validation) |
| **OpenSpec: Archive Change** | Archive completed change |

### Keyboard shortcuts

- `Cmd+Shift+P` (Mac) / `Ctrl+Shift+P` (Windows/Linux): Command Palette — then type "OpenSpec" to run any command.
- No default keybindings; you can assign them in Keyboard Shortcuts (e.g. for "OpenSpec: Open Dashboard").

### Configuration

| Setting | Default | Description |
|--------|---------|-------------|
| `openspec.focusSidebarViewWhenOpeningChangeDetail` | `false` | Focus OpenSpec sidebar when opening change detail |
| `openspec.focusSidebarViewWhenOpeningDashboard` | `false` | Focus OpenSpec sidebar when opening dashboard |
| `openspec.taskExecutionMode` | `fillChat` | When clicking task execute: `auto` = run via adapter; `fillChat` = fill chat or copy to clipboard |
| `openspec.preferredAgentAdapter` | `""` | Preferred agent executor adapter id (e.g. `cursor`, `clipboard`). Empty = use first available |
| `openspec.taskDependencyPolicy` | `block` | When preceding tasks are incomplete: `block` = prevent execution; `warn` = show warning and allow proceed |
| `openspec.agentModel` | `auto` | Cursor agent CLI model (only when using Cursor adapter). Use `auto` or a specific model name |
| `openspec.debug` | `false` | Enable debug: Verify tab and full prompt in Output when executing tasks |

**Task execution & Adapters**

- **Clipboard** (`clipboard`): Always available. In fillChat mode it copies the prompt to the clipboard and notifies you; in auto mode it also copies (no direct execution).
- **Cursor** (`cursor`): Available when the Cursor `agent` CLI is on PATH (e.g. in Cursor IDE). Executes tasks via the agent CLI or fills chat / copies to clipboard.
- You can choose the adapter in the change detail UI (Adapter dropdown) or set `openspec.preferredAgentAdapter` in settings. If the selected adapter is unavailable, the extension falls back to the first available one (often clipboard).

### Dashboard

- Changes list with progress and status; quick actions (Copy /opsx:ff, /opsx:apply, Archive)
- Specs list; empty states with "Create New Change"
- Change detail: Proposal / Specs / Design / Tasks tabs; markdown rendering; task toggles; action bar

### Viewing Logs

1. Open Output panel: `View > Output` or `Cmd+Shift+U`
2. Select **"OpenSpec"** from dropdown
3. View timestamped logs (INFO, WARN, ERROR, DEBUG)

### Troubleshooting

- **Extension doesn’t activate**: Open a folder that contains (or will contain) an OpenSpec workspace (`openspec/config.yaml`). The extension only activates in OpenSpec workspaces.
- **"OpenSpec CLI not found"**: Install [OpenSpec CLI](https://github.com/Fission-AI/OpenSpec#quick-start) and ensure it’s on your PATH.
- **Dashboard empty**: Run **OpenSpec: Refresh Data**; check the **OpenSpec** output channel for errors.
