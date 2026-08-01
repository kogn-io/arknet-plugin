---
description: "Write, review and maintain Architecture Decision Records as first-class resources in the arknet store (arkarch:ArchitectureDecisionRecord), via arknet's adr_add/adr_list/adr_get/adr_set_status/adr_supersede MCP tools -- not Markdown files. Keeps every ADR a durable decision record: one decision per record, free of implementation detail, references only requirements/bounded contexts that already exist. Trigger (also DE, since the user may phrase it in German): /arknet:adr, 'write an ADR', 'new ADR', 'ADR for X', 'review this ADR', 'maintain the ADRs', 'is this a good ADR', 'supersede this ADR'; DE: 'schreib ein ADR', 'neues ADR', 'ADR fuer X', 'review das ADR', 'pflege die ADRs', 'loese dieses ADR ab'. NOT for a project that still keeps file-based Markdown ADRs under docs/adr/ (use /arknet:legacy-adr there instead). NOT for general documentation, NOT for requirements (use /arknet:req-interview), NOT for code comments."
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

## The five tools

| Tool | Purpose |
|---|---|
| `adr_add` | Record a new decision. Always starts `PROPOSED`; takes no status parameter. |
| `adr_list` | One compact line per decision: code, status, title, addresses/affects/supersedes/superseded-by. |
| `adr_get` | A single decision's full text, plus both directions of `supersedes`. |
| `adr_set_status` | Transitions: `PROPOSED -> ACCEPTED`, `PROPOSED -> REJECTED`, `ACCEPTED -> DEPRECATED`. |
| `adr_supersede` | Records that one decision replaces an older one (relation only -- see "Lifecycle" below). |

`adr_add(name, adrContext, decision, consequences?, alternatives?, decisionDate?, addressesRequirements?, affectsContexts?)`:

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

## Context discipline -- read before writing

Read `adr_list` before adding a decision, the same way `/arknet:req-interview` reads
`req_list`/`uc_list`/`term_list` first. A decision judged in isolation misses the two defects
that only show up against the whole register: **contradiction** (does this reverse or conflict
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
  into `consequences`/`decision` text as a workaround.
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

## No correction path

There is no `adr_update` and no delete tool. A `PROPOSED` decision entered with wrong or
incomplete text cannot be edited afterwards -- only accepted as-is, superseded later, or left
standing as a permanent, imperfect record. Because of this, **confirm the content with the user
before calling `adr_add`**, rather than write speculatively and plan to fix it up. This is
tighter than the legacy Markdown skill's `Proposed`-is-freely-editable rule: here, nothing is
freely editable, not even at `Proposed`.

## Reviewing the register

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
