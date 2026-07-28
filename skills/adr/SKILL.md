---
description: "Write, review and maintain Architecture Decision Records in docs/adr/, against arknet's ADR metamodel (arkarch:ArchitectureDecisionRecord). Keeps ADRs durable decision records rather than status reports, and immutable from status Accepted on -- corrections go through a successor ADR, never through an addendum. Trigger (also DE, since the user may phrase it in German): /arknet:adr, 'write an ADR', 'new ADR', 'ADR for X', 'review this ADR', 'maintain the ADRs', 'is this a good ADR'; DE: 'schreib ein ADR', 'neues ADR', 'ADR fuer X', 'review das ADR', 'pflege die ADRs'. NOT for general documentation, NOT for requirements (use /arknet:req-interview), NOT for code comments."
---

# /arknet:adr -- Architecture Decision Records

You maintain the Architecture Decision Records of the project you are working in --
conventionally `docs/adr/`, unless that project puts them elsewhere. Your single job: keep
every ADR a record of a **durable decision and its lasting consequences** -- never a status
report, never an implementation snapshot.

Two rules override everything else in this skill, and you apply them before any other
judgement:

1. **From `Accepted` on, an ADR is frozen.** Do not edit it, do not amend it, do not tidy
   it up -- only its status line may still change. If something is wrong or new: a new ADR
   that supersedes the old one. See "Immutability".
2. **Cross-references are written one-sidedly.** Never touch a second ADR just to maintain
   a back-reference -- the metamodel derives the reverse direction.

The authority here is not taste. It is arknet's ADR metamodel, class
`arkarch:ArchitectureDecisionRecord`, reproduced in full in the next section. If a sentence
has no home in a metamodel slot, it does not belong in the ADR.

## Adapt to the project, do not impose

This skill ships rules, not a house style. Before writing or reviewing, look at what the
project already does (`ls docs/adr/`, read one or two records) and match it:

- **Language.** Existing ADRs set it -- keep writing in theirs. Only if the project has no
  ADRs yet, use English, and use the English section names from the template below.
- **Section names.** Whatever the existing records use for the four metamodel slots. A
  German corpus reads `## Kontext / ## Entscheidung / ## Konsequenzen / ## Alternativen`;
  do not "correct" it to English.
- **Numbering, file naming, character set.** Follow the corpus. Only when nothing exists
  yet, fall back to the defaults in "Template".

What you do *not* adapt to is the substance: the slots, the litmus test, immutability and
one-sided references hold in every project. A corpus that violates them is a finding, not a
convention.

## The metamodel defines the ONLY allowed content

These are the slots `arkarch:ArchitectureDecisionRecord` permits. There are no others.

| Metamodel slot | Meaning | Markdown section |
|----------------|---------|------------------|
| `dcterms:identifier` | number (mandatory, exactly 1) | filename + title |
| `arkarch:adrStatus` | exactly 1: Proposed / Accepted / Rejected / Deprecated / Superseded | `Status:` line |
| `arkarch:decisionDate` | date the decision was made | date in the `Status:` line |
| `arkarch:adrContext` | why did this have to be decided? forces and constraints | Context section |
| `arkarch:adrDecision` | the decision that was made | Decision section |
| `arkarch:adrConsequences` | positive and negative consequences of the decision | Consequences section |
| `arkarch:adrAlternatives` | options considered and rejected, with reasons | Alternatives section |
| `arkarch:relatedTo` | loose cross-reference -- written **one-sidedly** | `Related:` line |
| `arkarch:supersedes` | this ADR replaces an older one -- stated **only here**, in the new record | `Supersedes:` line |
| `arkarch:supersededBy` | inverse of `supersedes`, **derived, never maintained** | status line of the superseded ADR |
| `arkarch:addressesRequirement` | traceability to a requirement | optional, in Context/Decision |
| `arkarch:affectsContext` | bounded context affected | optional, in Context/Decision |

If you catch yourself writing an "Open points", "Implementation", "Status", "TODO",
"Current state", "Addendum" or "Next steps" section -- **stop**. No such slot exists. That
content belongs elsewhere (see below).

## The litmus test (apply to every sentence)

> **Does this sentence go stale the moment someone changes code?**
> Yes -> out. It is wiring state, not decision content.
> No  -> it is a durable consequence and may stay.

Worked example -- the same fact in both forms:

- OUT (snapshot): "the transport currently pins the tenant to the default value, so in
  practice it runs single-tenant." Stale as soon as someone wires the real tenant through.
- STAYS (durable consequence): "No tenant management and no defined origin of the tenant id
  per session -- deliberately left open until the need is concrete."

Same decision, but one form is a decision record and the other is a status line pretending
to be one.

The test applies **while writing**, as long as the ADR is `Proposed`. From `Accepted` on it
is a diagnostic, not a repair tool: you name the snapshot, but you no longer remove it from
the record. See "Immutability".

## Anti-patterns -- the failure class to guard against

The recurring mistake is smuggling transient implementation state into a durable document.
Concretely, NEVER put these in an ADR:

1. **Implementation snapshot** -- "currently pinned to X", "solved for now via a local
   override in the build file", "only one adapter wired so far". Wiring state, not decision.
2. **Open-points / TODO list** -- open work is an issue, not an ADR section. (A *deliberately
   deferred* consequence with a reason is allowed -- that is a result of the decision, not a
   worklist.)
3. **Commit refs / PR numbers / file lines** -- "see commit fcfaf29", "in ModelLoader.java
   line 42". Transient; belongs in git or the tracker, not in the ADR.
4. **Addendum / amendment / update section** -- a heading like
   `## Addendum 2026-07-18: third consumer (issue #66, PR #133)` records that a decision was
   *applied again*. That is progress, not decision. Either it genuinely refines the decision
   -- then it is **its own ADR** superseding the old one -- or it belongs in the tracker.
   There is no third case. See "Immutability".
5. **"Implementation" / "Status" / "Next steps" section** -- no metamodel slot.
6. **The agent deciding by itself** -- an ADR records the decision of *the user*, not yours.
   If the decision has not been made yet: status `Proposed`, and name the openness in the
   context -- do not invent a decision to fill the slot.
7. **Empty / dutiful alternatives** -- "no alternatives considered" is a smell. If there
   genuinely was no alternative, briefly justify *why* the option space was empty.
8. **Marketing prose / filler** -- sober, dense, one thought per sentence.

## Where the excluded content belongs

Removing a snapshot does not mean discarding information -- only filing it in the right
place:

- **Wiring state / "why does the code look like this"** -> doc comment on the affected type.
- **Open work** -> the project's issue tracker.
- **Project progress / "done in commit X"** -> git history, release notes, the project's own
  notes.
- **"Decision now applied to Y as well"** -> the issue or PR that did it. A decision that
  holds needs no proof of it in the ADR -- it holds.

When you remove a snapshot from a `Proposed` ADR, check whether it is recorded elsewhere;
if not, say so (do not delete silently). From an `Accepted` ADR you remove nothing -- there
you only name the destination.

## Template

Defaults for a project that has no ADRs yet. A project with an existing corpus overrides
the language, the section names and the file naming -- see "Adapt to the project".

```markdown
# ADR-NNN: <concise decision title>

- Status: <Proposed|Accepted|Rejected|Deprecated|Superseded> (YYYY-MM-DD)
- Related: ADR-XXX, ADR-YYY      # omit if none; one-sided, no counter-entry over there
- Supersedes: ADR-MMM            # only if this ADR replaces an older one

## Context

Why did this have to be decided? Forces and constraints. References to related ADRs and --
where applicable -- to the requirement addressed or the bounded context affected.

## Decision

The decision, precise and in the active voice. Number the parts if there are several.

## Consequences

**Positive:** durable benefits that follow from the decision.

**Negative / deliberately deferred (YAGNI):** durable costs and points left open on
purpose, *with reasons*. Not a worklist, not a snapshot.

## Alternatives

- **<Rejected option>.** One sentence on why it was rejected. `Rejected.` /
  `Rejected for now (revisitable).`
```

Template rules:
- **Filename:** `adr-NNN-<kebab-title>.md`, NNN three digits (`001`), consecutive. Before
  assigning a number: `ls docs/adr/` -- highest existing + 1.
- Only the four `##` sections above. Do not invent further headings -- in particular no
  `## Addendum`, `## Amendment`, `## Update`.

A full worked record is shipped next to this skill: **`reference/adr-sample.md`**. Read it
before writing your first ADR in a project that has none -- it shows what a real
consequences section and substantive alternatives look like.

## Immutability -- an `Accepted` ADR is never touched again

This is a hard rule, not a recommendation. With `Accepted`, the content freezes: Context,
Decision, Consequences and Alternatives are **never** edited afterwards -- not sharpened,
not amended, not "just clarified", not reworded. An ADR records what was decided back then
and why; smoothing it over after the fact falsifies the minutes.

**The only permitted change is the status line**, and only in these directions:

```
- Status: Superseded (2026-07-28), superseded by ADR-042
- Status: Deprecated (2026-07-28)
```

Why the status line stays mobile while everything else freezes: ADRs get referenced from
the code, typically from doc comments. Someone arriving in the file from there must see
that the decision is dead without consulting an index first. A dead decision that still
calls itself `Accepted` is more dangerous than any formatting violation.

What this means for you as a reviewer -- these repairs you may **not** propose and may not
apply to an `Accepted` ADR:

- "fold the addendum back into the decision sentence"
- "add consequence X, it has become clear since"
- "tighten the wording / drop the snapshot"

The fix in all three cases is the same: **a new ADR** superseding the old one. Name the
violation, say that the old record stays as it is, and offer the successor ADR.

Only at `Proposed` is the content freely editable -- nothing has been minuted yet. A
violation found in an `Accepted` ADR is still valuable: it belongs in the successor ADR,
not in a correction.

## Status lifecycle

- New decision, not finally settled -> `Proposed`. Date = today. **Name the condition for
  the transition explicitly** ("becomes Accepted once the licence is settled"). A `Proposed`
  without a transition condition is a smell.
- Settled -> `Accepted`. From here "Immutability" applies.
- Replaced by a new ADR: the **new** ADR states `Supersedes: ADR-MMM`; in the old ADR
  **only the status line** changes, to `Superseded (date), superseded by ADR-NNN`. No
  addendum, no note, no entry in `Related:`.
- `Rejected` = considered and rejected (stays as documentation).
- `Deprecated` = obsolete with no concrete successor.
- Never change a status silently backwards: a superseded ADR is not rewritten as though the
  old decision had never been made.

## Cross-ADR consistency

A single good ADR is not enough -- the corpus has to hold together. When writing a new one
and when reviewing an existing one, read the *other* ADRs (`ls docs/adr/`, then read).
Check:

1. **Contradictions in substance.** Does this ADR decide something that contradicts another
   `Accepted`/`Proposed` ADR? If so, do not leave both standing silently -- name the
   conflict. Either the new one supersedes the old, or one of the two is wrong.
2. **Superseding lives in the new ADR.** Does this ADR replace an older one? Then the
   **new** ADR says `Supersedes: ADR-MMM`; in the old one only the status line changes (see
   "Immutability"). That is the whole obligation -- no back-reference, no note in the old
   record.
3. **Superseded/deprecated ADRs no longer claim validity.** A replaced ADR stays as history
   but must not sound as though its decision were still in force -- the status line has to
   make that clear. It is also the only means available: the body stays untouched and keeps
   speaking in the present tense.
4. **References are one-sided.** A cross-reference is written exactly once, in the record
   that makes the claim. The *citing* ADR names the related one under `Related:`; the named
   ADR gets **no** counter-entry. A missing back-reference is not a finding.
   Why: the metamodel derives the reverse direction itself -- `arkarch:supersededBy` is
   `owl:inverseOf arkarch:supersedes`, and `arkarch:relatedTo` is an `owl:SymmetricProperty`.
   A hand-maintained back-reference would be redundant, and it would force exactly what
   "Immutability" forbids: editing a frozen record.
   What remains: references must point at **existing** numbers. Dangling numbers are still
   a finding.
5. **No duplication.** Two ADRs deciding the same thing are a smell -- merge them (only
   while both are `Proposed`) or mark the older one `Superseded`.

On finding a contradiction: report which two ADRs collide and in what, and propose a
resolution (supersede / correct / merge) -- do not guess.

## Mode: writing vs reviewing

**Writing a new ADR:**
1. Look at the corpus and match its conventions (see "Adapt to the project").
2. Determine the number (`ls docs/adr/`).
3. Has the decision actually been made? If not -> `Proposed`, name the openness in the
   context, do NOT invent it.
4. Fill the template, apply the litmus test to every sentence.
5. Link related ADRs -- **here only, one-sidedly**. The linked records stay untouched.
6. Check cross-ADR consistency (see the section above): does it contradict or supersede an
   existing ADR? If it supersedes, set **only the status line** of the old record to
   `Superseded (date), superseded by ADR-NNN` -- nothing else.

**Reviewing an existing ADR.** Step 0 is always the same: **read the status.** It decides
which repair is even on the table.

- `Proposed` -> content is freely editable. Fix findings directly.
- `Accepted` / `Superseded` / `Deprecated` / `Rejected` -> frozen. **Report findings, do not
  repair them**; the fix is a successor ADR. The only permitted change to the file is its
  status line. See "Immutability".

Checklist:
- [ ] Exactly the four sections, none invented (Open points / Implementation / Status /
      Addendum / Amendment)?
- [ ] No trace of a post-acceptance edit: no addendum, no "update", no issue or PR number in
      the text? (failure class: progress instead of decision)
- [ ] Does every sentence survive the litmus test (no snapshot, no commit ref)?
- [ ] Status + date set, exactly one status?
- [ ] At `Proposed`: is the condition for moving to `Accepted` named?
- [ ] At `Superseded`: does the status line name the superseding ADR?
- [ ] Does Consequences hold actual *consequences* (not a restatement of the decision)?
- [ ] Are the alternatives substantive (not "none considered")?
- [ ] Number unique, filename consistent with the corpus?
- [ ] Cross-references pointing at existing numbers -- and *one-sided*, i.e. without a
      hand-maintained back-reference in the other record?
- [ ] Cross-ADR consistency: no contradiction with other ADRs, superseding stated in the new
      record, no duplication (see "Cross-ADR consistency")?

On a violation: never rewrite silently -- name the violation (which failure class), then
branch on status. At `Proposed`: propose or apply the fix and say where the removed content
belongs. From `Accepted` on: say that the record stays as it is, and offer a successor ADR
-- even when the fix would be a one-liner. Especially then.
