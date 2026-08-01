# arknet plugin

A Claude Code plugin for [arknet](https://github.com/kogn-io/arknet) -- DDD
architecture models that machines understand. This repository ships the
Claude Code integration (skills + distribution MCP config) only; the model
store and its tools live in the `arknet` MCP server, a separate project with
its own release cycle.

## Skills

### `/arknet:adr`

Maintains Architecture Decision Records as first-class resources in the arknet
store (`arkarch:ArchitectureDecisionRecord`), via arknet's `adr_add`/
`adr_list`/`adr_get`/`adr_set_status`/`adr_supersede` MCP tools -- not
Markdown files. Keeps every ADR a record of a durable decision and its
lasting consequences -- never a status report, never an implementation
snapshot.

**One decision per record**, still enforced by discipline rather than the
store: the independence test -- "could a point have gone the other way
without changing the point before it?" -- decides whether it is its own ADR.
`adr_supersede` points at the whole record, so a bundled decision cannot be
superseded in part. Implementation detail -- class names, signatures, literal
parameter values -- is kept out of `decision`/`consequences` for the same
reason files were kept clean of it: a rename should never falsify a decision.

**The lifecycle the tools implement is narrower than the ontology.**
`adr_set_status` only supports `PROPOSED -> ACCEPTED`; there is no tool call
for `Rejected`/`Deprecated`, and `adr_supersede` records the relation without
touching the superseded decision's status (tracked as
[kogn-io/arknet#91](https://github.com/kogn-io/arknet/issues/91)). Judging
whether a decision is still in force therefore means checking the
`supersedes`/`superseded by` fields, not the status alone.

**No correction path.** There is no update or delete tool -- a `PROPOSED`
decision entered with the wrong text stays as it is. The skill confirms
content with the user before writing, rather than writing speculatively.

### `/arknet:legacy-adr`

The file-based predecessor of `/arknet:adr`, kept for projects that still
maintain their ADRs as Markdown under `docs/adr/` and have not migrated to
the store yet. Same durable-decision discipline (one decision per record,
immutability from `Accepted` on, an index at `docs/adr/README.md`), applied
to files instead of store resources. New projects should use `/arknet:adr`;
this skill exists only for backward compatibility during the transition.

### `/arknet:req-interview`

A relentless requirements-interview skill. Elicits functional/non-functional
requirements, use cases, and glossary terms in dialogue -- against arknet's
store tools (`req_add`/`uc_add`/`term_add`), not markdown tables -- until a
shared, testable understanding is reached. Two entry points: greenfield (an
idea or wish) and brownfield (attach an existing codebase and let the code
raise questions).

The same skill also runs a **full-set audit**: on a phrasing like "review the
requirements relentlessly" or "are they complete/consistent", it first runs
`orphan_check`/`trace_matrix` as a mandatory automated pass -- surfacing
dangling links and orphaned terms that a content read alone would miss --
then walks the entire register (requirements, use cases, glossary) one item
at a time against a fixed checklist: the SOPHIST/Rupp linguistic-defect
filter (passive voice without an actor, nominalisation, incomplete
comparatives, universal quantifiers, underspecified conditions), the
ISO/IEC/IEEE 29148 quality attributes (completeness, unambiguity,
consistency, testability, dependencies, priority differentiation), and --
for glossary terms -- implementation-free and config-free definitions. It
interrogates the user on every gap it finds.

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
        "X-Arknet-Project-Anchor": "${PWD}"
      }
    }
  }
}
```

The `X-Arknet-Project-Anchor` header routes each call to the arknet project
anchored at your current session's start directory -- the daemon is shared
across all projects on the machine, one project per repository.

## Getting started

Once the daemon is running and the plugin is installed and configured (see
above), start Claude Code from your project's directory -- that directory
becomes the project's anchor.

**Register the project, once:**

```
project_add(label: "my-project")
```

Then start the actual work with the skill, not with the raw tools:

```
/arknet:req-interview
```

Tell it what you want to build, in a sentence. It interviews you -- one
question at a time, always with its own suggested answer attached so you are
deciding from a position, not a blank prompt -- until a requirement, use case
or glossary term is testable and unambiguous. Only then does it write
anything (`req_add`/`uc_add`/`term_add` behind the scenes; you see the
resulting codes, e.g. `FR-1`, `TERM-3`, `UC1`, not the raw calls). A
shortened example:

```
> /arknet:req-interview
> I want librarians to be able to check a book back in.

Skill: Before "check in" -- is "loan" already a term in your glossary, or
  should this interview define it? [...]
You:   Define it: a loan is ...
Skill: Got it -- TERM-1 "Loan". Now, "check in": what should happen if the
  book is returned damaged, or after the due date? [...]
[... interview continues, one question at a time ...]
Skill: Written: FR-1 "Close a loan when its book is returned" (done-when:
  loan marked returned with a condition, or a named failure reason), UC1
  "Check in a book" realising FR-1. No ripple into the existing set.
```

Once something is in the store, see it rendered as a model rather than as
triples:

```
store_overview
```

returns a compact digest plus the path to a self-contained HTML report
(requirements with their acceptance criteria, use cases with their flow, the
glossary, bounded contexts).

Later, two more entry points build on the same register:

- `/arknet:adr` -- once a HOW decision needs recording (which store/library/
  pattern, and why), not part of the requirements interview.
- Asking the req-interview skill to **"review the requirements/use cases/
  glossary relentlessly"** re-runs it as a full-set audit instead of an
  intake: it checks structural gaps (`orphan_check`/`trace_matrix`) and then
  every item against a fixed linguistic and ISO 29148 quality checklist --
  useful once the register has grown past a handful of entries.

## MCP Tools

arknet manages DDD architecture models -- requirements, use cases, a
ubiquitous-language glossary, and bounded contexts -- as an RDF/SKOS store with
SHACL write validation. All writes are validated against arknet's shapes;
unknown or ambiguous references (e.g. an actor label that does not exist yet)
are rejected with a didactic error rather than silently accepted.

### Requirements

- `req_add` -- register a functional/non-functional requirement (title,
  normative "the system shall ..." description, type, at least one testable
  acceptance criterion; optional MoSCoW priority, quality category, goal link).
- `req_get` / `req_list` -- fetch one / list all requirements.
- `req_set_status` -- change lifecycle status (`PROPOSED` -> `ACCEPTED`).
- `req_link_term` -- link a requirement to a glossary term it uses.
- `req_schema` -- describe the requirement vocabulary (types, statuses,
  priorities) as data, so a client does not have to guess the accepted values.

### Use cases

- `uc_add` -- register a complete Cockburn-style use case in a single call
  (goal-in-context, primary/supporting actors, ordered main flow, optional
  precondition/postcondition/extensions); steps can reference the
  requirements they realise.
- `uc_get` / `uc_list` -- fetch one / list all use cases.

### Glossary

- `term_add` -- register a ubiquitous-language term as a SKOS concept;
  optionally mark it as an actor (`HUMAN`/`SYSTEM`) so it can later be used as
  a use case's primary or supporting actor.
- `term_get` / `term_list` -- fetch one / list all glossary terms.

### Bounded contexts

- `bc_add` -- register a bounded context (name, one-sentence domain vision,
  optional owning team and strategic classification --
  core/supporting/generic domain).
- `bc_get` / `bc_list` -- fetch one / list all bounded contexts.
- `bc_link_term` -- link a bounded context to a glossary term of its
  ubiquitous language.

### Architecture decisions

- `adr_add` -- record a new architecture decision (context, decision,
  consequences, considered options); always starts `PROPOSED`.
- `adr_get` / `adr_list` -- fetch one / list all decisions, with both
  directions of the `supersedes` relation.
- `adr_set_status` -- change lifecycle status; today only
  `PROPOSED` -> `ACCEPTED`.
- `adr_supersede` -- record that one decision replaces an older one.

### Traceability and analysis

- `trace_matrix` -- for every requirement: which glossary terms it uses and
  which use case(s) realise it.
- `impact_analysis` -- what is transitively affected if a given requirement,
  term, use case or architecture decision changes.
- `orphan_check` -- find requirements that no use case realises, and glossary
  terms that are never referenced.

### Generic store access

- `store_overview` -- workspace-wide digest (resource/triple/type counts, one
  line per resource) plus a self-contained HTML report written to disk.
- `resource_get` -- fetch all statements (outgoing and incoming) of a single
  resource.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please also read our
[Code of Conduct](CODE_OF_CONDUCT.md) and [Security Policy](SECURITY.md).

## License

[Apache License 2.0](LICENSE).
