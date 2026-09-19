# hipi Documentation

hipi is a minimal terminal coding harness. It is designed to stay small at the core while being extended through TypeScript extensions, skills, prompt templates, themes, and pi packages.

## Quick start

Install hipi by building it from source. There is no published npm package and no installer script
yet.

```bash
git clone https://github.com/FrankCDev/HipiWork.git
cd HipiWork
npm install --ignore-scripts
npm run build
```

`--ignore-scripts` disables dependency lifecycle scripts during install. hipi does not require install scripts for normal installs.

This builds the CLI to `packages/coding-agent/dist/bundle/cli.js`. Run it with `node` from the
repository root, or put a wrapper on your `PATH`:

```bash
node packages/coding-agent/dist/bundle/cli.js --help
```

Uninstalling means deleting the checkout. HipiWork does not install anything globally, so there is
no global package to remove.

Then run it in a project directory:

```bash
node /path/to/HipiWork/packages/coding-agent/dist/bundle/cli.js
```

Authenticate with `/login` for subscription providers, or set an API key such as `ANTHROPIC_API_KEY` before starting hipi.

For the full first-run flow, see [Quickstart](quickstart.md).

## Start here

- [Quickstart](quickstart.md) - install, authenticate, and run a first session.
- [Using hipi](usage.md) - interactive mode, slash commands, context files, and CLI reference.
- [Providers](providers.md) - subscription and API-key setup for built-in providers.
- [llama.cpp](llama-cpp.md) - run a local router and manage models with `/llama`.
- [Security](security.md) - project trust, sandbox boundaries, and vulnerability reporting.
- [Containerization](containerization.md) - sandbox hipi with Gondolin, Docker, or OpenShell.
- [Settings](settings.md) - global and project settings.
- [Keybindings](keybindings.md) - default shortcuts and custom keybindings.
- [Sessions](sessions.md) - session management, branching, and tree navigation.
- [Compaction](compaction.md) - context compaction and branch summarization.

## Customization

- [Extensions](extensions.md) - TypeScript modules for tools, commands, events, and custom UI.
- [Skills](skills.md) - Agent Skills for reusable on-demand capabilities.
- [Prompt templates](prompt-templates.md) - reusable prompts that expand from slash commands.
- [Themes](themes.md) - built-in and custom terminal themes.
- [pi packages](packages.md) - bundle and share extensions, skills, prompts, and themes.
- [Custom models](models.md) - add model entries for supported provider APIs.
- [Custom providers](custom-provider.md) - implement custom APIs and OAuth flows.

## Programmatic usage

- [SDK](sdk.md) - embed hipi in Node.js applications.
- [RPC mode](rpc.md) - integrate over stdin/stdout JSONL.
- [JSON event stream mode](json.md) - print mode with structured events.
- [TUI components](tui.md) - build custom terminal UI for extensions.

## Reference

- [Environment variables](environment-variables.md) - hipi process configuration and session metadata available to bash tools.
- [Session format](session-format.md) - JSONL session file format, entry types, and SessionManager API.

## Platform setup

- [Windows](windows.md)
- [Termux on Android](termux.md)
- [tmux](tmux.md)
- [Terminal setup](terminal-setup.md)
- [Shell aliases](shell-aliases.md)

## Development

- [Development](development.md) - local setup, project structure, and debugging.
