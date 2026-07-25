# Security Policy

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

Email **info@hauschel.de** with the details. This reaches the maintainer
privately and lets us coordinate a fix and disclosure.

## What to include

- A description of the issue and its impact.
- Steps to reproduce, or a minimal proof of concept.
- The affected version or commit, plus any relevant environment details.

## Process and expectations

This project is maintained on a best-effort basis by a single maintainer in
spare time (see [CONTRIBUTING](CONTRIBUTING.md)). There is no guaranteed
response time, but security reports are prioritised over routine issues. Please
allow a reasonable window for a fix before any public disclosure.

## Scope

This repository ships a Claude Code plugin: skill instructions
(`skills/*/SKILL.md`) and a distribution `.mcp.json` that points Claude Code at
an [arknet](https://github.com/kogn-io/arknet) MCP server. It contains no
server code and runs nothing on its own -- installing the plugin only adds
skills to Claude Code's context and a client-side MCP connection entry.

Reports about the skill content itself (e.g. a skill instruction that could be
made to act against the user's interest) are in scope here. Reports about the
arknet MCP server it connects to -- the daemon, its trust boundary, or the
tools it exposes -- belong in the [arknet security
policy](https://github.com/kogn-io/arknet/security/policy) instead.

## Supported versions

The project is pre-1.0 and still evolving. Only the latest released version
receives fixes; there is no back-porting to older versions.
