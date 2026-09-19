# Security Policy

This document explains the security model behind the HipiWork agent and where its boundaries are.

HipiWork is a fork of [pi](https://github.com/earendil-works/pi). Most of the code is inherited
unchanged, so for many issues the correct fix belongs upstream. See
[Reporting a Vulnerability](#reporting-a-vulnerability) for how to tell the two apart.

## Security model

In general, HipiWork is a coding agent that runs locally within the security boundary of the user
running it. It is the responsibility of the user to monitor its operations or to contain it within a
container, virtual machine, or other sandbox solution.

HipiWork treats the local user account and files writable by that account as inside the same trust
boundary as the agent process itself. If an attacker can modify files under the user's home
directory, workspace, shell startup files, environment, or the agent configuration, they can
generally influence HipiWork or other local developer tools. Reports that depend on such prior local
write access are not security vulnerabilities unless they demonstrate how HipiWork grants that write
access or crosses an operating-system privilege boundary.

HipiWork relies on users installing trustworthy extensions and loading trustworthy skills, and on
using it only within trusted repositories. Files like `AGENTS.md`, or instructions in comments, can
be used to prompt inject the agent trivially, and this cannot be protected against.

## Reporting a Vulnerability

Two cases, two destinations.

**Report to this repository** if the issue is specific to what HipiWork changed relative to upstream:

- The `hipi` binary, package metadata, or build/release scripts in this repository
- The configuration directory (`~/.hipi`), the `HIPI_*` environment variables, or their handling
- Outbound request attribution headers or user agents
- The default-enabled service set, or the gating of the update check, self-update, and `/share`

Use **GitHub Security Advisories** for `FrankCDev/HipiWork`. Do not open a public issue for a
security-sensitive report.

**Report upstream** to [pi](https://github.com/earendil-works/pi) if the issue is in inherited code:

- Provider adapters and the unified LLM API (`packages/ai`)
- The agent runtime (`packages/agent`), terminal UI (`packages/tui`), or session storage
- Credential handling, OAuth flows, or extension/skill loading semantics

Those paths are upstream's code and upstream's to fix. Reporting them here means they may never reach
the people who can address them. Upstream's own reporting instructions and its
`security@earendil.com` address are for that project, not for HipiWork.

### What to include

- A description of the issue and its impact
- Steps to reproduce, proof of concept, or relevant logs
- Affected package, version, commit, or configuration
- Any known mitigations

## Scope

Security issues in the command-line tool, APIs, and repository code shipped from this repository are
in scope.

Not in scope:

- Hosted services. HipiWork operates no server, no domain, and no hosted infrastructure. `pi.dev`
  and the infrastructure behind it are operated by the pi project, not by HipiWork — report
  problems with them upstream.

## Out Of Scope

- Local code execution or sandboxing behavior (the agent intentionally does not have a sandbox)
- Behavior of extensions or skills installed by the user
- Risks from working in untrusted repositories
- Risks from installing untrusted extensions, skills, packages, or tools
- Issues caused by non-trustworthy MITM proxies
- Public internet exposure of an installation
- Prompt injection attacks
- Exposed secrets that are third-party/user-controlled credentials
- Reports requiring the ability to create, modify, delete, or replace files, directories, symlinks,
  environment variables, shell configuration, or other user-controlled local state on the target
  machine. This includes `~/.hipi` (and `~/.pi`), `~/.hipi/agent/models.json`, workspace files,
  `AGENTS.md`, skills, extensions, extension configuration, dotfiles, and files synchronized through
  NFS, roaming profiles, or dotfile managers, unless the report shows how the agent itself grants
  that access.
- Issues caused by intentionally weakened user configuration
- Resource/DOS claims that require trusted local input/config against the agent
- Reports about malicious model output
- User-approved or user-initiated local actions presented as vulnerabilities

## Notes for Reporters

The most useful reports show a current, reproducible security boundary bypass with demonstrated
impact. Reports that only show expected local-agent behavior, prompt injection, or a malicious
trusted extension/skill are not security vulnerabilities under this model.

For example, a report showing that malicious contents written to a trusted configuration file cause
the agent to execute commands, load attacker-controlled tools, send credentials to an
attacker-controlled endpoint, or otherwise change behavior is out of scope.

When possible, include the exact affected path, package version or commit SHA, configuration, and a
proof of concept against the latest `main`. For dependency reports, include evidence that the shipped
dependency is affected and that the issue is reachable through this repository. For exposed-secret
reports, include evidence that the credential grants access to something HipiWork operates — note
that currently means nothing, since HipiWork runs no service.
