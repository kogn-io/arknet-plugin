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
| `adr_list` | One compact line per decision: code, status, title, addresses/affects/supersedes/superseded-by. |
| `adr_get` | A single decision's full text, plus both directions of `supersedes`. |
| `adr_set_status` | Transitions: `PROPOSED -> ACCEPTED`, `PROPOSED -> REJECTED`, `ACCEPTED -> DEPRECATED`. |
| `adr_supersede` | Records that one decision replaces an older one (relation only -- see "Lifecycle" below). |
| `adr_update` | Corrects an already-recorded decision -- see "Correcting a decision" below. |
| `adr_delete` | Removes a `PROPOSED` decision entered by mistake -- see "Deleting a decision" below. |

`adr_add(name, adrContext, decision, consequences?, alternatives?, decisionDate?, addressesRequirements?, affectsContexts?, relatedTo?)`:

- `name`, `adrContext`, `decision` are required (`adrContext`/`decision` each need at least 5
  characters -- a floor, not a quality target).
- `consequences`, `alternatives` are optional but expected in practice (SHACL flags a missing
  one as a warning, not a hard rejection) -- treat an empty one as a finding to raise with the
  user, not something to silently skip.
- `decisionDate` is optional ISO-8601 (`yyyy-MM-dd`) -- only set it once the decision has
  actually been made, not as a placeholder.
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

- **One decision per record.** Apply the independence test: could a numbered point in
  `decision` have gone the other way without changing the point before it? If yes, it is its
  own ADR. This matters even more here than on paper: `adr_supersede` points at the whole
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
- **Substantive alternatives.** "No alternatives considered" is a smell, not an answer -- if the
  option space genuinely was empty, say briefly why.
- **Role-based language, not personal names.** Check `adrContext`/`decision`/`consequences`/
  `alternatives` for named individuals (e.g. "Fred uses...") and replace with the store's
  existing convention of role-based language ("the user", "the operator"), matching how
  requirements and bounded contexts already phrase this. `adr_update` can still correct this
  while the decision is `PROPOSED` (see "Correcting a decision" below), but that window closes
  for good at `ACCEPTED` -- catch it before writing rather than relying on the correction path.

## Lifecycle -- narrower than the ontology

The ADR ontology defines five statuses (`Proposed`, `Accepted`, `Rejected`, `Deprecated`,
`Superseded`). The tool surface implements four of them: `adr_set_status` supports
`PROPOSED -> ACCEPTED`, `PROPOSED -> REJECTED`, and `ACCEPTED -> DEPRECATED` -- any other
transition errors. `Superseded` is still not a settable status: `adr_supersede` does **not**
change the superseded decision's status, it only records the `supersedes` relation. An old ADR
keeps whatever status it had (typically `ACCEPTED`) forever; the fact that it has been
superseded is visible only through the `supersedes`/`superseded by` fields `adr_get`/`adr_list`
render, never through the status line.

What this means in practice:

- **Rejecting a proposal.** Call `adr_set_status(id, "REJECTED")` -- do not fold the rejection
  into `consequences`/`decision` text as a workaround. `REJECTED` means the option was
  considered and turned down -- a decision worth keeping, not a mistaken entry to undo; it is
  deliberately not deletable either (see "Deleting a decision" below).
- **Deprecating a decision that became obsolete without a successor.** Call
  `adr_set_status(id, "DEPRECATED")`. If a newer decision replaces it instead, use
  `adr_supersede` (see below), not `DEPRECATED`.
- **Judging whether a decision is still in force.** Never read only the status. After an
  `adr_supersede` call, the superseded decision still reads `ACCEPTED` -- check its
  `superseded by` field (via `adr_get`, or the inline annotation `adr_list` already shows) before
  treating an `ACCEPTED` decision as current.

## Superseding a decision

`adr_supersede(id, supersededId)`: `id` is the new, superseding decision; `supersededId` the
older one. Both must already exist -- write the new ADR first (`adr_add`, then
`adr_set_status` to `ACCEPTED` once it is genuinely decided), then link it. The call is
idempotent (recording the same pair twice is a no-op) and rejects a decision superseding
itself. There is no back-reference to maintain: `adr_get`/`adr_list` derive "superseded by" on
the superseded record by reading the relation in reverse -- never write it from the other side.

## Correcting a decision

`adr_update(id, name?, adrContext?, decision?, consequences?, alternatives?, decisionDate?, addressesRequirements?, affectsContexts?, relatedTo?)`:
every field but `id` is optional, and an omitted field is left unchanged -- never cleared.

- **Text fields** (`name`, `adrContext`, `decision`, `consequences`, `alternatives`,
  `decisionDate`) are correctable only while the decision is `PROPOSED`. From `ACCEPTED` on
  (and likewise `REJECTED`/`DEPRECATED`) the tool refuses a text change, because a decision in
  force records what was decided at the time -- record the correction as a new decision
  (`adr_add`) and link it with `adr_supersede` instead of trying to edit the original.
- **The three reference lists** (`addressesRequirements`, `affectsContexts`, `relatedTo`) are
  the deliberate exception and stay correctable in *every* status, so an edge to a requirement,
  bounded context or peer decision that did not exist yet when the decision was made can still
  be completed. Passing a list replaces it wholesale; an empty list removes every edge of it;
  omitting it leaves it untouched.
- Status and the `supersedes` relation are not touched here -- still `adr_set_status` and
  `adr_supersede`.

Because the text-field window closes at `ACCEPTED`, **confirm the content with the user before
calling `adr_add`** rather than write speculatively and plan to fix it up afterwards -- the
correction path exists, but only for as long as the decision stays `PROPOSED`.

## Related decisions (`relatedTo`)

A loose "see also" cross-reference between decisions of equal rank -- unlike `supersedes`, it
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
- **Refused while another decision still points at this one** via `supersedes` or `relatedTo`;
  the refusal names those decisions. Note the asymmetry this creates with "Superseding a
  decision" above: `arkarch:supersedes` itself has no removal path, so a superseded `PROPOSED`
  record can never be deleted once something points at it, and a mistyped `adr_supersede` call
  is permanent -- double-check `id`/`supersededId` before calling it.

## Reviewing the ADRs in the store

- `adr_list` for the overview; `adr_get` for one decision's full text.
- `impact_analysis(code)` walks `addressesRequirement`/`affectsContext`/`supersedes` backward
  from a requirement, bounded context, or ADR -- use it before treating a decision as safe to
  leave unlinked or superseded, the same way `/arknet:req-interview` uses it after every written
  change.
- Per-decision checklist: one decision per record (independence test); no implementation
  detail; `consequences`/`alternatives` populated and substantive, not empty or dutiful;
  `addressesRequirements`/`affectsContexts` still resolve to requirements/contexts that
  actually exist (`req_get`/`bc_get` -- the store does not re-validate references on read, only
  on write); a shipped decision reads `ACCEPTED`, not still `PROPOSED`.
- A decision that is `ACCEPTED` but no longer actually followed -- and not superseded by
  another ADR -- should be flagged to the user for `adr_set_status` to `DEPRECATED`, not left
  stale. What you still cannot check from status alone: `Superseded` is never written as a
  status (see "Lifecycle") -- always cross-check `superseded by` before trusting `ACCEPTED`.

## Scope boundary

- **HOW, not WHAT/WHY.** Requirements, use cases and glossary terms belong to
  `/arknet:req-interview`; this skill only records the architectural decision itself.
- **Store, not files.** A project still on file-based ADRs belongs to `/arknet:legacy-adr`, not
  here.
