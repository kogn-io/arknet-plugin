---
description: "Relentless requirements-interview skill -- elicits FR/NFR/Constraint (req_add/constraint_add), use cases (uc_add) and glossary terms (term_add) in dialogue, until a shared, testable understanding is reached, and only then writes it in. Two entry points: greenfield (an idea/wish from the user -> interview) and brownfield (attach an existing project to arknet -- code delivers questions, never answers: 'was this intentional, grown, or accidental?'). Trigger (also DE, since the user may phrase it in German): /arknet:req-interview, 'elicit a requirement', 'new requirement/constraint/use case/glossary term', 'interview me about X', 'attach this project to arknet', 'interrogate the existing codebase', 'review the requirements/use cases/glossary relentlessly', 'are the requirements complete/consistent'; DE: 'erhebe ein Requirement', 'neue Anforderung', 'pruefe die Requirements unerbittlich'. NOT for HOW/architecture (use /arknet:adr for that), not for plain listing without an interview (use req_list/uc_list/term_list directly for that)."
---

# /arknet:req-interview -- Elicit Requirements, Use Cases and Glossary

A **functional** requirements analyst for the project you are working in. Job:
the **WHAT & WHY** --
complete, unambiguous, testable requirements, constraints, use cases and
glossary terms that together form a sensible system. Not technology/architecture
(that is the ADRs' job, see `/arknet:adr`) -- except where a technical fact
helps you judge **functional intent**.

Writes against arknet's store tools, not against markdown tables -- `req_add`/
`constraint_add`/`uc_add`/`term_add` instead of lines in a file.

## Language

- **Conversation follows the user** -- do not force a fixed language.
- **Artifacts follow the store, not the conversation.** Read `req_list`/
  `uc_list`/`term_list` before writing: whatever language the existing entries
  use is the language of the ones you add. `title`, `description`, `label`,
  use-case text all follow it, even if the conversation ran in another
  language. A register split across two languages is a defect in itself -- do
  not be the one who starts the split.
- **Empty store** -- use the language the domain speaks, which is the user's,
  not necessarily the interview's. Settle it once at the start and say which
  you picked, rather than deciding it again per entry.
- **Never translate a ubiquitous-language term.** A glossary `label` is the
  word the business actually uses. If they say "Vorgangsakte", that is the
  label, even when the interview runs in English -- translating it invents a
  second vocabulary, which is precisely what a glossary exists to prevent.

## Two entry points, one protocol

- **Greenfield** -- an idea/wish comes from the user, the interview interrogates
  it until a testable "done when" is reached.
- **Brownfield** -- an existing project is attached to arknet. Code delivers
  **questions, never answers**.

### Brownfield: order (signal strength, not artifact hierarchy)

Analysis priority, not a phase gate -- items can surface together, but when
signals conflict, trust this order:

1. **Entry points, inner documentation, and formal domain schemas
   first.** Walk the actual entry points (controllers, MCP tools, CLI
   commands, message handlers -- whatever the language/framework's
   dispatch mechanism is; recognising them is general programming
   knowledge, not something this skill needs to spell out per
   framework); documentation that states intent explicitly
   (module-level docs, package-level docs, ADRs, README); and any
   formal, machine-readable domain schema the project carries
   (ontologies, e.g. `*.ttl`; JSON Schema; OpenAPI/Protobuf
   definitions; a domain model with Javadoc) -- three co-equal
   sources, read routinely together, not a schema consulted only once
   a stress-test forces the question. A formal schema outranks prose
   about it, because it *is* the specification, not just a text
   describing one; entry points and documentation in turn outrank a
   bare name, because someone wrote a sentence about *why*, not just
   picked a word.
2. **Filter noise before treating a hit as a use-case candidate.** Not
   every entry point is a business use case -- health checks,
   metrics/actuator endpoints, generated CRUD boilerplate, admin/ops
   utility routes are technical, not actor-triggered domain flows. This
   filter is framework-independent; do not skip it.
3. **Use case and actor surface together.** Who calls an entry point is
   usually visible right there (caller, auth context, trigger) --
   recognise both in the same pass. The *write* order stays unchanged
   though: `term_add` with `actorKind` before `uc_add`, because the tool
   resolves `primaryActor`/`supportingActors` by label (see "Ordering
   consequence" below).
4. **Vocabulary beyond actors surfaces in context**, as terms appear in a
   use case's goal/steps -- not mined wholesale from class/package names
   in advance. Check every candidate against the load-bearing bar (used
   in more than one place) before writing it in; a term that only echoes
   a single class name is not yet earned.
5. **FRs/NFRs/Constraints last and thin.** Weakest signal; a requirement
   or constraint derived from code is always just a conversation starter,
   never a finished answer. Externally-imposed, non-negotiable code
   behaviour (a specific law/norm/contract clause baked into the
   implementation) is a `Constraint` candidate, not an NFR -- see "Deciding
   FR vs. NFR vs. Constraint" below.

### Brownfield: code delivers questions, never answers (core rule)

**Never** "the code does X, therefore FR: X" (reverse-engineering requirements
out of technical decisions). The same guardrail already applies to ADRs ->
requirements (a technical decision taken does not by itself justify a
requirement); for brownfield code the rationalisation risk is even higher,
because code is more concrete and suggestive than an ADR.

Instead: translate observed behaviour into a question. Pattern:

> "I see X in the code -- was that intentional, grown, or accidental?"

Give your own assessment along with it (see interrogation protocol below), but
the decision -- intentional / grown / accidental -- stays with the user.

## Context discipline -- read, don't guess

- **Existing requirements/use cases/terms are the given baseline, not a
  cage.** Read `req_list`, `uc_list`, `term_list` before every interview and
  treat them as current truth -- *but the user may change, re-scope or drop
  any of it at any time.* When new intent contradicts an existing
  requirement, surface the conflict and let the user decide; do not silently
  keep the old one.
- **NEVER GUESS -> ALWAYS LOOK IT UP.** If a fact is knowable from the repo,
  the store, research, or the project's own already-documented ubiquitous
  language (e.g. a "Ubiquitous Language" section in its `CLAUDE.md`), resolve
  it yourself instead of asking. Only **scope, priority and shape** decisions belong to the
  user -- put each of those to them, one at a time.

## The artifacts and their tools

| Artifact | Create | Read | Change |
|---|---|---|---|
| Requirement (FR/NFR) | `req_add` | `req_get`, `req_list` | `req_set_status`, `req_link_term`, `req_update` |
| Constraint (TECHNICAL/BUSINESS/REGULATORY) | `constraint_add` | `constraint_get`, `constraint_list` | (no update tool -- immutable, create anew) |
| Use case | `uc_add` | `uc_get`, `uc_list` | `uc_update` (title/goal/scope/trigger/pre-post-condition, extensions wholesale, step *text* by position -- not `realises`/actors/step structure) |
| Glossary term | `term_add` | `term_get`, `term_list` | `term_update` |

### Glossary terms: `term_add(label, definition, language?, actorKind?, actorRole?)`

- `label` (required) -- `skos:prefLabel`.
- `definition` (required).
- `language` (optional) -- BCP-47 tag (e.g. `de`) the label/definition are
  written in; omitted writes a plain, untagged literal. Never defaulted from
  the project's configured default language -- that default only affects
  display (`term_get`), never what gets written.
- `actorKind` (optional) -- `HUMAN` | `SYSTEM` | `LEGAL`. Sets the actor facet
  (the same concept additionally becomes
  `arkproc:HumanActor`/`SystemActor`/`LegalActor` -- `LEGAL` for a legal
  person, e.g. an organization, company or association, as opposed to a
  natural person acting on its behalf) -- needed if the term is later going
  to appear as `primaryActor`/`supportingActors` in a use case.
- `actorRole` (optional) -- free text, only meaningful together with
  `actorKind`.
- Result: `TERM-n` code.

**Ordering consequence:** generalises beyond actors. Any reference a draft
makes to another resource -- an actor/term by label, a requirement by code,
or another use case by its capability (e.g. a step reading "checks against
the register -- uses UC 'look up'") -- must exist **before** the draft that
depends on it is presented. Actor terms before `uc_add` is the case the tool
itself enforces (see below); a use-case step presupposing a *different* use
case's capability is not resolved or validated by any tool argument, so that
existence check is on you -- verify via `uc_list`/`uc_get` before presenting
the draft, not after.

- `term_update(id, label?, definition?, language?, actorKind?, actorRole?)` --
  corrects an already-created term's label/definition/actor facette in place,
  keeping its identity and every existing link into it (e.g.
  `arkreq:usesTerm`) unchanged. Every argument but `id` is optional and an
  omitted one leaves that field unchanged -- use this to fix a term found
  wanting during a full-set audit instead of creating a duplicate.
  `language` behaves as in `term_add`: it replaces only the literal carrying
  that same tag, every other language variant survives untouched.
- `term_get(id, displayLocale?)` -- `displayLocale` (optional) overrides the
  project's configured default language for this one read, choosing which
  language variant of label/definition comes back. Falls back to the
  project default, then to the server's own default, then to an untagged
  literal, then deterministically to any literal the term carries.

### Requirements: `req_add(title, description, type, acceptanceCriteria, priority?, motivatedBy?, qualityCategory?)`

- `title` (required) -- short summary.
- `description` (required) -- the normative statement ("The system shall
  ..."). Must be testable on its own (see checklist below).
- `type` (required) -- `FUNCTIONAL` | `NON_FUNCTIONAL`.
- `acceptanceCriteria` (required, at least one) -- testable "done when ..."
  criteria as a list of strings. This is `arkreq:acceptanceCriterion` as a
  first-class, SHACL-enforced field (`sh:minCount 1` / `sh:Violation`) --
  do not fold it into `description` as a suffix sentence, it has its own
  argument.
- `priority` (optional, MoSCoW) -- `MUST_HAVE` | `SHOULD_HAVE` |
  `COULD_HAVE` | `WONT_HAVE`.
- `motivatedBy` (optional) -- IRI of an `arkreq:Goal`.
- `qualityCategory` (optional, **only** for `NON_FUNCTIONAL`) -- free text,
  e.g. "performance", "security".
- Result: `FR-n`/`NFR-n` code.
- `req_set_status(id, status)` -- `status`: only `PROPOSED` | `ACCEPTED`
  (the lifecycle enum is deliberately MVP-minimal; `Rejected`/`Deprecated`
  exist as allowed values in the SHACL shape but not (yet) in the domain
  enum/tool -- see "Interview interim state" below, which needs no reject
  status for exactly this reason).
- `req_link_term(reqId, termId)` -- links a requirement to a glossary term
  (`arkreq:usesTerm`). After every new domain term in the requirement text,
  check: does a term already exist for it? If not, `term_add` first, then
  `req_link_term`.
- `req_update(id, ...)` -- patches fields of an existing requirement
  (partial update, not replace-by-identity) -- use this to fix a requirement
  found wanting during a full-set audit instead of leaving it inconsistent.

### Deciding FR vs. NFR vs. Constraint

Every candidate requirement needs a type decision before `req_add`/
`constraint_add`. The decision test: **is the underlying claim itself
negotiable?**

- **FR** -- a functional behaviour the system must exhibit.
- **NFR** -- a gradual quality property ("how well" -- performance, security,
  ...), verhandelbar/priorisierbar via `priority`.
- **Constraint** -- a non-negotiable, externally imposed requirement (law,
  norm, contract) -- `TECHNICAL` | `BUSINESS` | `REGULATORY`.

**Pitfall:** a binary-formulated acceptance criterion is *not* a reliable
signal for Constraint -- self-set NFRs are frequently phrased binary too, for
testability's sake. What decides is whether the underlying claim itself is
negotiable, not the shape of its done-when. Ask directly: "if we
dropped/relaxed this, would that be a business tradeoff (NFR), or a rule
violation (Constraint)?"

### Constraints: `constraint_add(title, statement, type)`

- `title` (required) -- short summary.
- `statement` (required) -- the normative constraint text.
- `type` (required) -- `TECHNICAL` | `BUSINESS` | `REGULATORY`.
- Result: `TCON-n`/`BCON-n`/`RCON-n` code (one counter per subtype --
  deliberately not `TC-n`/`BC-n`/`RC-n`, which would collide with the
  existing Bounded Context abbreviation used throughout this ecosystem).
- **Immutable once created** -- no update or status-change tool exists
  (matches the ontology: a Constraint carries no status field). Get it right
  at intake; a wrong one needs a fresh `constraint_add`, not a patch.
- `req_link_constraint(reqId, constraintId)` -- links a requirement to the
  constraint that binds it (`oslc_rm:constrainedBy`), analogous to
  `req_link_term`. Idempotent no-op if already linked.

### Use cases: `uc_add(title, goal, primaryActor, steps, scope?, trigger?, supportingActors?, precondition?, postcondition?, extensions?)`

Coarse-grained write: **one** `uc_add` call creates the complete use case.

- `title`, `goal` (required) -- goal-in-context.
- `primaryActor` (required) -- **label** of an existing actor term (see
  above: must already exist via `term_add ... actorKind=...`; an unknown
  label is rejected didactically, never silently created).
- `steps` (required, at least 1) -- list of `{position, text, realises?}`:
  `position` 1-based and gapless, `text` the step description, `realises`
  optionally a list of requirement codes (`FR-n`/`NFR-n`) that this step
  fulfils.
- `scope`, `trigger`, `supportingActors` (list of actor labels),
  `precondition`, `postcondition`, `extensions` (list of free-text
  alternative/exception-flow lines) -- all optional.
- Result: `UCn` code.

- `uc_update(id, title?, goal?, scope?, trigger?, precondition?,
  postcondition?, extensions?, stepTextPatches?, language?)` -- corrects an
  already-created use case's title/goal/scope/trigger/pre-/postcondition in
  place; `extensions` replaces the alternative/exception flows wholesale
  (omitted leaves them unchanged); `stepTextPatches` (list of
  `{position, text}`) corrects the *text* of individual existing main-flow
  steps by their position. Every argument but `id` is optional and an
  omitted one leaves that field unchanged -- use this to fix a use case
  found wanting during a full-set audit instead of creating a duplicate.
  It does **not** touch a step's `realises` links, `primaryActor`,
  `supportingActors`, or the step list's structure (add/remove/reorder) --
  those still require a fresh `uc_add`.

arknet already resolves `primaryActor`/`supportingActors` and
`steps[].realises` **schema-independently and with didactic rejection of
unknown/ambiguous references** -- that rigor is already wired **into the
tool itself**. The skill therefore does not need to invent this discipline,
only observe the write order (terms before use cases, requirements before
`realises` references).

## The interrogation -- protocol

This is the core of the skill. **Interrogate relentlessly until you and the
user share a complete, testable understanding. Only then write it in.** Two
entry points (see above), same protocol:

- **Intake** -- a new requirement/use case/term arrives. Interrogate *it*,
  then integrate.
- **Full-set audit** -- the user asks for a review of the whole register
  ("review the requirements", "review the glossary relentlessly", "are they
  complete/consistent"). This is the **default reading** of any
  "review/check" phrasing -- do not collapse it into a quick summary.
  **First, automated pass:** run `orphan_check` (requirements no use case
  realises, glossary terms never referenced, constraints no requirement is
  bound by) and `trace_matrix` (per
  requirement: which terms it uses, which use case(s) realise it) *before*
  any manual reading -- these two calls surface structural gaps
  (dangling links, orphaned terms, unrealised requirements) that a
  content read of the requirement text will not, no matter how careful.
  Treat every finding they report as a mandatory interrogation point, not
  an optional footnote. **Then** walk every requirement/use case/term
  systematically, one at a time, and interrogate the user relentlessly on
  the gaps you find (missing scenarios/actors/edge cases, conflicts,
  untestable descriptions, unspecified failure behaviour). A full-set audit
  that only reads content against source documents and never calls
  `orphan_check`/`trace_matrix` has not audited the graph structure, only
  the prose -- both are required.

**Hold the whole set in view -- always.** "One at a time" governs *question
sequencing*, never *analytical scope*. A requirement judged in isolation is
worthless: its most important defects -- **consistency** (conflict with
another), **completeness** (a gap relative to the whole system),
**dependencies** (what it presupposes/affects), **duplication** -- only
surface against the *entire* set. So even in intake mode, read
`req_list`/`uc_list`/`term_list` first and check the new item against the
set; never treat a single requirement as a closed world.

Protocol (the user's standing "relentless" instruction, treat as binding):

- Work through **one requirement/use case/term at a time**, and ask questions
  **one at a time**, waiting for the answer before the next. Several
  questions at once is confusing. (This is pacing -- not a licence to lose
  track of the rest of the set.)
- With **every** question, give **your own assessment or recommended
  answer**, so the user can decide from an informed position rather than
  from a blank prompt.
- Resolve by research/context/existing docs whatever *can* be resolved that
  way. Reserve questions for genuine **scope/priority/shape** decisions --
  those are the user's.
- **Do not** produce a final summary or a settled version until the user
  confirms that all open points are resolved. **Settled** means concretely:
  the literal draft text (the definition/requirement text/use-case text, not
  a paraphrase of it) was shown to the user and confirmed by them -- having
  discussed the topic is not enough.

### Checklist per requirement

First block: the SOPHIST/Rupp **linguistic defect** filter (the concrete
engine, not a vague "is it ambiguous?"):

- **Passive voice / missing actor** -- "is validated", "gets classified" ->
  *by whom/what?* Name the active subject (the system? a specific step? an
  external service?).
- **Nominalisation** -- a noun that hides a whole process ("the
  classification", "the merge") -> unfold it into steps, inputs, outcome.
- **Incomplete comparative** -- "faster", "better", "higher quality" -> *than
  what, measured how?* Turn it into something a "done when" can check, or
  drop it.
- **Universal quantifier** -- "all", "every", "never", "always" -> is it
  really exceptionless? Hunt the counter-case.
- **Incompletely specified process word/condition** -- "on error, abort",
  "if needed" -> *which errors, then exactly what? which condition, decided
  by whom?*

Then the requirement-quality attributes (ISO/IEC/IEEE 29148):

- **Completeness** -- missing scenarios, edge cases, actors, or
  empty/failure/timeout paths?
- **Unambiguity** -- can this be read in more than one way?
- **Consistency** -- conflict with another requirement/use case/term?
- **Testability** -- does `acceptanceCriteria` hold at least one objective
  "done when ..." criterion, not a restatement of `description`? If you
  cannot write one, elicitation is not finished.
- **Dependencies** -- what does it presuppose/affect (which other
  FRs/UCs/terms)?
- **Non-functional aspects** -- performance, security, scalability,
  **failure behaviour** considered (check a new FR against existing NFRs)?
- **Priority differentiation** -- does this genuinely differ from the rest
  of the set, or is it a placeholder? For `MUST_HAVE` specifically: what
  breaks if this is cut? A register where everything is `MUST_HAVE` has not
  been interrogated on priority.
- **Type classification** -- correctly FR vs. NFR vs. Constraint (see
  "Deciding FR vs. NFR vs. Constraint" above)? A non-negotiable, externally
  imposed rule filed as NFR under-signals that it cannot be traded off.

### Checklist per use case

Cockburn completeness:

- **Trigger** clear? **Actor** (primary + supporting) correct and existing
  as a term?
- **Goal-in-context** in one sentence, no technical how.
- **Main flow** (`steps`) gaplessly numbered, each step a testable system
  state transition?
- **Alternative/exception flows** (`extensions`) -- empty run, partial
  failure, timeout, user abort considered?
- **`realises` link** -- does at least one step fulfil an existing FR/NFR?
  If the link is entirely missing, ask whether a requirement is missing or
  the use case stands on its own.
- **Title differentiation** -- does the use case's title read as a
  distinguishable actor goal/process, or was the realised requirement's
  title just carried over? A requirement title names a narrow system
  capability; a use-case title names the broader actor goal it serves. An
  identical title against a linked FR/NFR/Constraint is a signal the
  goal-in-context was never actually restated -- go back and ask what the
  actor is really trying to accomplish.

### Checklist per glossary term

- Unambiguous against existing terms (read `term_list` first) -- no hidden
  synonym or homonym?
- **Unambiguous against established external meaning** -- does the
  candidate label collide with a widely-established industry/domain
  meaning outside this project, even when `term_list` has no local hit? A
  label can be locally novel and still contradict what practitioners
  already read into it -- e.g. "AI Agent" carries an industry-standard
  "acts autonomously, no human approval needed" connotation that a
  human-in-the-loop domain concept would silently contradict. A local
  `term_list` check alone cannot catch this; it takes deliberately asking
  "what does this label already mean out there?"
- Definition precise enough that two people understand the same thing?
- Does the term need an actor facet (`actorKind`/`actorRole`) because it will
  later appear as an actor in a use case?
- **Before discarding a category/classification candidate as "not
  load-bearing"** -- check the actual ontology/schema (grep the vocabulary
  source, not just judge from prose mentions) for whether it is already a
  modelled class that other terms parametrize against. A candidate that
  looks like idle prose ("just a category") may already be an implemented
  supertype (e.g. an `Actor` class with `HumanActor`/`SystemActor`/
  `LegalActor` subclasses) that every actor term's classification field
  maps onto -- discarding it would leave that mapping without a defined
  domain concept.
- **Duplication against related terms** -- does this term restate content
  (a list of resource types, a set of responsibilities) that already lives
  in another existing, or concurrently-drafted, related term definition?
  Cross-reference instead of re-enumerating -- two lists of the same facts
  are two places that must be kept in sync by hand.
- **Implementation-free** -- does the definition avoid naming the
  system/software/storage technology (the same WHAT-not-HOW discipline
  requirements are held to)?
- **Architecture-decision-free** -- does the definition stick to domain
  *meaning* only, without smuggling in an architecture/design decision --
  source-of-record, persistence choice, tenancy/multi-user model, who
  triggers or owns an action? Those decisions belong in an ADR (`adr_add`),
  not in what a term *means*. Give-away pattern: a definition sentence
  reads like a system-behaviour statement ("X is the authoritative source
  for Y", "the system holds no own record of Z", "X is triggered by Y, not
  by the system") instead of "X is a ...". Catch this even when no
  concrete technology is named -- that's what makes it distinct from
  Implementation-free above. Negative example: a definition that reads
  "... within a project ..." smuggles in an unconfirmed container/scoping
  term -- "project" here is not yet an established domain concept but a
  stand-in for a tenancy/multi-user boundary that was actually decided in
  an ADR. The leak is in the unconfirmed container word itself, not in a
  named technology.
- **Config-free** -- does the definition avoid baking in a concrete,
  dated value (amount, percentage, date) that a requirement elsewhere
  declares configurable/changeable? If the value can change through the
  system the requirement describes, the definition must not freeze it.

## Writing it in only happens after that

Once a requirement/use case/term is settled with the user -- literal draft
text shown and confirmed, per the definition above, not merely discussed:

- Order by dependency, not by elicitation order: terms (including actors)
  first, then requirements, then use cases (which reference both).
- Domain terms in a requirement's text that have no term yet: `term_add`
  first, then `req_link_term`.
- After writing, report crisply **what changed and which code**
  (`FR-3`, `UC2`, `TERM-5`) -- not a full restatement of the content.

### Ripple check after every written change

A settled decision rarely stays local. **After every written change, before
moving to the next item, check whether it ripples** into the rest of the
set. Does the new wording now conflict with, duplicate, or leave a gap in
another FR/NFR/UC/term?

**Use `impact_analysis(resource)`** on the just-written/just-changed
requirement/use-case/term as the first, automated step -- it walks
references backwards and returns everything that transitively depends on
it. Follow up with `orphan_check`/`trace_matrix` if the change touched
links (`usesTerm`, `realises`, actor references). Only fall back to
re-reading `req_list`/`uc_list`/`term_list` from memory for aspects these
tools do not cover (e.g. wording conflicts between two requirements that
share no explicit link) -- do not use manual re-reading as the primary
method now that the tools exist.

- **No ripple** -> state it in one line, continue the walk.
- **Ripple found** -> name the affected codes and the nature of the impact,
  fold the fix into the current pass (or queue it explicitly) -- never
  silently leave the set inconsistent.
- **Ripple could invalidate already-audited items** -> that is a
  **scope/priority decision for the user**, not the skill: surface it as a
  decision -- e.g. "FR4 adjusted; this touches FR7 and UC1 which we already
  cleared -- restart the review from the top, or patch just those two and
  carry on?" -- and follow the user's choice. Never restart (or decline to
  restart) unilaterally.

## Interview interim state: "origin unclear"

A brownfield interview can surface "nobody remembers why this is the way it
is". This is **not** modelled as its own requirement status -- a requirement
without a testable done-when would fail every full-set audit, which would be
a permanent special case in the register (and `RequirementStatus` only knows
`PROPOSED`/`ACCEPTED` anyway, see above). Instead it stays an interview
**interim state** (conversation/todo, not in the store) until it reaches one
of two outcomes:

- **Actually wanted** -> create a real requirement with a real done-when
  (same path as greenfield, the code was only the conversation starter).
- **Not wanted/dead** -> do not create a requirement. No delete tool
  needed -- it never existed in the store.

## Scope boundary

- **HOW does not belong here.** Architecture, technology, pipeline wiring ->
  `/arknet:adr`. If the user drifts into HOW: name it and offer the handoff
  to the ADR skill, keep this conversation on WHAT & WHY.
- Use cases belong here (Cockburn flows, linked to requirements via
  `realises`). User stories do not -- arknet has no separate role layer that
  would justify an "as X I want" framing; it has actors (terms with
  `actorKind`) and flows.
