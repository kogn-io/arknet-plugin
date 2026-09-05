---
description: "Write, review and maintain Architecture Decision Records as first-class resources in the arknet store (arkarch:ArchitectureDecisionRecord), via arknet's adr_add/adr_list/adr_get/adr_set_status/adr_supersede/adr_unsupersede/adr_update/adr_check/adr_delete MCP tools -- not Markdown files. Keeps every ADR a durable decision record: one decision per record, free of implementation detail, references only requirements/bounded contexts that already exist. Trigger (also DE, since the user may phrase it in German): /arknet:adr, 'write an ADR', 'new ADR', 'ADR for X', 'review this ADR', 'maintain the ADRs', 'is this a good ADR', 'supersede this ADR'; DE: 'schreib ein ADR', 'neues ADR', 'ADR fuer X', 'review das ADR', 'pflege die ADRs', 'loese dieses ADR ab'. NOT for a project that still keeps file-based Markdown ADRs under docs/adr/ (use /arknet:legacy-adr there instead). NOT for general documentation, NOT for requirements (use /arknet:req-interview), NOT for code comments."
---

# /arknet:adr -- Architecture Decision Records (arknet store)

You maintain the Architecture Decision Records of the project you are working in as resources
in its arknet store -- not as files. Every decision you write goes through arknet's `adr_*`
MCP tools, is SHACL-validated on the way in, and gets a store code (`ADR-1`, `ADR-2`, ...)
scoped to the project. Your job: keep every ADR a record of a **durable decision and its
lasting consequences**, never a status report or an implementation snapshot.

## Is this the right skill for this project?

If the project still keeps its ADRs as Markdown files under `docs/adr/` and has not moved to
the store, stop and use `/arknet:legacy-adr` there instead -- do not write into both models for
the same project, and do not silently decide to migrate an existing file-based corpus. If you
find both a populated `docs/adr/` *and* this skill was invoked, say so and ask the user which
model the project is actually on before writing anything.

## The nine tools

| Tool | Purpose |
|---|---|
| `adr_add` | Record a new decision. Always starts `PROPOSED`; takes no status parameter. |
| `adr_list` | One compact line per decision: code, status, title, addresses/affects/supersedes/superseded-by/related-to. |
| `adr_get` | A single decision's full text, plus both directions of `supersededBy` and every related decision. |
| `adr_set_status` | Transitions: `PROPOSED -> ACCEPTED`, `PROPOSED -> REJECTED`, `ACCEPTED -> DEPRECATED`. Refuses `SUPERSEDED` -- that one needs `adr_supersede`. Refuses `ACCEPTED` if the record carries considered options and not exactly one is `CHOSEN` -- `adr_update` corrects that first. Also stamps the decision date -- the only place it is ever set. |
| `adr_supersede` | Records that one decision replaces an older one -- sets the older decision's status to `SUPERSEDED` too (see "Lifecycle" below). |
| `adr_unsupersede` | Regret path for a mistyped `adr_supersede` call -- reverts a `SUPERSEDED` decision back to `ACCEPTED` and drops its `supersededBy` edge (see "Un-superseding a decision" below). |
| `adr_update` | Corrects an already-recorded decision -- see "Correcting a decision" below. |
| `adr_check` | Reads the whole corpus and reports what a machine can decide about it, in two separated blocks and without changing anything -- `Facts` (a `decisionDate` on a decision not yet taken, no consequence or no considered option recorded, an option space with nothing `CHOSEN` on a decision that was taken, a decision that addresses no requirement and affects no bounded context, an `ADR-n` named in the prose the project does not hold or that no `supersedes`/`supersededBy`/`relatedTo` edge backs) and `Suspicions` (tracker references, address/port literals, status prose, near-identical titles -- each a hint, not a defect). Also names, in its own output, what it does not check: whether a record bundles more than one decision, whether two records contradict each other, whether a consequence says anything. Read this first (see "Read everything first" below) -- its `Facts` replace the mechanical half of several review rules below; its `Suspicions` and not-checked list still need a reader's judgement, never a status change on their own. |
| `adr_delete` | Removes a `PROPOSED` decision entered by mistake -- see "Deleting a decision" below. |

`adr_add(name, adrContext, decision, consequences?, consideredOptions?, language?, addressesRequirements?, affectsContexts?, usesTerms?, relatedTo?)`:

- `name`, `adrContext`, `decision` are required (`adrContext`/`decision` each need at least 5
  characters -- a floor, not a quality target).
- `consequences` is a list of `{statement, type}`, `type` one of `POSITIVE`/`NEGATIVE`/
  `NEUTRAL`. `consideredOptions` is a list of `{name, rationale, outcome}`, `outcome` one of
  `CHOSEN`/`REJECTED` -- at most one option per decision may be `CHOSEN`. Both are optional but
  expected in practice -- treat an empty one as a finding to raise with the user, not something
  to silently skip. The call's result text names this itself: an empty list comes back with an
  inline warning (`no consequence recorded`/`no considered option recorded`), which is the cue,
  not a placeholder entry (see "Substantive consequences and considered options" below).
- There is **no** date parameter. A new record starts `PROPOSED`, which means precisely that
  nothing has been decided yet, so there is no date to carry. The date is stamped by the
  transition to `ACCEPTED`/`REJECTED` (see "Lifecycle" below) -- do not look for a way to set
  it here, and do not record it in the prose instead.
- `language` (BCP-47, e.g. `en`, `de`) is the tag every multilingual text this call writes
  (`name`, `adrContext`, `decision`, and any consequence/considered-option text) is recorded
  under. Optional -- falls back to the project's configured default language. `adr_get`/
  `adr_list` take a matching `displayLocale` to pick which language candidate is shown, again
  falling back to the project default.
- `addressesRequirements` (`FR-n`/`NFR-n`), `affectsContexts` (`BC-n`) and `usesTerms`
  (`TERM-n`) link to resources that **must already exist**. An unknown code is rejected by the
  tool itself with a didactic error -- if a reference doesn't obviously already exist, check
  with `req_list`/`bc_list`/`term_list` first (or create it: `req_add` / `bc_add` / `term_add`)
  rather than let the call fail as a surprise.
- `relatedTo` (`ADR-n`) links this decision to peer decisions ("see also"), each of which must
  already exist -- see "Related decisions" below.

## Context discipline -- read before writing

Read `adr_list` before adding a decision, the same way `/arknet:req-interview` reads
`req_list`/`uc_list`/`term_list` first. A decision judged in isolation misses the two defects
that only show up against the whole ADR set: **contradiction** (does this reverse or conflict
with an existing `PROPOSED`/`ACCEPTED` decision without saying so?) and **duplication** (is
this the same decision under a different title?). Surface either before writing, don't let two
silently-conflicting decisions both stand.

## Before writing -- two steps, in this order

Both steps run before `adr_add`, not in the review afterwards. By the time a review reaches a
record, a status transition is usually about to freeze its text, and the only remaining route
for a defect either step would have caught is a successor record.

### 1. Is this an ADR at all?

The tools accept anything that fills the required fields, and every rule below only asks whether
a record is *well written*: a naming convention, a local packaging choice, a piece of work
planning or a reversible default passes all of them. So ask the category question first, before
the record exists -- the cheapest place to keep a non-decision out of the store.

| # | Question | A "no" means |
|---|---|---|
| Q1 | **Reach.** Does it bear on structure (modules, bounded contexts), an interface or contract, a dependency (technology, library, external system), a quality attribute, or a construction technique that holds across the project? | A convention or a detail -- a doc comment, a style guide, the README. Not an ADR. |
| Q2 | **Cost of reversal.** Would reversing it in a year cost more than taking it did -- a migration, a broken contract, a rewrite in more than one place? | A reversible default -- configuration or a doc comment. Not an ADR. |
| Q3 | **A real alternative.** Was there at least one option a reasonable team could have chosen, or is the "alternative" a straw man? | No discretion was exercised: it is a constraint (`constraint_add`) or a plain fact, not a decision. |
| Q4 | **Category.** Is the core of it a HOW? A "must/shall" about system behaviour is a requirement (`req_add`), a definition is a glossary term (`term_add`), a date or a "later" is a tracker issue. | Hand that part off (see "Scope boundary") and write the ADR for the HOW remainder only -- if one is left. |

- **A "no" on Q1 or Q2 stops the write.** Say where the thing belongs instead, and do not call
  `adr_add`.
- **A "no" on Q3 does not.** An empty option space is allowed as long as the record says why it
  was empty (see "Substantive consequences and considered options"); Q3 exists to expose a
  straw-man option, not to force one into existence.
- **Project-wide is not the same as architecturally relevant.** A rule about naming, file
  placement or formatting holds everywhere and is still a convention -- it settles where things
  sit, not how the system is built. Q1 asks whether the decision constrains the *construction*
  of the system (a library it depends on, the technique its domain types are built with), not
  whether it happens to apply in every package.
- **Measure reach, not size.** "No Lombok" and "records, not entities, for domain types" are one
  sentence each and architecturally relevant -- a construction technique that holds across the
  project passes Q1. The expensive mistake is the decision that never gets recorded, not the one
  that sits `PROPOSED` a while longer: where Q1 and Q2 are genuinely close, write it and say so.

Put the result to the user as **its own question**, separate from the content confirmation that
follows (see "Correcting a decision") -- two lines, not a rendered table per invocation:

> This is an ADR because Q1: it fixes the persistence dependency for the whole service; Q2: a
> reversal means migrating the stored data. Agreed?

### 2. One decision, or several?

The independence test is a step in writing, not only rule R1 of the review. It falls on **every**
record you are about to write:

- Write `decision` out as its separate assertions -- **not only where they are numbered; a
  second decision hides in running prose far more often than in a numbered list.**
- Take them pairwise: could the later assertion have gone the other way without changing the
  earlier one? If yes, it is its own record. Applying this by feel finds nothing; do the split.
- **A handed-over list of split candidates is not the scope of this test.** Splitting the three
  records someone named and leaving the rest of the set untouched is exactly the failure this
  step exists to prevent -- when you write a whole set of decisions in one go, the test falls on
  each of them, including the ones nobody flagged.
- Then **run step 1 again on each fragment.** A split routinely frees trivial by-catch ("use
  PostgreSQL" plus "name the schema `app`": the first passes Q1, the second does not).

Only then call `adr_add` -- one call per surviving fragment.

## Writing quality -- independent of the store, still your job

The tools validate structure (required fields, minimum lengths, reference existence); they do
not validate decision *quality*. That is still yours to enforce:

- **One decision per record.** Enforced by the independence test in "Before writing", which is
  a step before `adr_add` and not a rule you check once the record exists. This matters even
  more here than on paper: `adr_supersede` points at the whole record, so a bundled ADR cannot
  be superseded in part -- reversing half of it means either superseding a decision that is
  still partly in force, or leaving the half you don't want standing.
- **No implementation detail.** No class names, method signatures, or literal parameter values
  in `decision`/`consequences`. The store has no file history a reader can consult to see a
  detail age past a rename -- an implementation detail written into `decision` goes stale
  exactly the same way it would in a file, just without a diff to notice it. The rule has a
  ceiling, though: the things the decision draws a boundary between or maps onto each other
  (a record and a triple, a daemon and a client, the vocabulary IRI it removes) are its
  subject, not a detail. A record that no longer says what it is about once they are
  abstracted away is too abstract, not too concrete. "Domain types stay plain records with
  no graph access; the translation to triples lives in the out-adapter alone" names both
  sides of the boundary and survives every rename; "the domain type has no graph access, the
  out-port translates" names neither and cannot be read without the code it was written
  against.
- **The litmus test.** Does the sentence go stale the moment someone changes code? If yes, it's
  wiring state, not a decision, and belongs in a doc comment or the issue tracker, not in
  `decision`/`consequences`.
- **Substantive consequences and considered options.** "No options considered" is a smell, not
  an answer -- if the option space genuinely was empty, say briefly why in `adrContext`.
  `consideredOptions` is where the discarded alternatives live, each with a `rationale`, and
  `outcome: CHOSEN` on the one taken -- the record of *why not X* is as much the point as the
  record of *why Y*. The same holds for `consequences`: a decision with none recorded has not
  been thought through. `adr_add`/`adr_update` already flag either empty list with an inline,
  non-blocking warning in their result text (`no consequence recorded`/`no considered option
  recorded`) -- that warning is the signal, not something to write around. On a `PROPOSED`
  record, note it and report it to the user rather than acting on it yourself; resolve it before
  the record goes `ACCEPTED` -- with real content or the brief reasoning above, never with a
  placeholder consequence or considered option invented only to make the warning go away.
- **Role-based language, not personal names.** Check `adrContext`/`decision`/every consequence
  `statement`/every considered option's `name`/`rationale` for named individuals (e.g. "Fred
  uses...") and replace with the store's existing convention of role-based language ("the
  user", "the operator"), matching how requirements and bounded contexts already phrase this.
  `adr_update` can still correct this while the decision is `PROPOSED` (see "Correcting a
  decision" below), but that window closes for good at `ACCEPTED` -- catch it before writing
  rather than relying on the correction path.
- **The decision is the user's, not yours.** An ADR records what the user decided. A choice you
  made on your own -- a library you picked, a split you judged best -- gets named as such and
  put to the user before `adr_add`, not written in as if already settled. If the decision is
  still open, `adrContext` names the openness and `decision` states your preference as a
  proposal; status stays `PROPOSED`, and the transition onward is the user's call (see
  "Accepting a proposal" below).
- **No `ADR-n` codes in the prose.** `adrContext`, `decision`, consequences and considered
  options name the thing itself ("the registered project identity"), never a peer decision's
  code -- the connection is carried by `relatedTo` (or `supersededBy`/`addressesRequirements`,
  as the case is), which `adr_get`/`adr_list` show. A record cannot know the code of a decision
  written after it, so a code in the prose is one split or reorder away from stale.

## Lifecycle -- SUPERSEDED is a real, written status

The ADR ontology defines five statuses (`Proposed`, `Accepted`, `Rejected`, `Deprecated`,
`Superseded`), and the tool surface implements all five. `adr_set_status` only ever sets
`ACCEPTED`, `REJECTED` or `DEPRECATED` (`PROPOSED -> ACCEPTED`, `PROPOSED -> REJECTED`,
`ACCEPTED -> DEPRECATED`) and explicitly refuses `SUPERSEDED` as a target, pointing the caller
at `adr_supersede` instead -- reaching `SUPERSEDED` always needs a named successor, which
`adr_set_status` has no parameter for.

**The transition to `ACCEPTED`/`REJECTED` is also what dates the decision** -- that moment *is*
the decision, so it is the only place the date is ever written. `adr_add`/`adr_update` cannot
touch it. Today's date is recorded unless the optional `decidedOn` (ISO-8601 `yyyy-MM-dd`) names
an earlier day; pass it only for a decision genuinely taken back then and entered only now, not
to tidy up a timeline. `DEPRECATED` refuses `decidedOn` outright: it retires a decision rather
than making one, and the original date stays as it was.

`adr_supersede` sets the *older* decision's status to `SUPERSEDED` **and** its `supersededBy`
edge to the newer decision, together in one write -- status and edge are coupled, never two
independently maintained signals. After the call, `adr_get`/`adr_list` show the older decision's
status as `SUPERSEDED` directly; there is no separate field to cross-check to know a decision is
no longer current.

What this means in practice:

- **Accepting a proposal.** Before calling `adr_set_status(id, "ACCEPTED")` on the user's
  request, state Q1 and Q2 from "Before writing" once, one line each. This is the moment the
  text freezes, which makes it the last and most effective place for the category question --
  cheap to record while `PROPOSED`, expensive once `ACCEPTED`. If the record carries any
  considered options, check that exactly one is `CHOSEN` -- `adr_set_status` refuses `ACCEPTED`
  otherwise; a record with no considered options at all stays acceptable. If none is `CHOSEN` yet,
  use `adr_update` (`consideredOptionCorrections`) to mark one first, then retry. Say it, do not
  decide on it: the transition still happens only because the user asked for it.
- **Rejecting a proposal.** Call `adr_set_status(id, "REJECTED")` -- do not fold the rejection
  into `consequences`/`decision` text as a workaround. `REJECTED` means the option was
  considered and turned down -- a decision worth keeping, not a mistaken entry to undo; it is
  deliberately not deletable either (see "Deleting a decision" below).
- **Deprecating a decision that became obsolete without a successor.** Call
  `adr_set_status(id, "DEPRECATED")`. If a newer decision replaces it instead, use
  `adr_supersede` (see below), not `DEPRECATED`.
- **Correcting a mistyped `adr_supersede` call.** Call `adr_unsupersede` -- see "Un-superseding a
  decision" below. Only on the user's request, like every status transition here.
- **Judging whether a decision is still in force.** Read the status: `SUPERSEDED` (like
  `REJECTED`/`DEPRECATED`) means it no longer is. `adr_get`'s `superseded by` field additionally
  names *which* decision replaced it.

## Superseding a decision

`adr_supersede(id, supersededId)`: `id` is the new, superseding decision; `supersededId` the
older one. **Both must already be `ACCEPTED`** -- write the new ADR first (`adr_add`, then
`adr_set_status` to `ACCEPTED` once it is genuinely decided), then link it. The call is
idempotent (recording the same pair twice is a no-op) and rejects a decision superseding
itself. **Naming a different successor for an already-superseded decision is refused** -- there
is no tool to change or remove a `supersededBy` edge once set, so double-check `id`/
`supersededId` before calling; a mistyped call is effectively permanent.

## Un-superseding a decision

`adr_unsupersede(id)`: a regret path for a mistyped `adr_supersede` call -- not a lifecycle step
and not a way to reverse a valid supersession. `id` here identifies the older, wrongly-superseded
decision, not the successor. Accepted only on a decision whose status is `SUPERSEDED`; refused on
any other status, with no no-op fallback for an already-correct one. In one write, it removes
that decision's `supersededBy` edge and sets its status back to `ACCEPTED`, mirroring how
`adr_supersede` sets both together in the other direction. The successor named by the mistaken
call is left untouched, so a fresh, correctly aimed `adr_supersede` call can follow. Like every
status transition, call it only on the user's explicit request -- never as an automatic recovery
from a call that returned an error.

## Correcting a decision

`adr_update(id, name?, adrContext?, decision?, newConsequences?, consequenceCorrections?, newConsideredOptions?, consideredOptionCorrections?, language?, addressesRequirements?, affectsContexts?, usesTerms?, relatedTo?)`:
every field but `id` is optional, and an omitted field is left unchanged -- never cleared.

- **`name`/`adrContext`/`decision`, and the `statement`/`type` of an existing consequence or the
  `name`/`rationale`/`outcome` of an existing considered option** (addressed by 1-based
  `position` via `consequenceCorrections`/`consideredOptionCorrections`) **are correctable only
  while the decision is `PROPOSED`** -- **unless** the call writes a language that field or
  position has never carried before, which counts as a translation and is allowed in *every*
  status; correcting the wording of a language the field/position already carries stays
  `PROPOSED`-only. Changing `type`/`outcome` is **never** exempt, regardless of language, once
  the decision is no longer `PROPOSED` -- classification is a judgement on the decision, not a
  fact of its wording. From `ACCEPTED` on, a refused text change means: record the correction as
  a new decision (`adr_add`) and link it with `adr_supersede` instead of trying to edit the
  original.
- **`newConsequences`/`newConsideredOptions`** append new entries and are allowed in *every*
  status -- adding a consequence noticed only later is not the same as rewriting one.
- **The four reference lists** (`addressesRequirements`, `affectsContexts`, `usesTerms`,
  `relatedTo`) are the deliberate exception and stay correctable in *every* status, so an edge
  to a requirement, bounded context, glossary term or peer decision that did not exist yet when
  the decision was made can still be completed. Passing a list replaces it wholesale; an empty
  list removes every edge of it; omitting it leaves it untouched.
- Status and the `supersededBy` relation are not touched here -- still `adr_set_status` and
  `adr_supersede`.

Because the text-field window closes at `ACCEPTED`, **confirm the content with the user before
calling `adr_add`** rather than write speculatively and plan to fix it up afterwards -- the
correction path exists, but only for as long as the decision stays `PROPOSED` (translations
aside).

## Related decisions (`relatedTo`)

A loose "see also" cross-reference between decisions of equal rank -- unlike `supersededBy`, it
carries no direction of replacement. Settable at `adr_add` and completed later with
`adr_update`; only the forward direction is stored (the decision recorded later names the
earlier one it relates to), but `arkarch:relatedTo` is a symmetric property, so `adr_get`/
`adr_list` read back a merged list regardless of which side wrote the edge. There is
deliberately no `adr_link_related` tool -- the relation is set only through `adr_add`/
`adr_update`.

## Deleting a decision

`adr_delete(id)` removes a decision and every triple it carries -- not a correction, the whole
record is gone. The freed code is **not** handed out again; the next `adr_add` continues above
it.

- **Only `PROPOSED` is deletable.** This undoes a record entered by mistake -- a duplicate, a
  draft that belongs elsewhere. From `ACCEPTED` on the record stays: what was decided is
  exactly what an ADR exists to keep. Use `adr_supersede` or
  `adr_set_status(id, "DEPRECATED")` instead.
- **`REJECTED` is explicitly not deletable either** -- see "Lifecycle" above: it means the
  option was considered and turned down, a decision worth keeping, not a mistake to undo.
- **Refused while another decision still points at this one** -- named as its own successor
  (`supersededBy`) or via `relatedTo`; the refusal names those decisions. There is no tool to
  remove a `supersededBy` edge, so that block can only be cleared by removing the pointing
  decision itself (or, for `relatedTo`, correcting it away with `adr_update`).

## Reviewing the ADRs in the store

A review covers **every** decision in the store, not the ones that prompted it. The failure this
section exists to prevent is not a missing rule -- it is a rule applied to one record and not to
the rest. A prose verdict cannot be seen to be incomplete; a table can. So the review
**always** ends in the table below, one row per record, and an empty cell means "not checked",
never "fine".

### 1. Read everything first

`adr_check` first -- its `Facts` are the source for the mechanical part of R3, R4, R5, R6, R7 and
R8 below; do not re-derive them by rereading the corpus for the same patterns. Its
`Suspicions` and its not-checked list are candidates, not findings -- each still needs a
reader's judgement (see the rules below), and neither ever moves a status on its own. Then
`adr_list` for the overview, and `adr_get` for **each** record -- the compact list omits the
text the remaining, judgement-only rules are about. Two defects only show up against the whole
set and have no row of their own, so check them once across the corpus and report them under
the table:

- **Contradiction** -- does one decision reverse or conflict with another without saying so?
- **Duplication and orphaned neighbours** -- `adr_check`'s `Suspicions` already flag two
  decisions with near-identical titles as a hint; a reader still judges whether it is the same
  decision recorded twice, not just similar wording. Do two records that govern the same subject
  fail to reference each other? (A reader who finds one must be able to reach the other;
  `relatedTo` is what carries that -- `adr_check` does not check this.)

`impact_analysis(code)` walks `addressesRequirement`/`affectsContext`/`usesTerm` backward (change
the requirement/context/glossary term, the ADR is affected) and `supersededBy` forward -- use it
before treating a decision as safe to leave unlinked or superseded, the same way
`/arknet:req-interview` uses it after every written change.

### 2. Per-record rules

| # | Rule | How to apply it |
|---|---|---|
| R0 | Worth recording at all | Q1 (reach) and Q2 (cost of reversal) from "Before writing", applied to the finished record. A convention, a local detail, a reversible default or a piece of work planning fails here while every rule below reads `ok` -- that combination is the whole reason this row exists. |
| R1 | One decision | The independence test of "Before writing", applied to a record that already exists: split `decision` into its separate assertions -- not only where the text numbers them -- and take them pairwise: could the later one have gone the other way without changing the earlier one? If yes, it is its own record. Applying this by feel finds nothing; do the split. |
| R2 | No implementation detail | Class, module or annotation names, method signatures, literal values (ports, addresses, keys, paths). A term the record itself decides about (a vocabulary IRI it removes, a tool prefix it keeps) is the subject, not a detail -- and so are the things the decision draws a boundary between or maps onto each other (a record and a triple, a daemon and a client). A record that no longer says what it is about without them is too abstract, not too concrete; abstracting them away is a finding under this rule, not a pass. |
| R3 | No external references | `adr_check`'s `Suspicions` already flag a tracker-looking reference (`#123`); a reader confirms the flag is actually one (not, say, a decision or option count that happens to look like it) and decides how to rewrite the record so it stands on its own without it. |
| R4 | No status prose | `adr_check`'s `Suspicions` already flag "today"/"currently"/"not yet"/"so far"-style wording in `decision` or a consequence; a reader judges whether the flagged phrase genuinely describes a transient state that will go stale, not a quoted title or a fixed name. In `adrContext` such wording is legitimate either way -- it describes the situation the decision was taken in, and `adr_check` does not flag it there. |
| R5 | Substantive consequences and options | `adr_check`'s `Facts` already flag a record with no consequence or no considered option recorded, and a taken decision (`ACCEPTED` on) with nothing `CHOSEN`. What is left for a reader: whether a populated list is actually substantive -- every considered option carries a real rationale, not a placeholder; the record's own reasoning for an empty space (see "Substantive consequences and considered options" above) is adequate, never invented after the fact just to clear the tool's finding; and negative consequences are present -- a record with only positive ones has not been thought through. |
| R6 | References resolve | `adr_check`'s `Facts` already flag an `ADR-n` named in the prose that the store does not hold. What is left for a reader: whether `addressesRequirements`/`affectsContexts`/`usesTerms` name the *right* requirement/context/term for what the decision is actually about, not merely one that happens to exist. |
| R7 | Prose matches the graph | `adr_check`'s `Facts` already flag an `ADR-n` named in the text with no `supersedes`/`supersededBy`/`relatedTo` edge backing it. What is left for a reader: whether an edge that does exist is the right relation for what the prose actually says -- a `relatedTo` doing the work of an unrecorded `supersededBy`, or the reverse -- since the tool checks presence, not fit. |
| R8 | Status is honest | `adr_check`'s `Facts` already flag a `decisionDate` on a record not yet taken (still `PROPOSED`) -- a leftover, not something to act on by itself. What is left for a reader: whether a shipped decision still reads `PROPOSED`, and whether a `PROPOSED` record whose decision was never confirmed by the user is a question back to them rather than a candidate for `ACCEPTED`. Never flip a status yourself -- neither on your own reading of the build state nor on the strength of an `adr_check` finding (see below). |

### 3. Report as a table

| Record | R0 | R1 | R2 | R3 | R4 | R5 | R6 | R7 | R8 |
|---|---|---|---|---|---|---|---|---|---|
| ADR-1 | ok | ok | ok | ok | ok | ok | ok | ok | ok |
| ADR-2 | ok | *finding* | ok | ... | | | | | |

`ok` or a short finding per cell. Then the corpus-wide findings from step 1, then the ranked
list of what to do. A record you did not reach gets a row too, marked as unchecked -- the point
of the table is that the gap is visible.

### 4. What follows from a finding

- **An R0 finding on a `PROPOSED` record: propose `adr_delete`.** That is precisely the "draft
  that belongs elsewhere" case the delete path exists for (see "Deleting a decision"). Propose
  it and name where the content belongs instead; the user deletes, you do not decide it away.
- **An R0 finding on an `ACCEPTED` record: report it, do not act.** There is no status for
  "should never have been an ADR" -- `DEPRECATED` says "no longer in force", a different
  statement about a real decision. Report the finding and leave the choice between leaving it
  standing and `adr_set_status(id, "DEPRECATED")` to the user.
- A finding on R1-R7 is a text correction: possible **only while the record is `PROPOSED`**
  (translations aside, see "Correcting a decision"). Raise them before any status transition,
  not after -- from `ACCEPTED` on the only remaining route is a successor record.
- A decision that is `ACCEPTED` but no longer actually followed -- and not superseded -- should
  be flagged to the user for `adr_set_status` to `DEPRECATED`, not left stale. Since
  `SUPERSEDED` is a written status, `adr_list`'s status column already tells a superseded
  decision apart from one still in force; `adr_get`'s `superseded by` field names which decision
  replaced it.
- **Never transition a status yourself on the strength of your own reading of the build state, or
  of an `adr_check` finding.** A `Fact` is decidable as stated, a `Suspicion` is a hint a reader
  rules on -- neither is a status decision by itself; R8 reports the mismatch, the user decides.

## Scope boundary

- **HOW, not WHAT/WHY.** Requirements, use cases and glossary terms belong to
  `/arknet:req-interview`; this skill only records the architectural decision itself.
- **A WHAT inside the draft is handed over, not absorbed.** When a draft decision carries a
  requirement in its first half ("because responses have to arrive in under 200 ms, a cache is
  introduced"), name that half, offer the handoff to `/arknet:req-interview` (`req_add` for a
  quality attribute, `constraint_add` for an imposed limit), and keep the ADR for the HOW
  remainder ("introduce a cache") only. Link the two afterwards with `addressesRequirements`, so
  the decision keeps the reason it was taken for. This is the mirror image of the handoff
  `/arknet:req-interview` already offers in the other direction.
- **Store, not files.** A project still on file-based ADRs belongs to `/arknet:legacy-adr`, not
  here.
