# arknet plugin

A Claude Code plugin for [arknet](https://github.com/kogn-io/arknet) -- DDD
architecture models that machines understand. This repository ships the
Claude Code integration (skills + distribution MCP config) only; the model
store and its tools live in the `arknet` MCP server, a separate project with
its own release cycle.

## Skills

### `/arknet:adr`

Maintains Architecture Decision Records in `docs/adr/` against arknet's own
metamodel (`arkarch:ArchitectureDecisionRecord`). Keeps every ADR a record of
a durable decision and its lasting consequences -- never a status report,
never an implementation snapshot.

### `/arknet:req-interview`

A relentless requirements-interview skill. Elicits functional/non-functional
requirements, use cases, and glossary terms in dialogue -- against arknet's
store tools (`req_add`/`uc_add`/`term_add`), not markdown tables -- until a
shared, testable understanding is reached. Two entry points: greenfield (an
idea or wish) and brownfield (attach an existing codebase and let the code
raise questions).

## Requirements

- [Claude Code](https://claude.com/claude-code)
- A running arknet MCP server, reachable at `127.0.0.1:47331`. The plugin
  does not start or manage the server -- see the [arknet
  README](https://github.com/kogn-io/arknet#mcp-server) for how to run the
  daemon (Docker image recommended).

## Installation

```
/plugin marketplace add hauschel-ai-tools/claude-code-marketplace
/plugin install arknet@hauschel-plugins
```

## Configuration

The plugin ships a distribution `.mcp.json` that points Claude Code at the
arknet daemon over Streamable HTTP:

```json
{
  "mcpServers": {
    "arknet": {
      "type": "http",
      "url": "http://127.0.0.1:47331/mcp",
      "headers": {
        "X-Arknet-Workspace-Dir": "${PWD}"
      }
    }
  }
}
```

The `X-Arknet-Workspace-Dir` header routes each call to the arknet workspace
for your current session's start directory -- the daemon is shared across all
projects on the machine, one workspace per repository.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please also read our
[Code of Conduct](CODE_OF_CONDUCT.md) and [Security Policy](SECURITY.md).

## License

[Apache License 2.0](LICENSE).
