# arknet plugin

A Claude Code plugin for [arknet](https://github.com/kogn-io/arknet) -- DDD
architecture models that machines understand. This repository ships the
Claude Code integration (skills + distribution MCP config) only; the model
store and its tools live in the `arknet` MCP server, a separate project with
its own release cycle.

## Table of Contents

- [Skills](#skills)
  - [`/arknet:init`](#arknetinit)
  - [`/arknet:adr`](#arknetadr)
  - [`/arknet:req-interview`](#arknetreq-interview)
  - [`/arknet:bc-audit`](#arknetbc-audit)
  - [`/arknet:context-map`](#arknetcontext-map)
  - [`/arknet:health-check`](#arknethealth-check)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Compatibility check](#compatibility-check)
- [Project anchor report](#project-anchor-report)
- [Export freshness nudge](#export-freshness-nudge)
- [Getting started](#getting-started)
- [MCP Tools](#mcp-tools)
  - [Projects](#projects)
  - [Requirements](#requirements-1)
  - [Constraints](#constraints)
  - [Actors](#actors)
  - [Roles](#roles)
  - [Use cases](#use-cases)
  - [Glossary](#glossary)
  - [Bounded contexts](#bounded-contexts)
  - [Architecture decisions](#architecture-decisions)
  - [Traceability and analysis](#traceability-and-analysis)
  - [Generic store access](#generic-store-access)
- [Contributing](#contributing)
- [License](#license)

## Skills

### `/arknet:init`

A **one-time onboarding skill** for a project that is about to use arknet.
Two jobs, and the first is the reason it exists.

It appends a short **routing block** to the project's own `CLAUDE.md`
(creating the file if there is none): this project's architecture model --
requirements, use cases, glossary, bounded contexts, ADRs, constraints --
lives in the arknet store, not in files, and is maintained through the
`/arknet:*` skills. Without that sentence a session only finds out where the
model lives once a skill trigger happens to fire; before that it writes a
`docs/adr/0001-....md` and no one notices. The block carries nothing the
store already holds (label, languages, anchor, description -- a copy
drifts), no tool lists, no version numbers, and deliberately no export path:
an export is a snapshot out of the store, never a source for it. It is
wrapped in an HTML-comment marker pair so a later run recognises and replaces
it in place instead of appending a second copy, and it never touches the rest
of the file -- Claude Code's built-in `/init` may run before or after, in
either order.

Second, it makes the current directory **resolve to the right project** in the
store. That is a choice between three tools, not one call: `project_add` for a
genuinely new project, `project_attach_anchor` when the same project is
already registered under another directory (a git worktree, a second
checkout, another IDE workspace), and `project_adopt` for a dataset that
already holds data but no registration. The wrong one does not fail --
`project_add` from a worktree silently creates a *second* project, and the
tool surface has no `project_delete` to undo it -- while the right one, called
naively, does: `project_attach_anchor` resolves the project through the
caller's own anchor and needs `callerAnchor` from a directory that is not
registered yet. The skill proposes the case it reads from
`project_list` and lets the user confirm it before writing. For a project that
already resolves, it shows the state and offers `project_update` -- in
particular for an absent `languages` set, without which `store_check`'s
language check reports `LANGUAGE: not checked` and is silently off.

Same dialogue discipline as `/arknet:req-interview`: one question at a time,
each with the skill's own proposal attached (label from the repository name,
languages from the languages the project's docs are actually written in),
never a blank prompt.

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
back via `addressesRequirements`. Linking a decision to a bounded context
(`affectsContexts`) follows the same targeting discipline: only a context the
decision actually binds gets the edge, never every context that happens to
exist, and a genuinely project-wide decision -- the composition root, the
build technique, a project-wide convention -- gets no context edge at all,
even though it technically touches every context.

The same check is **R0 of the review**, ahead of R1-R8: a record that fails it
is proposed for `adr_delete` -- a `PROPOSED` one, and an `ACCEPTED` one no
other decision points at. There is no status for "should never have been an
ADR" (`DEPRECATED` says something else), and the deletion stays the user's
call. And it is stated once more before `adr_set_status` moves a decision to
`ACCEPTED`, the moment its text freezes.

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
only while a decision is `PROPOSED` -- from `ACCEPTED` on, what stays writable is
its reference lists (`addressesRequirements`/`affectsContexts`/`usesTerms`/`relatedTo`),
a further language for a field that never carried it (a translation, not a
correction), and a consequence or considered option *appended* to what is
already recorded. The `PROPOSED` window applies to taking a consequence or
considered option out again by position
(`removeConsequencePositions`/`removeConsideredOptionPositions`), with no
translation exemption.
`adr_delete` removes a decision entered by mistake -- a `PROPOSED` one, or an
`ACCEPTED` one no other decision points at -- but explicitly not a `REJECTED`
one: "considered and rejected" is itself a decision worth keeping. The skill
still confirms content with the user before writing, rather than relying on
the correction window.

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

### `/arknet:req-interview`

A relentless requirements-interview skill. Elicits functional/non-functional
requirements, constraints, use cases, and glossary terms in dialogue --
against arknet's store tools (`req_add`/`constraint_add`/`uc_add`/`term_add`),
not markdown tables -- until a shared, testable understanding is reached. Two
entry points: greenfield (an idea or wish) and brownfield (interrogate an
existing codebase and let the code raise questions). Either way the project
has to resolve to a project in the store first -- if it does not, the skill
stops and points at `/arknet:init` rather than guessing a registration call.

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

Reads `role_usecase_matrix` (which use cases share a role) and
`term_cooccurrence` (which glossary terms are named together, and which
never are) as raw, unclustered data -- the same "facts in, judgement stays
with the agent and the user" discipline `orphan_check`/`trace_matrix`
already apply in `/arknet:req-interview`. Every cluster found this way is
then tested for a language break before it becomes a candidate: does the
same fact or concept get different rules on each side of the split? A
clustering that traces only to who is responsible for it, which module it
lives in, or how much data passes through it -- with no such rule
difference -- is reported as an observation without a context proposal,
not presented for confirmation. Candidates that do clear the test are
presented one at a time, own assessment first naming the language break;
the skill then asks whether it is a deliberate boundary or a coincidental
clustering, and only on confirmation does it write a Bounded Context
(`bc_add`) and link its glossary terms (`bc_link_term`), followed by an
`impact_analysis` ripple check. Out of scope: tactical design
(Aggregate/Entity/Value Object/Domain Event), which has no tool surface
yet, and context-map relationship types (Partnership/Anti-Corruption
Layer/...), which `/arknet:context-map` covers instead.

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
`orphan_check`'s orphaned-requirements, unreferenced-terms and
unbound-constraints lists, `trace_matrix` (untraced requirements), `adr_list`
filtered to `PROPOSED` (decisions still open -- open, not waiting to be
accepted: `/arknet:adr` weighs a record's right to exist before its status,
and deleting one is a legitimate outcome while it is still `PROPOSED`), and
`adr_check`'s `Facts` block (what is mechanically decidable about the ADR
corpus) -- stated plainly, no judgement needed; and **hints** -- a Bounded
Context with no `bc_link_context` edge recorded (`bc_list` against
`resource_get`), `orphan_check`'s fourth list (terms named in text without a
backing edge -- its word-boundary match is deliberately left unsharpened,
because a wrong edge costs more than a missed one, so it recurs on an
everyday word used in its ordinary sense as often as on a real gap), and
`adr_check`'s `Suspicions`/not-checked list, each phrased as a question
("worth a look with `/arknet:context-map`?"/"worth a look with
`/arknet:req-interview`?"/"worth a look with `/arknet:adr`?"), never as a
defect on par with an orphaned requirement or a `Fact` -- and never as a
proposed status change. Each finding names the specialist skill that would
resolve it (`/arknet:req-interview` full-set-audit mode, `/arknet:adr`,
`/arknet:context-map`) rather than starting that skill's dialogue itself.

Deliberately out of scope for now: a staleness signal for `/arknet:bc-audit`
(reading `role_usecase_matrix`/`term_cooccurrence` for collisions that
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
occasionally expect a tool, or a tool parameter, that an older connected
server doesn't have yet. The plugin ships a generated snapshot of what the
server offered when it was last checked (`hooks/arknet-tools-baseline.json`,
one line per tool with its sorted parameters, refreshed by hand from a
repo checkout -- see `CONTRIBUTING.md`), and a `SessionStart` hook compares
the live server against it for every tool a shipped skill's `SKILL.md`
actually names, warning if a tool or one of its parameters has gone missing
-- naming the affected skill so you know to update the arknet-mcp daemon
rather than wonder why a skill is failing. It runs on startup, on
`--resume` and after `/clear` -- the three points at which the session
either connects afresh or continues from an empty context that no longer
carries an earlier warning. Context compaction and a forked session keep
that context, so they are left out rather than repeating a warning the
session already has. The check is silent otherwise: no server reachable,
or everything present, produces no extra output.

## Project anchor report

A second, separate `SessionStart` hook reports which registered arknet
project the current directory resolves to as an anchor -- "this directory
resolves to project X", or, if no registered project has this directory as
an anchor, that it has no project and a pointer at `/arknet:init`, plus a
hint if a parent directory is a registered anchor of some project (you
probably started in a subdirectory of it). This matters because a git
worktree or a second checkout of an already-registered project is not
itself a registered anchor, and a plain `project_add` from there would
silently create a second project -- there is no `project_delete` to undo
that. Seeing the resolved label (or its absence) makes the missing anchor
visible before that mistake happens.

It runs on startup, on `--resume`, after `/clear` and after context
compaction -- one point more than the compatibility check above, because
what it reports is orientation information rather than a warning: its value
depends on the line still being in front of the session. `/clear` empties
the context outright, and compaction keeps the context only as a rewritten
summary, from which a one-line orientation note can fall out without
anything about the anchor having changed -- so both repeat it. A forked
session takes its context along verbatim, so that case is left out, same
as for the compatibility check. The check is silent otherwise: no
server reachable, or the response is malformed, produces no extra output.

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
above), start Claude Code from your project's directory -- that directory is
the anchor every call is routed by. Session start reports which project (if
any) that directory resolved to, see [Project anchor
report](#project-anchor-report).

**Onboard the project, once:**

```
/arknet:init
```

It decides which registration call this directory actually needs
(`project_add`, `project_adopt` or `project_attach_anchor`), asks for the
label, the default language, the set of languages the model will be
maintained in and an optional description -- one question at a time, each
with its own proposal -- and appends the routing block to your project's
`CLAUDE.md` that tells every later session the model lives in the store, not
in files.

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
  fact-tools (`orphan_check`, `trace_matrix`, `adr_list`, `adr_check`,
  `bc_list`) and routes to whichever of the skills above resolves each
  finding, instead of making you know which one to pick first.

## MCP Tools

arknet manages DDD architecture models -- requirements, use cases, a
ubiquitous-language glossary, and bounded contexts -- as an RDF/SKOS store with
SHACL write validation. All writes are validated against arknet's shapes;
unknown or ambiguous references (e.g. a role or actor code that does not
exist yet) are rejected with a didactic error rather than silently accepted.

### Projects

A project is what an anchor -- your session's start directory, sent as the
`X-Arknet-Project-Anchor` header -- resolves to; every other tool below
operates inside the project the call comes from. Prefer `/arknet:init` over
calling these directly: three of them can register a project, only one of
them is right in a given situation, and there is no `project_delete`.

- `project_list` -- every registered project with its anchors, default
  language, maintained languages and description, plus the datasets in the
  store that no project claims yet (the candidates for `project_adopt`).
- `project_add` -- register a new project (`label`, optional
  `defaultLanguage`, optional `languages`, optional `description` with its
  `language` tag). The calling directory becomes the project's first anchor;
  the optional `anchor`/`anchorType` are only for clients that cannot supply
  one.
- `project_adopt` -- claim an existing, unregistered dataset (`datasetId` as
  `project_list` reports it, plus a `label`) as the project this call comes
  from -- for data written before projects were registered, or restored from
  a backup. The dataset keeps its identity and its data.
- `project_attach_anchor` -- attach a further `anchor` to the caller's
  project, for a second directory working on the same project (a git
  worktree, another checkout, another IDE workspace). This, not
  `project_add`, is the call from a second directory -- and from there it
  needs `callerAnchor` (an anchor the project already has), because the
  caller's own directory does not resolve to any project yet.
- `project_update` -- correct the caller's project: `description` (+
  `language`), `defaultLanguage`, and `languages`, the set the project
  undertakes to maintain its model in. `languages` is the target state
  `store_check` compares against, and `defaultLanguage` has to be one of its
  members; passing an empty list removes the set, omitting it leaves it
  untouched.
- `project_rename` -- change the project's human-readable `label`. Identity
  and anchors are unaffected.
- `project_export` -- back up the store as a timestamped `.trig` file (with
  provenance, self-description and a trailing export-metadata graph naming
  the server version, build time, export time and every shipped ontology
  module's version) into the server's export directory. Exports every
  registered project by default; `projectOnly` narrows it to the project
  this call addresses. No matching import/restore tool yet.

### Requirements

- `req_add` -- register a functional/non-functional requirement (title,
  normative "the system shall ..." description, type, at least one testable
  acceptance criterion; optional MoSCoW priority, quality category and
  rationale -- why the requirement exists, not a restatement of what it
  does).
- `req_get` / `req_list` -- fetch one / list all requirements; both take an
  optional `displayLocale` choosing which language variant is shown. The list
  tools also say when they fell back: an entry missing in the requested
  language is shown under another one with an inline `[fallback: ...]` tag, so
  a gap in the kept language no longer looks like a present translation.
- `req_update` -- correct an existing requirement's title, description,
  rationale, priority or acceptance criteria (append new ones, patch the
  wording of existing ones by position, or remove them by position -- the
  ones after a removed criterion move up, at least one must stay), or state
  the fields it touches in a further language. Also the way a requirement gets its rationale recorded
  after the fact if it was registered without one.
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
- `constraint_get` / `constraint_list` -- fetch one / list all constraints;
  both take an optional `displayLocale`, and the list marks a fallen-back
  entry as described under `req_list`.
- `constraint_delete` -- remove the whole constraint resource, not just a
  correction; the intended use is undoing a misclassification, a record
  that turns out to be something the project decided itself and belongs in
  `adr_add` or `req_add` instead. Rejected while a requirement or use case
  still references it via `constrainedBy`. The `TCON-`/`BCON-`/`RCON-` code
  stays taken.
- `req_link_constraint` -- link a requirement to the constraint that binds
  it.

### Actors

- `actor_add` -- register an actor: someone or something that can act on the
  system under description, hold an interest in it, or both (a regulator or
  a department that never touches the system counts as much as a user).
  Takes a type (`HUMAN`, `SYSTEM`, `LEGAL` or `GROUP`), a name and an
  optional description, and an optional `language`. `language` is the
  BCP-47 tag `name`/`description` are written in, falling back to the
  project's configured default language if omitted; state the actor in a
  second language with `actor_update` afterwards. Unlike a glossary term's
  `skos:prefLabel`, an actor's `name` is not required to be the same word
  under every language tag -- it may be worded differently per language.
  The result is an `ACTOR-n` code. An actor is a resource in its own right
  and needs no glossary entry -- `term_add` it separately if its name is
  also a term worth defining.
- `actor_get` / `actor_list` -- fetch one / list all actors; both take an
  optional `displayLocale`, and the list marks a fallen-back entry as
  described under `req_list`.
- `actor_update` -- correct an already-created actor's name and/or
  description in place, or state either in a further language. The type,
  and the `ACTOR-n` code, stay fixed at creation.
- `actor_delete` -- remove the whole actor resource, not just a correction;
  rejected while a role still lists it among its `filledBy` occupants. An
  actor that is also a glossary term keeps its glossary entry.

### Roles

A role is a resource in its own right, distinct from an actor: the actor is
the carrier (a person, an organisation, a piece of software -- exists
whether or not the project models it), the role is the named function it
acts in (exists only while occupied, defined independently of who fills
it). A use case binds to a role, never directly to an actor.

- `role_add` -- register a role: a named function in which someone or
  something acts or holds an interest, named independently of who fills it.
  Takes a name (min. 2 characters, prose -- unlike an actor's plain-text
  name, this carries a language tag), an optional description, an optional
  `filledBy` (`ACTOR-n` codes of the actors occupying it from the start --
  a role may stay unfilled) and an optional `language`; the result is a
  `ROLE-n` code, its own counter independent of `ACTOR-n`.
- `role_get` / `role_list` -- fetch one / list all roles; both take an
  optional `displayLocale`, and the list marks a fallen-back entry as
  described under `req_list`.
- `role_update` -- correct an already-created role's name and/or
  description in place, state either in a further language, and/or replace
  its occupants (`filledBy`, replaced wholesale; an empty list clears every
  occupant, omitting it leaves occupancy unchanged). The `ROLE-n` code stays
  fixed at creation.
- `role_delete` -- remove the whole role resource and every triple it
  carries, not just a correction; the `ROLE-n` code stays taken.

### Use cases

- `uc_add` -- register a complete Cockburn-style use case in a single call
  (goal-in-context, primary/supporting roles, ordered main flow, optional
  precondition/postcondition/extensions); steps can reference the
  requirements they realise. Primary/supporting roles are given as
  `ROLE-n` codes (see Roles above), not actor codes or names.
- `uc_get` / `uc_list` -- fetch one / list all use cases; both take an
  optional `displayLocale`, and the list marks a fallen-back entry as
  described under `req_list`.
- `uc_update` -- correct an existing use case's title/goal/scope/trigger/
  pre-/postcondition, its extensions, the text or `realises` references of
  individual steps, and its primary/supporting roles (each replaced
  wholesale; the primary role cannot be cleared, an empty supporting-roles
  list clears it), append main-flow steps after the existing ones or remove
  them by position (the ones after a removed step move up, at least one must
  stay), or state the fields it touches in a further language -- reordering
  the main flow is still out of scope.
- `uc_link_term` -- link a use case to a glossary term it uses.
- `uc_link_constraint` -- link a use case to the constraint that binds it.

### Glossary

- `term_add` -- register a ubiquitous-language term as a SKOS concept;
  optionally name an already-existing term it specializes (`broader`,
  `skos:broader`) and/or terms it is associatively connected to without
  either being a kind of the other (`related`, `skos:related` -- symmetric,
  naming it on one side is enough).
- `term_get` / `term_list` -- fetch one / list all glossary terms; both take
  an optional `displayLocale`, and the list marks a fallen-back entry as
  described under `req_list`.
- `term_update` -- correct an existing term's label, definition, broader
  term or related peers in place, or state label/definition in a further
  language, keeping its identity and every link into it. `broader` and
  `related` are the exceptions to "omitted = unchanged": an empty string
  (`broader`) or an empty list (`related`) explicitly clears what is set.
- `term_delete` -- remove the whole term resource (label and definition in
  every language), not just a correction; rejected while anything still
  references it: a requirement's, use case's or architecture decision's
  `usesTerm`, a bounded context's ubiquitous-language link, or another
  term's `broader`/`related`. Remove those edges first (`req_update`/
  `uc_update`, `adr_update`, `bc_link_term`, `term_update` on the other
  term).

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
  `displayLocale`, and `adr_list` carries the same `[fallback: ...]` tag as
  the other list tools.
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
  the call writes a language that field never carried yet; a consequence or
  considered option is removed by position (`removeConsequencePositions`/
  `removeConsideredOptionPositions`, later entries move up) only while
  `PROPOSED`, with no translation exemption; reference lists
  (`addressesRequirements`/`affectsContexts`/`usesTerms`/`relatedTo`) in
  every status.
- `adr_check` -- check the whole corpus and report what is mechanically
  decidable, without changing anything: `Facts` (a `decisionDate` on a
  decision not yet taken, no consequence/no considered option recorded, an
  option space with nothing `CHOSEN` on a decision that was taken, a
  decision addressing no requirement and affecting no bounded context --
  expected, not a defect, for a decision that is genuinely project-wide, an
  `ADR-n` in the prose the project does not hold or no edge backs) and
  `Suspicions` (tracker references, address/port literals, status prose,
  near-identical titles -- each a hint, not a defect). Names, in its own
  output, what it does not check: bundled decisions, contradiction between
  records, whether a consequence has substance.
- `adr_delete` -- remove a decision entered by mistake: `PROPOSED`, or
  `ACCEPTED` with no other decision pointing at it; `REJECTED`,
  `DEPRECATED` and `SUPERSEDED` are explicitly not deletable, nor is a
  decision another one still points at via `supersededBy`/`relatedTo`.

### Traceability and analysis

- `trace_matrix` -- for every requirement: which glossary terms it uses and
  which use case(s) realise it.
- `impact_analysis` -- what is transitively affected if a given requirement,
  term, use case or architecture decision changes.
- `orphan_check` -- four lists: requirements that no use case realises;
  glossary terms that are never referenced (by a requirement, a use case, a
  bounded context's ubiquitous language, or another term's broader or
  related term);
  text that names a term without its backing edge -- a use case's goal,
  scope, trigger, precondition, postcondition and every step/extension text
  count as its text, and naming its own primary/supporting role there is
  not a gap; an ADR's context, decision, consequences, and options are scanned
  as well; and constraints that no requirement or use case is bound by.
- `role_usecase_matrix` -- raw bipartite view: which use cases each role
  appears in (`primaryRole`/`supportingRole`), which roles each use case
  names, and which actors occupy each role (`filledBy`). No clustering or
  judgement -- data for `/arknet:bc-audit`.
- `term_cooccurrence` -- which glossary terms are named together in the same
  requirement/use-case text, and which never are -- raw data for spotting a
  homonym (same term, different meaning per context) vs. a true duplicate.

### Generic store access

- `store_overview` -- workspace-wide digest (resource/triple/type counts, one
  line per resource) plus a self-contained HTML report written to disk.
- `store_check` -- check this project's stored model against what it
  declares about itself; read-only, changes and refuses nothing. `checks`
  selects which checks to run (a list of names, omit or pass an empty list
  to run all -- today there are two). `LANGUAGE` reports every field
  carrying at least one language-tagged value but not one for each language
  `project_update`'s `languages` declares, one row per resource and field
  naming the missing tags; with no declared `languages` set there is no
  target state to compare against, so it reports `LANGUAGE: not checked`
  instead of a clean result. `ROLE_TERM_DUPLICATE` reports every role and
  glossary term that carry the same name, compared case-insensitively and
  trimmed across every language variant of the role's name against the
  term's label -- a report only, never a rejection, since the two resource
  types stay independent of each other.
- `resource_get` -- fetch all statements (outgoing and incoming) of a single
  resource.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please also read our
[Code of Conduct](CODE_OF_CONDUCT.md) and [Security Policy](SECURITY.md).

## License

[Apache License 2.0](LICENSE).
