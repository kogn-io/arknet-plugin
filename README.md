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
- [Export freshness nudge](#export-freshness-nudge)
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
`adr_list`/`adr_get`/`adr_set_status`/`adr_supersede`/`adr_unsupersede`/
`adr_update`/`adr_check`/`adr_delete` MCP tools -- not Markdown files. Keeps every ADR a record of a
durable decision and its lasting consequences -- never a status report, never
an implementation snapshot.

**The decision is the user's, not the agent's.** A choice the agent made on
its own -- a library it picked, a split it judged best -- is named as such
and put to the user before `adr_add`, not written in as if already settled.
An open decision keeps `adrContext` naming the openness and `decision`
stating the agent's preference as a proposal, status `PROPOSED`; a
`PROPOSED` record whose decision the user never confirmed is a question
back to the user, not a candidate for `ACCEPTED`.

**"Is this an ADR at all?" comes before "is this a good ADR?"** Four
questions run ahead of `adr_add`: reach (structure, a contract, a dependency,
a quality attribute, or a construction technique that holds across the
project), cost of reversal, whether a real alternative existed, and whether
the core is a HOW at all -- a "must/shall" about system behaviour is a
requirement, a definition is a glossary term, a "later" is a tracker issue. A
"no" on reach or cost of reversal stops the write and names where the thing
belongs instead; the criterion is reach, not size, so "no Lombok" is one
sentence and still an architecture decision. A draft that carries a
requirement in its first half hands that half to `/arknet:req-interview`
(`req_add`/`constraint_add`) and keeps the ADR for the HOW remainder, linked
back via `addressesRequirements`.

The same check is **R0 of the review**, ahead of R1-R8: a `PROPOSED` record
that fails it is proposed for `adr_delete`, an `ACCEPTED` one is reported and
left to the user, since there is no status for "should never have been an
ADR" -- `DEPRECATED` says something else. And it is stated once more before
`adr_set_status` moves a decision to `ACCEPTED`, the moment its text freezes.

**One decision per record**, still enforced by discipline rather than the
store -- and before the write rather than in the review afterwards: the
independence test -- "could a point have gone the other way without changing
the point before it?" -- splits `decision` into its separate assertions, and
each surviving fragment becomes its own `adr_add` call. It falls on every
record written, not only on the ones someone flagged as candidates.
`adr_supersede` points at the whole record, so a bundled decision cannot be
superseded in part. Implementation detail -- class names, signatures, literal
parameter values -- is kept out of `decision`/`consequences` for the same
reason files were kept clean of it: a rename should never falsify a decision.

**`SUPERSEDED` is a real, written status.** `adr_set_status` supports
`PROPOSED -> ACCEPTED`, `PROPOSED -> REJECTED`, and `ACCEPTED -> DEPRECATED`,
and explicitly refuses `SUPERSEDED` as a target -- that transition always
needs a named successor, so it goes through `adr_supersede` instead, which
sets the older decision's status to `SUPERSEDED` and its `supersededBy` edge
together, in one write. Both decisions must already be `ACCEPTED`, and naming
a different successor for an already-superseded decision is refused. Judging
whether a decision is still in force is therefore a plain status read again;
`adr_get`'s `superseded by` field additionally names which decision replaced
it. A mistyped `adr_supersede` call has a narrow regret path back:
`adr_unsupersede`, accepted only on a `SUPERSEDED` decision, drops its
`supersededBy` edge and reverts its status to `ACCEPTED` in one write, leaving
the named successor untouched -- a correction, never a way to reverse a valid
supersession.

**Corrections are narrower than they look.** `adr_update` corrects text fields
only while a decision is `PROPOSED` -- from `ACCEPTED` on, only its reference
lists (`addressesRequirements`/`affectsContexts`/`usesTerms`/`relatedTo`) stay editable.
`adr_delete` removes a `PROPOSED` decision entered by mistake, but explicitly
not a `REJECTED` one -- "considered and rejected" is itself a decision worth
keeping. The skill still confirms content with the user before writing,
rather than relying on the correction window.

**No `ADR-n` codes in the prose.** A peer decision is connected via
`relatedTo` (or `supersededBy`/`addressesRequirements`), never by naming its
code inside `adrContext`/`decision`/consequences/considered options -- a
record cannot know the code of a decision written after it.

**A review starts with `adr_check`, not a manual reread for patterns.** Its
`Facts` block covers the mechanical part of several review rules (tracker
references, status prose, unresolved `ADR-n` mentions, missing edges, empty
consequence/option lists, nothing `CHOSEN`, a stray `decisionDate`); the
skill only judges what the tool cannot -- whether a flagged pattern is
actually a defect, whether a record bundles more than one decision, whether
two records contradict each other, whether a consequence says anything.
`Suspicions` and the tool's own not-checked list are candidates for that
judgement, never findings to act on directly, and neither ever triggers a
status change by itself.

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
requirements) and `adr_list` filtered to `PROPOSED` (decisions still open --
open, not waiting to be accepted: `/arknet:adr` weighs a record's right to
exist before its status, and deleting one is a legitimate outcome while it is
still `PROPOSED`) -- stated plainly, no judgement needed; and **hints** -- a
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

## Export freshness nudge

If your project keeps a reproducible export of the arknet store in the
working tree (a directory holding a `.trig` full dump, as produced by
`project_export`) for readers without a running server, that snapshot goes
stale the moment the store is written again. A `Stop` hook watches for this:
once per session, if a store-writing arknet tool (`adr_add`, `req_update`,
`bc_link_term`, and so on) was called and such an export directory is found
in the project, it adds a one-line reminder to regenerate the snapshot
before committing. The check is silent otherwise -- no write tool called, no
export directory found, or the nudge already fired this session produces no
extra output. The export mechanism itself (script, path convention) is not
part of this plugin; the hook only discovers an existing `.trig` snapshot,
it does not create one.

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
  existing ones by position), or state the fields it touches in a further
  language.
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
- `uc_update` -- correct an existing use case's title/goal/scope/trigger/
  pre-/postcondition, its extensions, the text or `realises` references of
  individual steps, and its primary/supporting actors (each replaced
  wholesale; the primary actor cannot be cleared, an empty supporting-actors
  list clears it), or state the fields it touches in a further language --
  not the step list's structure.
- `uc_link_term` -- link a use case to a glossary term it uses.
- `uc_link_constraint` -- link a use case to the constraint that binds it.

### Glossary

- `term_add` -- register a ubiquitous-language term as a SKOS concept;
  optionally mark it as an actor (`HUMAN`/`SYSTEM`/`LEGAL` -- the last for a
  legal person such as an organization or company, as opposed to a natural
  person acting on its behalf) so it can later be used as a use case's primary
  or supporting actor.
- `term_get` / `term_list` -- fetch one / list all glossary terms.
- `term_update` -- correct an existing term's label, definition or actor
  facet in place, or state them in a further language, keeping its identity
  and every link into it.

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

- `adr_add` -- record a new architecture decision (context, decision, a list
  of typed consequences, a list of considered options with an outcome, an
  optional `language`); always starts `PROPOSED`.
- `adr_get` / `adr_list` -- fetch one / list all decisions, with both
  directions of `supersededBy` and every related decision; take an optional
  `displayLocale`.
- `adr_set_status` -- change lifecycle status; supports
  `PROPOSED` -> `ACCEPTED`, `PROPOSED` -> `REJECTED`, and
  `ACCEPTED` -> `DEPRECATED`; refuses `SUPERSEDED` (use `adr_supersede`).
  Refuses `ACCEPTED` if the record carries considered options and not
  exactly one is `CHOSEN` -- a `PROPOSED` record is allowed to have none.
  Moving to `ACCEPTED`/`REJECTED` also stamps the decision date -- the only
  place it is set; an optional `decidedOn` backdates it to a day the
  decision was really taken.
- `adr_supersede` -- record that one decision replaces an older one; both
  must already be `ACCEPTED`. Sets the older decision's status to
  `SUPERSEDED` together with the `supersededBy` edge, in one write.
- `adr_unsupersede` -- regret path for a mistyped `adr_supersede` call; only on
  a `SUPERSEDED` decision, reverts its status to `ACCEPTED` and drops its
  `supersededBy` edge, in one write, leaving the successor untouched.
- `adr_update` -- correct an already-recorded decision; text fields (and a
  consequence's/considered option's wording) only while `PROPOSED`, unless
  the call writes a language that field never carried yet; reference lists
  (`addressesRequirements`/`affectsContexts`/`usesTerms`/`relatedTo`) in
  every status.
- `adr_check` -- check the whole corpus and report what is mechanically
  decidable, without changing anything: `Facts` (a `decisionDate` on a
  decision not yet taken, no consequence/no considered option recorded, an
  option space with nothing `CHOSEN` on a decision that was taken, a
  decision addressing no requirement and affecting no bounded context, an
  `ADR-n` in the prose the project does not hold or no edge backs) and
  `Suspicions` (tracker references, address/port literals, status prose,
  near-identical titles -- each a hint, not a defect). Names, in its own
  output, what it does not check: bundled decisions, contradiction between
  records, whether a consequence has substance.
- `adr_delete` -- remove a `PROPOSED` decision entered by mistake;
  `REJECTED` is explicitly not deletable, nor is a decision another one
  still points at via `supersededBy`/`relatedTo`.

### Traceability and analysis

- `trace_matrix` -- for every requirement: which glossary terms it uses and
  which use case(s) realise it.
- `impact_analysis` -- what is transitively affected if a given requirement,
  term, use case or architecture decision changes.
- `orphan_check` -- four lists: requirements that no use case realises;
  glossary terms that are never referenced (by a requirement, a use case, a
  bounded context's ubiquitous language, or another term's broader term);
  text that names a term without its backing edge -- a use case's goal,
  scope, trigger, precondition, postcondition and every step/extension text
  count as its text, and naming its own primary/supporting actor there is
  not a gap; an ADR's context, decision, consequences, and options are scanned
  as well; and constraints that no requirement or use case is bound by.
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
