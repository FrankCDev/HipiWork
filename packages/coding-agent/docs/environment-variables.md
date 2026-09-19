# Environment Variables

hipi uses environment variables in three ways:

- Variables such as `HIPI_OFFLINE` configure the hipi process.
- hipi sets process markers so child processes can identify hipi as the launching agent.
- Commands run by the LLM-callable shell tools receive `HIPI_*` variables describing the current session.

Provider API-key variables are documented separately in [Providers](providers.md#environment-variables-or-auth-file).

## Process Marker

The CLI and RPC entry points set two process markers:

- `AI_AGENT=hipi` is a generic marker that lets tooling identify HipiWork as the agent that launched the process.
- `HIPI_CODING_AGENT=true` is Pi-specific and lets child processes detect that they run inside hipi.

Child processes inherit both markers. They are not session-specific and are not set automatically when hipi is embedded through the SDK.

## Shell Tool Session Environment

Commands run by the `bash` and `powershell` tools receive the current hipi session state:

| Variable | Description |
|----------|-------------|
| `HIPI_SESSION_ID` | Current session ID |
| `HIPI_SESSION_FILE` | Absolute path to the current session JSONL file; unset for ephemeral sessions |
| `HIPI_PROVIDER` | Currently selected model provider |
| `HIPI_MODEL` | Currently selected model ID |
| `HIPI_REASONING_LEVEL` | Current effective reasoning level: `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, or `max` |

The values are resolved when each command starts. Switching models or changing the reasoning level therefore affects the next shell command without restarting hipi. `HIPI_PROVIDER` and `HIPI_MODEL` identify the selected hipi model, not a different upstream model that a router may choose internally.

When asked which model or provider is running, inspect these variables instead of inferring the answer from the system prompt:

```bash
printf '%s/%s\n' "$HIPI_PROVIDER" "$HIPI_MODEL"
printf 'reasoning=%s session=%s\n' "$HIPI_REASONING_LEVEL" "$HIPI_SESSION_ID"
```

The session file can be inspected directly when the session is persistent:

```bash
if [ -n "$HIPI_SESSION_FILE" ]; then
  tail -n 1 "$HIPI_SESSION_FILE"
fi
```

These variables are injected into the LLM-callable `bash` and `powershell` tools. They are not injected into user-entered `!` or `!!` commands.

### Custom Shell Tools

Tools created with `createBashTool()` or `createPowerShellTool()` expose the session environment by default when registered with hipi. Injection happens before `spawnHook`, so a hook receives the variables in `ctx.env`:

```typescript
const bashTool = createBashTool(cwd, {
  spawnHook: (ctx) => ({
    ...ctx,
    env: { ...ctx.env, CI: "1" },
  }),
});
```

Disable session metadata independently of the spawn hook:

```typescript
const powershellTool = createPowerShellTool(cwd, {
  exposeSessionEnvironment: false,
  spawnHook: (ctx) => ctx,
});
```

When disabled, hipi removes inherited values for these variables so nested hipi processes do not expose stale parent-session metadata.

## hipi Process Configuration

These variables are read by hipi itself:

| Variable | Description |
|----------|-------------|
| `HIPI_CODING_AGENT_DIR` | Override the config directory; default is `~/.hipi/agent` |
| `HIPI_CODING_AGENT_SESSION_DIR` | Override session storage; overridden by `--session-dir` |
| `HIPI_PACKAGE_DIR` | Override the package directory, useful for Nix/Guix store paths |
| `HIPI_OFFLINE` | Disable startup network operations, including version checks and package updates |
| `HIPI_LATEST_VERSION_URL` | Release feed queried for version checks. Unset (the default) disables them entirely |
| `HIPI_SKIP_VERSION_CHECK` | Skip the version check at startup even when a release feed is configured |
| `HIPI_TELEMETRY` | Override provider attribution headers: `1`/`true`/`yes` or `0`/`false`/`no` |
| `HIPI_CACHE_RETENTION` | Set to `long` for extended provider prompt caching where supported |
| `HIPI_SHARE_VIEWER_URL` | Session viewer base URL. Unset (the default) leaves `/share` disabled |
| `HIPI_HARDWARE_CURSOR` | Set to `1` to show the hardware cursor; see [Terminal setup](terminal-setup.md) |
| `HIPI_HYPERLINKS` | Override OSC 8 hyperlink detection with `1`, `0`, or `auto` |
| `HIPI_IMAGE_PROTOCOL` | Override inline image detection with `kitty`, `iterm2`, `none`, or `auto` |
| `HIPI_TRUE_COLOR` | Override truecolor detection with `1`, `0`, or `auto` |
| `HIPI_TUI_ESC_TIMEOUT` | How long to wait after a lone ESC before treating it as Escape, in milliseconds; defaults to `100` over SSH and `10` otherwise. Increase if Alt-key input is misread as Escape |
| `VISUAL`, `EDITOR` | External editor fallback when `externalEditor` is unset |
| `HTTP_PROXY`, `HTTPS_PROXY` | Proxy outbound HTTP requests |

Provider credentials such as `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, and cloud-provider configuration are listed in [Providers](providers.md#environment-variables-or-auth-file).

`HIPI_SERVER_DIR` and `HIPI_SERVER_ID` apply only to the source-only [experimental remote harness](development.md#experimental-remote-harness), not distributed builds.
