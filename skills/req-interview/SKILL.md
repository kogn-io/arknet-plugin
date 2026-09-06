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
  language. A store split across two languages is a defect in itself -- do
  not be the one who starts the split. Read those lists under the language
  you are keeping (`displayLocale`) and read their `[fallback: ...]` tags: a
  tagged line is an entry **missing** in that language, not one written in
  it. Untagged is the only proof of a real entry -- without the tag a gap and
  a translation look the same.
- **Empty store** -- use the language the domain speaks, which is the user's,
  not necessarily the interview's. Settle it once at the start and say which
  you picked, rather than deciding it again per entry.
- **Never translate a ubiquitous-language term.** A glossary `label` is the
  word the business actually uses. If they say "Vorgangsakte", that is the
  label, even when the interview runs in English -- translating it invents a
  second vocabulary, which is precisely what a glossary exists to prevent.
- **A second language never restates a term's `label`.** In a store that
  deliberately carries two languages, a term's label goes in under every
  language tag as the same word, and only its `definition` is written a
  second time. A translated label is the second vocabulary the rule above
  forbids -- a reader seeing `Anker`/`Anchor` cannot tell whether that is one
  term or two, and mention detection resolves a term through one label at a
  time, so prose naming it in the other language stays unlinked. This is the
  one exception to the restate rule below, which governs prose fields
  (`title`, `description`, use-case text) only.
- **One write call carries one language tag**, across every write tool
  (`req_`, `constraint_`, `term_`, `uc_`). A second language therefore takes
  a second call: create it in the first language, then restate it under the
  second via the matching `*_update` -- a term's `label` excepted, see the
  rule above. That is a decision for the whole store, not for a single entry
  (see the split rule above), so settle it with the user before writing the
  second variant. Two silent failure modes live there, both from omitting
  `language`, which falls the call back to the project's
  default tag: identical text under that tag returns without error and
  writes nothing, and *differing* text replaces the default-language literal
  instead of adding a second variant -- the first language is then gone,
  without an error. Name the `language` whenever the point of the call *is*
  the language.

## Two entry points, one protocol

- **Greenfield** -- an idea/wish comes from the user, the interview interrogates
  it until a testable "done when" is reached.
- **Brownfield** -- an existing project is attached to arknet. Code delivers
  **questions, never answers**.

**Elicitation order is not write order** -- two different orders, and mixing
them up is the standard failure of this skill. *Elicited* along flows: use
cases first, vocabulary (and the actors who drive it) emerges out of them.
*Written* along dependencies: actors and terms, then requirements, then use
cases (see "Writing it in" below).
**Actors** are no exception to the elicitation order -- they surface
with the use case they serve, like any glossary term -- only to the write
order: they have to exist (`actor_add`) before `uc_add`, because the tool
resolves `primaryActor`/`supportingActors` against the actor register. An
actor is its own resource, not a glossary term (see "Actors" below) --
naming it does not, by itself, put a word into the glossary. Every other
term surfaces in a concrete use case's goal or steps and is written from
there. A glossary round pulled forward -- terms proposed in advance, off
class or package names -- is not a shortcut but the reverse-engineering
"code delivers questions, never answers" forbids below.

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
   though: `actor_add` before `uc_add`, because the tool resolves
   `primaryActor`/`supportingActors` by name against the actor register
   (see "Ordering consequence" below).
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
| Requirement (FR/NFR) | `req_add` | `req_get`, `req_list` (both `displayLocale?`) | `req_set_status`, `req_link_term`, `req_update` |
| Constraint (TECHNICAL/BUSINESS/REGULATORY) | `constraint_add` | `constraint_get`, `constraint_list` (both `displayLocale?`) | `constraint_update` (title/statement -- not the type or the code that follows from it), `constraint_delete` (whole resource; refused while a requirement or use case still references it via `constrainedBy`) |
| Use case | `uc_add` | `uc_get`, `uc_list` (both `displayLocale?`) | `uc_update` (title/goal/scope/trigger/pre-post-condition, extensions wholesale, step *text* by position, step `realises` by position (wholesale replace, empty clears), `primaryActor` (replaces, cannot be cleared), `supportingActors` (wholesale replace, empty clears) -- not step structure), `uc_link_term`, `uc_link_constraint` |
| Glossary term | `term_add` | `term_get`, `term_list` (both `displayLocale?`) | `term_update`, `term_delete` (whole resource; refused while a requirement, use case, ADR, bounded context or another term's `broader`/`related` still references it) |
| Actor | `actor_add` | `actor_get`, `actor_list` | `actor_update` (name/description -- not the type or the code that follows from it), `actor_delete` (whole resource; refused while a use case still names it) |

### Actors: `actor_add(type, name, description?)`

An actor is a resource in its own right, not a glossary term or a facet of
one -- someone or something that can act on the system under description,
hold an interest in it, or both. It needs no definition and no `TERM-n`
code to exist; a resource may still be *both* an actor and a glossary term
(e.g. "Customer" worth an actor *and* a defined domain concept), but nothing
forces the pairing.

- `type` (required) -- `HUMAN` (a natural person) | `SYSTEM` (an external
  system or service) | `LEGAL` (a legal person -- organization, company,
  association) | `GROUP` (a group without a legal form of its own --
  department, committee, team). Fixed at creation; `actor_update` cannot
  change it.
- `name` (required) -- what the actor is called, e.g. "Sachbearbeiter" or
  "PaymentService". Plain text, no language tag (unlike a glossary term's
  `skos:prefLabel`) -- an actor is a structural identity, not prose whose
  wording is the deliverable.
- `description` (optional) -- free text.
- Result: `ACTOR-n` code.
- `actor_update(id, name?, description?)` -- corrects an already-created
  actor's name/description in place, keeping its identity (and every
  existing link into it) unchanged. Cannot change `type` or the code.
- `actor_delete(id)` -- removes the whole actor resource, not just a
  correction. Rejected while a use case still names it as `primaryActor` or
  `supportingActor` -- re-point that use case first (`uc_update`). An actor
  that is also a glossary term keeps its glossary entry; only the actor
  resource goes away.

### Glossary terms: `term_add(label, definition, broader?, related?, language?)`

- `label` (required) -- `skos:prefLabel`. The same word under every language
  tag the store carries; only `definition` is restated in a second language
  (see "Language" above).
- `definition` (required).
- `broader` (optional) -- code of an already-existing term this one
  specializes, its superordinate term (`skos:broader`), e.g. "Human Actor"
  as the broader term of "Customer". Rejected if the code does not resolve
  to an existing term.
- `related` (optional) -- codes of already-existing terms this one is
  associatively connected to (`skos:related`): a domain neighbourhood
  without hierarchy, e.g. "Anchor" and "Project" -- neither is a kind of the
  other, yet one is not understood without the other. The relation is
  symmetric: it shows on both terms, naming it on either one is enough.
  Rejected if a code does not resolve, or names the term itself.
- Which edge: `broader` when one term *is a kind of* the other -- its
  definition reads "a <other term> that ..."; `related` when the two belong
  together without either specializing the other.
- `language` (optional) -- BCP-47 tag (e.g. `de`) the label/definition are
  written in. Omitted, it falls back to the project's configured default
  language (`project_update`); if the project has no default either, the
  call is rejected rather than writing an untagged literal.
- Result: `TERM-n` code.

**Ordering consequence:** generalises beyond actors. Any reference a draft
makes to another resource -- an actor/term by name, a requirement by code,
or another use case by its capability (e.g. a step reading "checks against
the tenant register -- uses UC 'look up'") -- must exist **before** the draft that
depends on it is presented. Actors before `uc_add` is the case the tool
itself enforces (see below); a use-case step presupposing a *different* use
case's capability is not resolved or validated by any tool argument, so that
existence check is on you -- verify via `uc_list`/`uc_get` before presenting
the draft, not after.

- `term_update(id, label?, definition?, broader?, related?, language?)` --
  corrects an already-created term's label/definition/broader/related in
  place, keeping its identity and every existing link into it (e.g.
  `arkreq:usesTerm`) unchanged. Every argument but `id` is optional and an
  omitted one leaves that field unchanged -- use this to fix a term found
  wanting during a full-set audit instead of creating a duplicate. `broader`
  and `related` carry a third state on top of that: omitted leaves the
  edge(s) unchanged, an empty string (`broader`) or an empty list
  (`related`) explicitly clears them, a value sets/replaces them wholesale.
  Rejected if a code does not resolve, if `broader` would make the term its
  own (direct or transitive) broader term, or if `related` names the term
  itself. `related` is symmetric but written in one direction: a
  `term_update` rewrites only the edges this term asserts itself -- an edge
  another term asserts towards this one is cleared with a `term_update` on
  *that* term. `language` behaves as in `term_add`
  (falls back to the project's default, rejects if neither is set): it
  replaces only the literal carrying the resolved tag, every other language
  variant survives untouched -- except a stale untagged one, swept away once
  the resolved tag equals the project's default.
- `term_delete(id)` -- removes the whole term resource, label and
  definition in every language, not just a correction -- for a term created
  by mistake (a duplicate, an actor that should have been `actor_add`).
  Rejected while anything still references it: a requirement's or use
  case's `arkreq:usesTerm`, an architecture decision's `arkarch:usesTerm`,
  a bounded context's `ubiquitousLanguageTerm`, or another term's `broader`
  or `related`. Remove those edges first (`req_update`/`uc_update`,
  `adr_update`, `bc_link_term`, or `term_update` on the *other* term to
  clear its `broader`/`related`). A term found wanting is corrected with
  `term_update`, not deleted and re-created -- re-creating loses the code
  and every link into it.
- `term_get(id, displayLocale?)` -- `displayLocale` (optional) overrides the
  project's configured default language for this one read, choosing which
  language variant of label/definition comes back. Falls back to the
  project default, then to the server's own default, then to an untagged
  literal, then deterministically to any literal the term carries.
- `term_list(displayLocale?)` -- takes the same parameter and falls back the
  same way, and marks what it fell back to: a term whose label/definition is
  missing in the requested (or project-default) language is shown under
  another one with an inline `[fallback: ...]` tag naming the language
  actually shown. Read that tag as **the entry is missing in the language you
  asked for**, not as "a translation exists elsewhere" -- an untagged line is
  the only evidence the entry really is in that language. Without the tag the
  two cases are indistinguishable in the output.

### Requirements: `req_add(title, description, type, acceptanceCriteria, language?, priority?, qualityCategory?)`

- `title` (required) -- short summary.
- `description` (required) -- the normative statement ("The system shall
  ..."). Must be testable on its own (see checklist below).
- `type` (required) -- `FUNCTIONAL` | `NON_FUNCTIONAL`.
- `acceptanceCriteria` (required, at least one) -- testable "done when ..."
  criteria as a list of strings. This is `arkreq:acceptanceCriterion` as a
  first-class, SHACL-enforced field (`sh:minCount 1` / `sh:Violation`) --
  do not fold it into `description` as a suffix sentence, it has its own
  argument.
- `language` (optional) -- BCP-47 tag the title/description are written in,
  behaving as in `term_add`: falls back to the project's configured default
  language, and if the project has no default either, the call is rejected
  rather than writing an untagged literal.
- `priority` (optional, MoSCoW) -- `MUST_HAVE` | `SHOULD_HAVE` |
  `COULD_HAVE` | `WONT_HAVE`.
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
- `req_update(id, title?, description?, priority?, newAcceptanceCriteria?,
  acceptanceCriteriaTextPatches?, language?)`
  -- patches fields of an existing requirement (partial update, not
  replace-by-identity) -- use this to fix a requirement found wanting during
  a full-set audit instead of leaving it inconsistent. Acceptance criteria
  are reached through two independent, narrow parameters:
  `newAcceptanceCriteria` appends criteria after the existing ones, and
  `acceptanceCriteriaTextPatches` (list of `{position, text}`) corrects the
  wording of existing ones by their 1-based position -- neither can insert
  mid-list, delete or reorder a criterion, and a position with no matching
  criterion is rejected. `language` is the tag a non-omitted
  `title`/`description` and any acceptance criterion this call touches are
  written in, and behaves as in `term_update`: it replaces only the literal
  carrying the resolved tag, every other language variant survives
  untouched -- except a stale untagged one, swept away once the resolved tag
  equals the project's default. It is also the only way to state an existing
  requirement in a second language, the same two-call pattern as for terms and
  constraints. It does **not** touch status (`req_set_status`) or
  linked terms (`req_link_term`).
- `req_get(id, displayLocale?)` -- `displayLocale` behaves as in `term_get`.
  `req_list(displayLocale?)` takes it too and flags a fallen-back entry with
  the same inline `[fallback: ...]` tag as `term_list`.

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

**Mandatory step before every `constraint_add`:** run the classification
test -- "Could this project decide otherwise?" If yes, it is a decision
(`adr_add`) or a requirement (`req_add`), never a constraint; only a "no"
clears the way to `constraint_add`. A constraint whose statement does not
name who or what imposes it (law, contract, customer, platform, budget,
organisation) has failed this test and is not ready to write in -- push back
and ask for the source before calling `constraint_add`.

### Constraints: `constraint_add(title, statement, type, language?)`

- `title` (required) -- short summary.
- `statement` (required) -- the normative constraint text.
- `type` (required) -- `TECHNICAL` | `BUSINESS` | `REGULATORY`.
- `language` (optional) -- BCP-47 tag the title/statement are written in,
  behaving as in `term_add`: falls back to the project's configured default
  language, and if the project has no default either, the call is rejected
  rather than writing an untagged literal.
- Result: `TCON-n`/`BCON-n`/`RCON-n` code (one counter per subtype --
  deliberately not `TC-n`/`BC-n`/`RC-n`, which would collide with the
  existing Bounded Context abbreviation used throughout this ecosystem).
- `constraint_update(id, title?, statement?, language?)` -- corrects an
  already-created constraint's wording in place, keeping its identity and
  every `oslc_rm:constrainedBy` link into it. Every argument but `id` is
  optional and an omitted one leaves that field unchanged. `language`
  behaves as in `term_update`: it replaces only the literal carrying the
  resolved tag, every other language variant survives untouched -- except a
  stale untagged one, swept away once the resolved tag equals the project's
  default. It is also the only way to state an existing constraint in a
  second language: one call carries exactly one tag, so `constraint_add`
  then `constraint_update`, the same two-call pattern as for terms,
  requirements and use cases.
- **Type and code are fixed at intake** -- `constraint_update` changes text,
  never `TECHNICAL`/`BUSINESS`/`REGULATORY`, and never the
  `TCON-`/`BCON-`/`RCON-n` code that follows from the type. A retyped
  constraint would need a new code, which nothing already referencing it via
  `oslc_rm:constrainedBy` would follow. So the intake discipline still holds
  -- for the type, not for the wording, which is correctable afterwards.
- **No status** -- there is no `constraint_set_status`, matching the
  ontology: a Constraint carries no status field.
- `constraint_delete(id)` -- removes the whole resource, not a correction.
  The intended use is undoing a misclassification: a record that turns out
  to be something the project decided itself, and belongs in `adr_add` or
  `req_add` instead. Refused while a requirement or use case still points at
  it via `constrainedBy` (`req_link_constraint`/`uc_link_constraint`). The
  `TCON-`/`BCON-`/`RCON-n` code stays taken, so it never ends up naming a
  different constraint later.
- `constraint_get(id, displayLocale?)` -- `displayLocale` behaves as in
  `term_get`. `constraint_list(displayLocale?)` takes it too and flags a
  fallen-back entry with the same inline `[fallback: ...]` tag as
  `term_list`.
- `req_link_constraint(reqId, constraintId)` -- links a requirement to the
  constraint that binds it (`oslc_rm:constrainedBy`), analogous to
  `req_link_term`. Idempotent no-op if already linked.

### Use cases: `uc_add(title, goal, primaryActor, steps, language?, scope?, trigger?, supportingActors?, precondition?, postcondition?, extensions?)`

Coarse-grained write: **one** `uc_add` call creates the complete use case.

- `title`, `goal` (required) -- goal-in-context.
- `primaryActor` (required) -- **name** of an existing actor (see above:
  must already exist via `actor_add`; an unknown name is rejected
  didactically, never silently created).
- `steps` (required, at least 1) -- list of `{position, text, realises?}`:
  `position` 1-based and gapless, `text` the step description, `realises`
  optionally a list of requirement codes (`FR-n`/`NFR-n`) that this step
  fulfils.
- `scope`, `trigger`, `supportingActors` (list of actor names),
  `precondition`, `postcondition`, `extensions` (list of free-text
  alternative/exception-flow lines) -- all optional.
- `language` (optional) -- BCP-47 tag that title, goal, scope, trigger,
  pre-/postcondition and every step's and extension's text are written in,
  behaving as in `term_add`: falls back to the project's configured default
  language, and if the project has no default either, the call is rejected
  rather than writing an untagged literal.
- Result: `UCn` code.

- `uc_update(id, title?, goal?, scope?, trigger?, precondition?,
  postcondition?, extensions?, stepTextPatches?, stepRealisesPatches?,
  primaryActor?, supportingActors?, language?)` -- corrects an
  already-created use case's title/goal/scope/trigger/pre-/postcondition in
  place; `extensions` replaces the alternative/exception flows wholesale
  (omitted leaves them unchanged); `stepTextPatches` (list of
  `{position, text}`) corrects the *text* of individual existing main-flow
  steps by their position, and the independent `stepRealisesPatches` (list
  of `{position, realises}`) corrects a step's `realises` references by the
  same position -- a listed position's requirement codes replace that
  step's entire `realises` set wholesale, an empty list explicitly clears
  it, and a position omitted from either list stays untouched. `primaryActor`
  replaces the current primary actor (it cannot be cleared -- a use case
  always has exactly one); `supportingActors` replaces the current list
  wholesale, an empty array clearing it. Every argument but `id` is optional
  and an omitted one leaves that field unchanged -- use this to fix a use
  case found wanting during a full-set audit instead of creating a
  duplicate. `language` is the tag every field this call actually touches is
  written in and behaves as in `term_update`: it replaces only the literal
  carrying the resolved tag, every other language variant survives untouched
  -- except a stale untagged one, swept away once the resolved tag equals the
  project's default. It is also the only way to state an existing use case in
  a second language. It does **not** touch the step list's structure
  (add/remove/reorder) -- that still requires a fresh `uc_add`.
- `uc_get(id, displayLocale?)` -- `displayLocale` behaves as in `term_get`.
  `uc_list(displayLocale?)` takes it too and flags a fallen-back entry with
  the same inline `[fallback: ...]` tag as `term_list`.
- `uc_link_term(ucId, termId)` -- links a use case to a glossary term it
  uses (`arkreq:usesTerm`), analogous to `req_link_term`. After every new
  domain term in the use case's goal/scope/trigger/pre-postcondition/step
  text, check: does a term already exist for it? If not, `term_add` first,
  then `uc_link_term`. Idempotent no-op if already linked.
- `uc_link_constraint(ucId, constraintId)` -- links a use case to the
  constraint that binds it (`oslc_rm:constrainedBy`), analogous to
  `req_link_constraint`. Idempotent no-op if already linked.

arknet already resolves `primaryActor`/`supportingActors` and
`steps[].realises` **schema-independently and with didactic rejection of
unknown/ambiguous references** -- that rigor is already wired **into the
tool itself**. The skill therefore does not need to invent this discipline,
only observe the write order (actors and terms before use cases, requirements
before `realises` references).

## The interrogation -- protocol

This is the core of the skill. **Interrogate relentlessly until you and the
user share a complete, testable understanding. Only then write it in.** Two
entry points (see above), same protocol:

- **Intake** -- a new requirement/use case/term arrives. Interrogate *it*,
  then integrate.
- **Full-set audit** -- the user asks for a review of the whole store
  ("review the requirements", "review the glossary relentlessly", "are they
  complete/consistent"). This is the **default reading** of any
  "review/check" phrasing -- do not collapse it into a quick summary.
  **First, automated pass:** run `orphan_check` (requirements no use case
  realises, glossary terms never referenced, text mentions of a term missing
  its backing edge -- including a use case's prose beyond its `goal` -- and
  constraints no requirement or use case is bound by) and `trace_matrix` (per
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
  breaks if this is cut? A store where everything is `MUST_HAVE` has not
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
- **Is this candidate actually an actor** (something that can act on the
  system, hold an interest in it, or both)? If so it belongs as its own
  `actor_add` resource, not a glossary term -- create the actor separately,
  and only *also* write a glossary term for it if its meaning is itself
  worth defining (the two are independent; neither implies the other).
- **Before discarding a category/classification candidate as "not
  load-bearing"** -- check the actual ontology/schema (grep the vocabulary
  source, not just judge from prose mentions) for whether it is already a
  modelled class that other resources parametrize against. A candidate that
  looks like idle prose ("just a category") may already be an implemented
  supertype (e.g. the `Actor` class with `HumanActor`/`SystemActor`/
  `LegalActor`/`GroupActor` subclasses) that every actor's `type` field
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

- Order by dependency, not by elicitation order: actors and terms first,
  then requirements, then use cases (which reference both). The elicitation
  order runs the other way round -- see "Elicitation order is not write
  order" at the top.
- Domain terms in a requirement's or use case's text that have no term yet:
  `term_add` first, then `req_link_term`/`uc_link_term`.
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
a permanent special case in the store (and `RequirementStatus` only knows
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
  would justify an "as X I want" framing; it has actors (`actor_add`) and
  flows.
