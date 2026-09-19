# HipiWork

An open-source coding and work agent client, built as a fork of [pi](https://github.com/earendil-works/pi).

HipiWork aims to be a general-purpose agent you can talk to about code and about work — the same
tool for reading a repository, running a build, drafting a document, or driving a workflow.

> **Not affiliated with the pi project.** HipiWork is an independent derivative work. See
> [Attribution](#attribution) for what came from upstream and what changed.

## Packages

HipiWork keeps the upstream package names so that it can keep merging upstream changes. Package
names are `@earendil-works/*`; the product and CLI are `hipi`.

| Package | Description |
|---------|-------------|
| **[@earendil-works/pi-coding-agent](packages/coding-agent)** | Interactive coding agent CLI (the `hipi` binary) |
| **[@earendil-works/pi-agent-core](packages/agent)** | Agent runtime with tool calling and state management |
| **[@earendil-works/pi-ai](packages/ai)** | Unified multi-provider LLM API (OpenAI, Anthropic, Google, etc.) |
| **[@earendil-works/pi-tui](packages/tui)** | Terminal UI library with differential rendering |
| **[@earendil-works/pi-durable](packages/durable)** | Durable conversation, task, and document runtime |
| **[@earendil-works/pi-telemetry](packages/telemetry)** | Vendor-neutral telemetry contracts, reference adapter, conformance tests, and typed schemas |
| **[@earendil-works/chord](packages/chord)** | Standalone application-composition runtime for services, replicated state, RPC, and plugins |

## Documentation

Start with [packages/coding-agent/docs/index.md](packages/coding-agent/docs/index.md). The agent can
also explain itself — ask it.

Key references:

- [Quickstart](packages/coding-agent/docs/quickstart.md)
- [Usage](packages/coding-agent/docs/usage.md)
- [Environment variables](packages/coding-agent/docs/environment-variables.md) — HipiWork uses the `HIPI_*` prefix
- [Extensions](packages/coding-agent/docs/extensions.md)
- [SDK](packages/coding-agent/docs/sdk.md)

## Building and running

HipiWork is currently **built from source**. There are no published releases yet, so the upstream
installer and the self-update command are disabled by design.

```bash
npm install --ignore-scripts  # Install all dependencies without running lifecycle scripts
npm run build                 # Refresh model data, then build all packages
npm run check                 # Lint, format, and type check
./test.sh                     # Run tests (skips LLM-dependent tests without API keys)
./pi-test.sh                  # Run HipiWork from sources (can be run from any directory)
```

`npm run build` needs network access: it refreshes model metadata from upstream provider catalogs.
Use `npm run build:offline` to rebuild from the model data already on disk.

Then run the CLI:

```bash
node packages/coding-agent/dist/bundle/cli.js --help
```

Configuration lives under `~/.hipi/`. Override the location with `HIPI_CODING_AGENT_DIR`.

### Disabled upstream services

These need a service HipiWork does not run yet. Each one stays off unless you point it somewhere,
so the binary makes no call to them by default:

| Feature | Env var | Default |
|---------|---------|---------|
| Update check | `HIPI_LATEST_VERSION_URL` | off — no request |
| Self-update (`hipi update --self`) | `HIPI_INSTALLER_API_BASE` | off — command reports no release feed |
| `/share` session links | `HIPI_SHARE_VIEWER_URL` | off — command is unavailable |

The upstream install-report ping is removed entirely, not merely disabled.

## Permissions & Containerization

HipiWork does not include a built-in permission system for restricting filesystem, process, network,
or credential access. By default, it runs with the permissions of the user and process that
launched it.

If you need stronger boundaries, containerize or sandbox it. See
[packages/coding-agent/docs/containerization.md](packages/coding-agent/docs/containerization.md) for
three patterns:

- **Gondolin extension**: keep `hipi` and provider auth on the host while routing built-in tools and `!` commands into a local Linux micro-VM.
- **Plain Docker**: run the whole `hipi` process in a local container for simple isolation.
- **OpenShell**: run the whole `hipi` process in a policy-controlled sandbox.

## Building standalone binaries from release source

Once releases exist, a versioned source archive will be published alongside a `SHA256SUMS` file.
Extract it and run the same build script used for the standalone binaries:

```bash
VERSION="<release-version>"
tar -xzf "hipi-${VERSION}-source.tar.gz"
cd "hipi-${VERSION}"
./scripts/build-binaries.sh --offline-model-data --platform linux-x64 --out "$PWD/out"
```

The archive includes release model data and native prebuilds. `--offline-model-data` uses that model
data without refreshing provider catalogs. The script installs dependencies and builds the executable
with its runtime assets; pass `--skip-install` if dependencies are already provided.

## Supply-chain hardening

We treat npm dependency changes as reviewed code changes.

- Direct external dependencies are pinned to exact versions. Internal workspace packages remain version-ranged.
- `.npmrc` sets `save-exact=true` and `min-release-age=2` to avoid same-day dependency releases during npm resolution.
- `package-lock.json` is the dependency ground truth. Pre-commit blocks accidental lockfile commits unless `HIPI_ALLOW_LOCKFILE_CHANGE=1` is set.
- `npm run check` verifies pinned direct deps, native TypeScript import compatibility, and the generated coding-agent shrinkwrap.
- The published CLI package includes `packages/coding-agent/npm-shrinkwrap.json`, generated from the root lockfile, to pin transitive deps for npm users.
- Release smoke tests use `npm run release:local` to build, pack, and create isolated npm and Bun installs outside the repo before tagging a release.
- Local release installs, documented npm installs, and `hipi update --self` use `--ignore-scripts` where supported.
- CI installs with `npm ci --ignore-scripts`, and a scheduled GitHub workflow runs `npm audit --omit=dev` plus `npm audit signatures --omit=dev`.
- Shrinkwrap generation has an explicit allowlist for dependency lifecycle scripts; new lifecycle-script deps fail checks until reviewed.

## Contributing

This repository tracks upstream pi. Two different contribution targets, with different rules:

- **Changes to HipiWork itself**: see [AGENTS.md](AGENTS.md) for project rules (for both humans and agents). Work on a branch, keep `main` a clean mirror of upstream, and sync with `git merge upstream/main`.
- **Fixes that belong upstream**: send them to [pi](https://github.com/earendil-works/pi) instead. Note that upstream auto-closes new contributors' issues and PRs until a maintainer replies `lgtm` — see `CONTRIBUTING.md`.

Upstream's longer-term plans for pi are in [RFCs](https://rfc.earendil.com/keyword/pi/); they are
upstream's roadmap, not HipiWork's.

## Attribution

HipiWork is a derivative work of [pi](https://github.com/earendil-works/pi), which is MIT licensed.

- Upstream copyright is preserved in full in [LICENSE](LICENSE) — `Copyright (c) 2025 Mario Zechner`.
- [NOTICE](NOTICE) records the relationship between this repository and upstream.
- Package names, the `@earendil-works/*` scope, the SDK surface, and the session format are inherited unchanged so that upstream merges stay possible.

What HipiWork changes relative to upstream: the product name and CLI (`hipi`), the configuration
directory (`~/.hipi`), the `HIPI_*` environment variable prefix, outbound request attribution
headers and user agents, the runtime system prompt, and the set of upstream services that are
enabled by default.

The `pi.dev` domain and the Exy mascot belong to the pi project and were donated to it by
[exe.dev](https://exe.dev). HipiWork does not use either.

## License

MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE).
