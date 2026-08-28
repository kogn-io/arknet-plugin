---
description: "Write, review and maintain Architecture Decision Records as first-class resources in the arknet store (arkarch:ArchitectureDecisionRecord), via arknet's adr_add/adr_list/adr_get/adr_set_status/adr_supersede/adr_update/adr_delete MCP tools -- not Markdown files. Keeps every ADR a durable decision record: one decision per record, free of implementation detail, references only requirements/bounded contexts that already exist. Trigger (also DE, since the user may phrase it in German): /arknet:adr, 'write an ADR', 'new ADR', 'ADR for X', 'review this ADR', 'maintain the ADRs', 'is this a good ADR', 'supersede this ADR'; DE: 'schreib ein ADR', 'neues ADR', 'ADR fuer X', 'review das ADR', 'pflege die ADRs', 'loese dieses ADR ab'. NOT for a project that still keeps file-based Markdown ADRs under docs/adr/ (use /arknet:legacy-adr there instead). NOT for general documentation, NOT for requirements (use /arknet:req-interview), NOT for code comments."
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

## The seven tools

| Tool | Purpose |
|---|---|
| `adr_add` | Record a new decision. Always starts `PROPOSED`; takes no status parameter. |
| `adr_list` | One compact line per decision: code, status, title, addresses/affects/supersedes/superseded-by/related-to. |
| `adr_get` | A single decision's full text, plus both directions of `supersededBy` and every related decision. |
| `adr_set_status` | Transitions: `PROPOSED -> ACCEPTED`, `PROPOSED -> REJECTED`, `ACCEPTED -> DEPRECATED`. Refuses `SUPERSEDED` -- that one needs `adr_supersede`. Also stamps the decision date -- the only place it is ever set. |
| `adr_supersede` | Records that one decision replaces an older one -- sets the older decision's status to `SUPERSEDED` too (see "Lifecycle" below). |
| `adr_update` | Corrects an already-recorded decision -- see "Correcting a decision" below. |
| `adr_delete` | Removes a `PROPOSED` decision entered by mistake -- see "Deleting a decision" below. |

`adr_add(name, adrContext, decision, consequences?, consideredOptions?, language?, addressesRequirements?, affectsContexts?, relatedTo?)`:

- `name`, `adrContext`, `decision` are required (`adrContext`/`decision` each need at least 5
  characters -- a floor, not a quality target).
- `consequences` is a list of `{statement, type}`, `type` one of `POSITIVE`/`NEGATIVE`/
  `NEUTRAL`. `consideredOptions` is a list of `{name, rationale, outcome}`, `outcome` one of
  `CHOSEN`/`REJECTED` -- at most one option per decision may be `CHOSEN`. Both are optional but
  expected in practice -- treat an empty one as a finding to raise with the user, not something
  to silently skip.
- There is **no** date parameter. A new record starts `PROPOSED`, which means precisely that
  nothing has been decided yet, so there is no date to carry. The date is stamped by the
  transition to `ACCEPTED`/`REJECTED` (see "Lifecycle" below) -- do not look for a way to set
  it here, and do not record it in the prose instead.
- `language` (BCP-47, e.g. `en`, `de`) is the tag every multilingual text this call writes
  (`name`, `adrContext`, `decision`, and any consequence/considered-option text) is recorded
  under. Optional -- falls back to the project's configured default language. `adr_get`/
  `adr_list` take a matching `displayLocale` to pick which language candidate is shown, again
  falling back to the project default.
- `addressesRequirements` (`FR-n`/`NFR-n`) and `affectsContexts` (`BC-n`) link to resources
  that **must already exist**. An unknown code is rejected by the tool itself with a didactic
  error -- if a reference doesn't obviously already exist, check with `req_list`/`bc_list`
  first (or create it: `req_add` / `bc_add`) rather than let the call fail as a surprise.
- `relatedTo` (`ADR-n`) links this decision to peer decisions ("see also"), each of which must
  already exist -- see "Related decisions" below.

## Context discipline -- read before writing

Read `adr_list` before adding a decision, the same way `/arknet:req-interview` reads
`req_list`/`uc_list`/`term_list` first. A decision judged in isolation misses the two defects
that only show up against the whole ADR set: **contradiction** (does this reverse or conflict
with an existing `PROPOSED`/`ACCEPTED` decision without saying so?) and **duplication** (is
this the same decision under a different title?). Surface either before writing, don't let two
silently-conflicting decisions both stand.

## Writing quality -- independent of the store, still your job

The tools validate structure (required fields, minimum lengths, reference existence); they do
not validate decision *quality*. That is still yours to enforce:

- **One decision per record.** Apply the independence test: split `decision` into its separate
  assertions -- **not only where they are numbered; a second decision hides in running prose far
  more often than in a numbered list** -- and take them pairwise: could the later assertion have
  gone the other way without changing the earlier one? If yes, it is its own ADR. This matters even more here than on paper: `adr_supersede` points at the whole
  record, so a bundled ADR cannot be superseded in part -- reversing half of it means either
  superseding a decision that is still partly in force, or leaving the half you don't want
  standing.
- **No implementation detail.** No class names, method signatures, or literal parameter values
  in `decision`/`consequences`. The store has no file history a reader can consult to see a
  detail age past a rename -- an implementation detail written into `decision` goes stale
  exactly the same way it would in a file, just without a diff to notice it.
- **The litmus test.** Does the sentence go stale the moment someone changes code? If yes, it's
  wiring state, not a decision, and belongs in a doc comment or the issue tracker, not in
  `decision`/`consequences`.
- **Substantive considered options.** "No options considered" is a smell, not an answer -- if
  the option space genuinely was empty, say briefly why. `consideredOptions` is where the
  discarded alternatives live, each with a `rationale`, and `outcome: CHOSEN` on the one taken --
  the record of *why not X* is as much the point as the record of *why Y*.
- **Role-based language, not personal names.** Check `adrContext`/`decision`/every consequence
  `statement`/every considered option's `name`/`rationale` for named individuals (e.g. "Fred
  uses...") and replace with the store's existing convention of role-based language ("the
  user", "the operator"), matching how requirements and bounded contexts already phrase this.
  `adr_update` can still correct this while the decision is `PROPOSED` (see "Correcting a
  decision" below), but that window closes for good at `ACCEPTED` -- catch it before writing
  rather than relying on the correction path.

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

- **Rejecting a proposal.** Call `adr_set_status(id, "REJECTED")` -- do not fold the rejection
  into `consequences`/`decision` text as a workaround. `REJECTED` means the option was
  considered and turned down -- a decision worth keeping, not a mistaken entry to undo; it is
  deliberately not deletable either (see "Deleting a decision" below).
- **Deprecating a decision that became obsolete without a successor.** Call
  `adr_set_status(id, "DEPRECATED")`. If a newer decision replaces it instead, use
  `adr_supersede` (see below), not `DEPRECATED`.
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

## Correcting a decision

`adr_update(id, name?, adrContext?, decision?, newConsequences?, consequenceCorrections?, newConsideredOptions?, consideredOptionCorrections?, language?, addressesRequirements?, affectsContexts?, relatedTo?)`:
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
- **The three reference lists** (`addressesRequirements`, `affectsContexts`, `relatedTo`) are
  the deliberate exception and stay correctable in *every* status, so an edge to a requirement,
  bounded context or peer decision that did not exist yet when the decision was made can still
  be completed. Passing a list replaces it wholesale; an empty list removes every edge of it;
  omitting it leaves it untouched.
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

`adr_list` for the overview, then `adr_get` for **each** record -- the compact list omits the
text every rule below is about. Two defects only show up against the whole set and have no row
of their own, so check them once across the corpus and report them under the table:

- **Contradiction** -- does one decision reverse or conflict with another without saying so?
- **Duplication and orphaned neighbours** -- is the same decision recorded twice under different
  titles? Do two records that govern the same subject fail to reference each other? (A reader
  who finds one must be able to reach the other; `relatedTo` is what carries that.)

`impact_analysis(code)` walks `addressesRequirement`/`affectsContext` backward (change the
requirement/context, the ADR is affected) and `supersededBy` forward -- use it before treating a
decision as safe to leave unlinked or superseded, the same way `/arknet:req-interview` uses it
after every written change.

### 2. Per-record rules

| # | Rule | How to apply it |
|---|---|---|
| R1 | One decision | Split `decision` into its separate assertions -- not only where the text numbers them -- and take them pairwise: could the later one have gone the other way without changing the earlier one? If yes, it is its own record. Applying this by feel finds nothing; do the split. |
| R2 | No implementation detail | Class, module or annotation names, method signatures, literal values (ports, addresses, keys, paths). A term the record itself decides about (a vocabulary IRI it removes, a tool prefix it keeps) is the subject, not a detail. |
| R3 | No external references | Issue, PR or commit numbers (`#123`). The record has to stand on its own; a tracker id ages worse than the decision and says nothing to a later reader. |
| R4 | No status prose | "today", "currently", "not yet", "so far" in `decision` or a consequence. In `adrContext` they are legitimate -- it describes the situation the decision was taken in. |
| R5 | Substantive consequences and options | Both populated; every option carries a rationale; exactly one `CHOSEN`. Negative consequences present -- a record with only positive ones has not been thought through. |
| R6 | References resolve | `addressesRequirements`/`affectsContexts` still name requirements/contexts that exist (`req_get`/`bc_get` -- the store validates references on write, not on read). No `ADR-n` in the prose that the store does not hold. |
| R7 | Prose matches the graph | Every peer decision named in the text also has a `relatedTo`/`supersededBy` edge, and every edge is one a reader can follow. Edges copied from elsewhere are the usual cause of a mismatch. |
| R8 | Status is honest | A shipped decision reads `ACCEPTED`, not still `PROPOSED`. A `decisionDate` on a `PROPOSED` record is a leftover -- nothing has been decided yet. Never flip a status on your own reading of the build state (see below). |

### 3. Report as a table

| Record | R1 | R2 | R3 | R4 | R5 | R6 | R7 | R8 |
|---|---|---|---|---|---|---|---|---|
| ADR-1 | ok | ok | ok | ok | ok | ok | ok | ok |
| ADR-2 | *finding* | ok | ... | | | | | |

`ok` or a short finding per cell. Then the corpus-wide findings from step 1, then the ranked
list of what to do. A record you did not reach gets a row too, marked as unchecked -- the point
of the table is that the gap is visible.

### 4. What follows from a finding

- A finding on R1-R7 is a text correction: possible **only while the record is `PROPOSED`**
  (translations aside, see "Correcting a decision"). Raise them before any status transition,
  not after -- from `ACCEPTED` on the only remaining route is a successor record.
- A decision that is `ACCEPTED` but no longer actually followed -- and not superseded -- should
  be flagged to the user for `adr_set_status` to `DEPRECATED`, not left stale. Since
  `SUPERSEDED` is a written status, `adr_list`'s status column already tells a superseded
  decision apart from one still in force; `adr_get`'s `superseded by` field names which decision
  replaced it.
- **Never transition a status yourself on the strength of your own reading of the build state.**
  R8 reports the mismatch; the user decides.

## Scope boundary

- **HOW, not WHAT/WHY.** Requirements, use cases and glossary terms belong to
  `/arknet:req-interview`; this skill only records the architectural decision itself.
- **Store, not files.** A project still on file-based ADRs belongs to `/arknet:legacy-adr`, not
  here.
