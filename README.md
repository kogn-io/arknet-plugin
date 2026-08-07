# arknet plugin

A Claude Code plugin for [arknet](https://github.com/kogn-io/arknet) -- DDD
architecture models that machines understand. This repository ships the
Claude Code integration (skills + distribution MCP config) only; the model
store and its tools live in the `arknet` MCP server, a separate project with
its own release cycle.

## Table of Contents

- [Skills](#skills)
  - [`/arknet:adr`](#arknetadr)
  - [`/arknet:legacy-adr`](#arknetlegacy-adr)
  - [`/arknet:req-interview`](#arknetreq-interview)
  - [`/arknet:bc-audit`](#arknetbc-audit)
  - [`/arknet:context-map`](#arknetcontext-map)
  - [`/arknet:health-check`](#arknethealth-check)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Compatibility check](#compatibility-check)
- [Getting started](#getting-started)
- [MCP Tools](#mcp-tools)
  - [Requirements](#requirements-1)
  - [Use cases](#use-cases)
  - [Glossary](#glossary)
  - [Bounded contexts](#bounded-contexts)
  - [Architecture decisions](#architecture-decisions)
  - [Traceability and analysis](#traceability-and-analysis)
  - [Generic store access](#generic-store-access)
- [Contributing](#contributing)
- [License](#license)

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
`adr_set_status` supports `PROPOSED -> ACCEPTED`, `PROPOSED -> REJECTED`, and
`ACCEPTED -> DEPRECATED`; `Superseded` is still not a settable status --
`adr_supersede` records the relation without touching the superseded
decision's status. Judging whether a decision is still in force therefore
means checking the `supersedes`/`superseded by` fields, not the status alone.

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
requirements, constraints, use cases, and glossary terms in dialogue --
against arknet's store tools (`req_add`/`constraint_add`/`uc_add`/`term_add`),
not markdown tables -- until a shared, testable understanding is reached. Two
entry points: greenfield (an idea or wish) and brownfield (attach an existing
codebase and let the code raise questions).

The same skill also runs a **full-set audit**: on a phrasing like "review the
requirements relentlessly" or "are they complete/consistent", it first runs
`orphan_check`/`trace_matrix` as a mandatory automated pass -- surfacing
dangling links and orphaned terms that a content read alone would miss --
then walks the entire store (requirements, use cases, glossary) one item
at a time against a fixed checklist: the SOPHIST/Rupp linguistic-defect
filter (passive voice without an actor, nominalisation, incomplete
comparatives, universal quantifiers, underspecified conditions), the
ISO/IEC/IEEE 29148 quality attributes (completeness, unambiguity,
consistency, testability, dependencies, priority differentiation), and --
for glossary terms -- implementation-free, architecture-decision-free and
config-free definitions. It
interrogates the user on every gap it finds.

### `/arknet:bc-audit`

Audits an already-filled requirements/use-case/glossary store for
emergent Bounded Context candidates -- it is an **audit**, never a
greenfield "which contexts does your system need" interview. Bounded
Context boundaries are meant to emerge from language collisions already
present in a filled store, not be drawn on a blank whiteboard before
the domain vocabulary exists.

Reads `actor_usecase_matrix` (which use cases share an actor) and
`term_cooccurrence` (which glossary terms are named together, and which
never are) as raw, unclustered data -- the same "facts in, judgement stays
with the agent and the user" discipline `orphan_check`/`trace_matrix`
already apply in `/arknet:req-interview`. Presents each candidate
collision one at a time, own assessment first, then asks whether it is a
deliberate boundary or a coincidental clustering; only on confirmation
does it write a Bounded Context (`bc_add`) and link its glossary terms
(`bc_link_term`), followed by an `impact_analysis` ripple check. Out of
scope: tactical design (Aggregate/Entity/Value Object/Domain Event), which
has no tool surface yet, and context-map relationship types
(Partnership/Anti-Corruption Layer/...), which `/arknet:context-map` covers
instead.

### `/arknet:context-map`

Elicits the DDD context-map relationship (Partnership, Shared Kernel,
Customer-Supplier, Conformist, Anti-Corruption Layer, Open Host Service,
Published Language, Separate Ways) between two **already-existing** Bounded
Contexts and records confirmed ones via `bc_link_context`. Companion to
`/arknet:bc-audit`: that skill decides *where* a boundary sits, this one
decides *how* two already-drawn boundaries relate.

Reads `bc_list` and `resource_get` as facts -- the pool of contexts to pair,
and any relationship already recorded for a pair -- before proposing
anything; the classification judgement stays with the user, same discipline
as `/arknet:bc-audit`. For the five asymmetric relationship types
(`CUSTOMER_SUPPLIER`, `CONFORMIST`, `ANTICORRUPTION_LAYER`,
`OPEN_HOST_SERVICE`, `PUBLISHED_LANGUAGE`) it also confirms which context is
upstream and which is downstream before writing; for the three symmetric
ones (`PARTNERSHIP`, `SHARED_KERNEL`, `SEPARATE_WAYS`) it says plainly that
the tool's upstream/downstream fields are bookkeeping only, not a real
asymmetry. `bc_link_context` is not idempotent -- calling it twice for the
same pair creates a second edge rather than updating the first -- so the
skill checks for an existing relationship before writing rather than after.
Out of scope: drawing or judging where a Bounded Context boundary sits
(`/arknet:bc-audit`'s job) and tactical design, which has no tool surface
yet.

### `/arknet:health-check`

A **read-only triage layer** for vague overall-status questions -- "is
everything okay?", "is the model consistent?", "anything left to do?" -- that
name no specific concern and therefore match none of the skills above by
name. It never writes to the store and never runs an interrogation dialogue
itself; it reads the existing fact-tools and routes to the skill that
actually resolves each finding.

Reports two kinds of finding, always visibly separated: **hard facts** --
`orphan_check`/`trace_matrix` (dangling links, orphaned terms, untraced
requirements) and `adr_list` filtered to `PROPOSED` (decisions still waiting
on accept/reject) -- stated plainly, no judgement needed; and **hints** -- a
Bounded Context with no `bc_link_context` edge recorded (`bc_list` against
`resource_get`), phrased as a question ("worth a look with
`/arknet:context-map`?"), never as a defect on par with an orphaned
requirement. Each finding names the specialist skill that would resolve it
(`/arknet:req-interview` full-set-audit mode, `/arknet:adr`,
`/arknet:context-map`) rather than starting that skill's dialogue itself.

Deliberately out of scope for now: a staleness signal for `/arknet:bc-audit`
(reading `actor_usecase_matrix`/`term_cooccurrence` for collisions that
emerged "since the last audit run") -- neither tool carries a timestamp, and
a store-size heuristic would fake a precision the store cannot back up.

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

## Compatibility check

This plugin and the arknet MCP server release independently, so a skill can
occasionally expect a tool an older connected server doesn't have yet. A
`SessionStart` hook checks the live tool set against what the shipped skills
need and, once per session, warns if something's missing -- naming the
affected skill so you know to update the arknet-mcp daemon rather than
wonder why a skill is failing. The check is silent otherwise: no server
reachable, or everything present, produces no extra output.

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
deciding from a position, not a blank prompt -- until a requirement, constraint,
use case or glossary term is testable and unambiguous. Only then does it write
anything (`req_add`/`constraint_add`/`uc_add`/`term_add` behind the scenes;
you see the resulting codes, e.g. `FR-1`, `TERM-3`, `UC1`, not the raw calls).
A shortened example:

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

Later, three more entry points build on the same store:

- `/arknet:adr` -- once a HOW decision needs recording (which datastore/
  library/pattern, and why), not part of the requirements interview.
- Asking the req-interview skill to **"review the requirements/use cases/
  glossary relentlessly"** re-runs it as a full-set audit instead of an
  intake: it checks structural gaps (`orphan_check`/`trace_matrix`) and then
  every item against a fixed linguistic and ISO 29148 quality checklist --
  useful once the store has grown past a handful of entries.
- `/arknet:bc-audit` -- once the store holds enough requirements/use
  cases/terms for language collisions to emerge, audits it for Bounded
  Context candidates instead of asking you to draw boundaries on a blank
  whiteboard. See below for the full protocol.
- `/arknet:context-map` -- once at least two Bounded Contexts exist, elicits
  how they relate (Partnership, Customer-Supplier, Anti-Corruption Layer,
  ...) and records the confirmed relationship. See below for the full
  protocol.
- `/arknet:health-check` -- for a vague "is everything okay?"/"what's the
  status?" question that names none of the above by itself. Reads the same
  fact-tools (`orphan_check`, `trace_matrix`, `adr_list`, `bc_list`) and
  routes to whichever of the skills above resolves each finding, instead of
  making you know which one to pick first.

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
- `req_update` -- correct an existing requirement's title, description,
  priority or acceptance criteria (append new ones, or patch the wording of
  existing ones by position).
- `req_set_status` -- change lifecycle status (`PROPOSED` -> `ACCEPTED`).
- `req_link_term` -- link a requirement to a glossary term it uses.
- `req_schema` -- describe the requirement vocabulary (types, statuses,
  priorities) as data, so a client does not have to guess the accepted values.

### Constraints

- `constraint_add` -- register a non-negotiable, externally imposed
  requirement (title, normative statement, type -- `TECHNICAL`, `BUSINESS`
  or `REGULATORY`). No status tool -- a constraint carries no lifecycle.
- `constraint_update` -- correct an already-created constraint's title and/or
  statement, or state either of them in a further language. The type, and the
  `TCON-`/`BCON-`/`RCON-` code that follows from it, stay fixed at creation.
- `constraint_get` / `constraint_list` -- fetch one / list all constraints.
- `req_link_constraint` -- link a requirement to the constraint that binds
  it.

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
- `bc_link_context` -- record a directed context-map relationship
  (Partnership, Shared Kernel, Customer-Supplier, Conformist,
  Anti-Corruption Layer, Open Host Service, Published Language, or
  Separate Ways) between two existing bounded contexts.

### Architecture decisions

- `adr_add` -- record a new architecture decision (context, decision,
  consequences, considered options); always starts `PROPOSED`.
- `adr_get` / `adr_list` -- fetch one / list all decisions, with both
  directions of the `supersedes` relation.
- `adr_set_status` -- change lifecycle status; supports
  `PROPOSED` -> `ACCEPTED`, `PROPOSED` -> `REJECTED`, and
  `ACCEPTED` -> `DEPRECATED`.
- `adr_supersede` -- record that one decision replaces an older one.

### Traceability and analysis

- `trace_matrix` -- for every requirement: which glossary terms it uses and
  which use case(s) realise it.
- `impact_analysis` -- what is transitively affected if a given requirement,
  term, use case or architecture decision changes.
- `orphan_check` -- find requirements that no use case realises, glossary
  terms that are never referenced, and constraints that no requirement is
  bound by.
- `actor_usecase_matrix` -- raw bipartite view: which use cases each actor
  appears in (`primaryActor`/`supportingActor`), and which actors each use
  case names. No clustering or judgement -- data for `/arknet:bc-audit`.
- `term_cooccurrence` -- which glossary terms are named together in the same
  requirement/use-case text, and which never are -- raw data for spotting a
  homonym (same term, different meaning per context) vs. a true duplicate.

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
