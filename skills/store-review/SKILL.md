---
description: "Runs every review rule a project's store has in one pass and returns a single report: first the mechanical checks (adr_check, orphan_check, store_check, trace_matrix), whose findings are carried over as facts rather than re-derived, then the reader-level review of each resource type in the review mode of its specialist skill -- always as a table with one row per resource, where an empty cell means 'not checked' and never 'fine'. The reader level runs in one subagent per resource type, without the writing context of this session, so the reviewer is never the author of what it reviews. Writes nothing at all -- no resource, no status, no link; the report goes to the user as a file or an issue comment, and every consequence is the user's to draw. Trigger (also DE, since the user may phrase it in German): /arknet:store-review, 'review the whole store', 'full review of the model', 'review everything before we accept it', 'has this model actually been reviewed', 'run all the review rules'; DE: 'review den ganzen Store', 'vollstaendiger Review des Modells', 'pruefe das ganze Modell durch', 'Gesamtreview', 'ist das Modell wirklich reviewt'. NOT a status overview -- a vague 'is everything okay?' is /arknet:health-check, which reads the fact tools and routes here when a real review is what is wanted. NOT an elicitation -- this skill never interviews, never drafts text and never writes; /arknet:req-interview, /arknet:adr, /arknet:bc-audit and /arknet:context-map own every write. NOT the place for one named resource -- a question about a single ADR, requirement or context boundary goes straight to the matching specialist skill."
---

# /arknet:store-review -- One Full Review Pass over a Project's Store

The review rules of a store live on two levels, and only one of them runs on a
single call. The **mechanical** level sits in the tools (`adr_check`,
`orphan_check`, `store_check`, `trace_matrix`): one call each, result complete,
no judgement. The **reader** level sits in the specialist skills -- the rule
table of `/arknet:adr`, the full-set audit of `/arknet:req-interview`, the
language-break test of `/arknet:bc-audit`, the relationship reading of
`/arknet:context-map`. That level only ever runs when somebody invokes that one
skill, for that one resource type.

This skill is the pass that runs **both levels over the whole store in one go**
and returns one report. It exists because a review that has to be assembled from
four separate invocations is a review that is quietly skipped in parts, and a
prose verdict cannot be seen to be incomplete -- only a table can.

## Is this the right skill?

- **A vague status question** ("is everything okay?", "anything left to do?")
  is `/arknet:health-check`: it reads the fact tools, separates facts from
  hints, and routes -- including here, when the answer is that a real review is
  due. This skill is the heavier pass the routing points at, not a substitute
  for the triage.
- **One named resource** -- this ADR, that requirement, this context boundary
  -- goes to the specialist skill directly. Reviewing one record does not need
  a full pass over the store.
- **Anything that should change the store** belongs to the specialist skill
  too. This skill produces findings; it never resolves one.

## Which project

Every tool below reads the project the current working directory resolves to.
If the user wants the review run against a different project, pass its
registered anchor as `projectAnchor` on **every** call -- `project_list` shows
which anchors are registered for which project. Name in the report which
project was reviewed; a report that does not say what it looked at cannot be
checked later.

## The five rules

1. **The mechanical level runs first, and its findings are facts.** Call
   `adr_check`, `orphan_check`, `store_check` and `trace_matrix` before any
   reading. Carry their findings into the report as they came -- do not re-read
   the corpus looking for the same patterns, and do not restate a tool finding
   as your own observation. Where a tool names in its own output what it does
   *not* check, that boundary is part of the report too: it is exactly the part
   the reader level has to cover.
2. **The reader level runs per resource type, and always ends in a table.** One
   row per resource, one column per rule of that type's review mode. `ok` or a
   short finding per cell. **An empty cell means "not checked", never "fine"**
   -- a resource the pass did not reach still gets a row, marked as unchecked.
   This is the rule that makes an incomplete review visible as incomplete.
3. **The reviewer is never the author.** Each type's reader-level review runs
   in its own subagent, and that subagent gets the review rules and the
   resources -- never the reasoning, drafts or justifications from the session
   that wrote them. An agent that argued for a record's wording an hour ago
   will read that wording as settled; it finds nothing because it already
   agrees. One subagent per resource type, running in parallel.
4. **Findings stay in the report.** This skill calls no `_add`, `_update`,
   `_set_status`, `_link_*`, `_delete` or `_supersede` tool, for any resource
   type, ever -- not even to correct something a finding makes obvious. Ask the
   user where the report goes (a file, or a comment on an issue they name) and
   put it there; never post it anywhere on your own initiative. What follows
   from a finding is the user's call, made against the specialist skill.
5. **Report the gaps as gaps.** The reader-level review modes are unevenly
   developed. This skill covers what they carry and says plainly, in the
   coverage table of the report, which resource types it did not review and
   why. A type with no review mode is reported as unreviewed -- never quietly
   left out, and never given an improvised rule set invented for this run.

## The tools

| Tool | Level | Role |
|---|---|---|
| `project_list` | -- | Which projects and anchors exist -- only needed when the review targets a project other than the current directory's. |
| `adr_check` | Mechanical | The whole decision corpus, checked for what is mechanically decidable: `Facts` (a date on a decision not taken, no consequence or considered option recorded, nothing `CHOSEN` on a taken decision, a decision addressing no requirement and affecting no context, an `ADR-n` in the prose the project does not hold or no edge backs) and `Suspicions` (tracker references, address/port literals, status prose, near-identical titles). Names its own not-checked list in its output. |
| `orphan_check` | Mechanical | Requirements no use case realises; glossary terms never referenced; a term named in text without the backing edge; constraints nothing is bound by. |
| `store_check` | Mechanical | The stored model against what the project declares about itself -- today the maintained-language set and role/term name duplicates. |
| `trace_matrix` | Mechanical | Per requirement: which terms it uses, which use case(s) realise it. |
| `adr_list`, `adr_get` | Reader | The decision corpus for the ADR reviewer -- the list for the overview, `adr_get` for each record's full text. |
| `req_list`, `req_get`, `constraint_list`, `constraint_get`, `uc_list`, `uc_get`, `term_list`, `term_get` | Reader | Requirements, constraints, use cases and glossary terms, in full, for their reviewers. |
| `bc_list`, `bc_get` | Reader | Every Bounded Context, each with its recorded `ContextRelationship` edges shown inline by both calls. |
| `role_usecase_matrix`, `term_cooccurrence` | Reader | Raw bipartite/co-occurrence data, the material the Bounded Context reader works from. |
| `impact_analysis` | Reader | What a resource pulls with it -- used to weigh a finding, never to act on one. |

Read-only, all of them. No tool this skill calls changes anything.

## Protocol

### 1. Establish the scope

Resolve the project (see "Which project"). Then read the inventory -- `adr_list`,
`req_list`, `constraint_list`, `uc_list`, `term_list`, `bc_list`, `actor_list`,
`role_list` -- and write down the count per resource type. That inventory is what
the coverage table is checked against at the end: a type that has resources but
no reviewer produced a row is a gap in the report, not an absence of findings.

An empty store is not a finding. Say so plainly and point at
`/arknet:req-interview` as the place to start.

### 2. Run the mechanical level

`adr_check`, `orphan_check`, `store_check`, `trace_matrix`. Keep their output --
the reader-level subagents get the part that concerns their type, so that they
do not spend their pass re-finding what a tool already reported, and so that
their judgement lands on what the tool explicitly does not check.

### 3. Run the reader level, one subagent per resource type

Launch them in parallel, one per type. Each briefing carries exactly four
things, and nothing else -- five when the review targets a project other
than the current directory's:

- **The review rules of that type's specialist skill, quoted in full.** Quote
  them; do not summarise, and do not assume the subagent can load the skill
  itself. A summarised rule is a weaker rule, and the difference shows up as
  findings that were not made.
- **The resource inventory of that type** -- the codes, nothing more. The
  subagent reads each record itself, from the store, with the read tools above.
  Handing it your rendering of a record puts your reading between the reviewer
  and the text.
- **The mechanical findings for that type**, as facts already established, with
  the instruction not to re-derive them.
- **The output contract**: the table of rule 2, one row per resource, plus the
  corpus-wide findings that have no row of their own, plus anything it could
  not reach. Where a rule says its check has to be carried out **in writing**
  rather than by feel -- a text split into its separate assertions, a claim
  traced back to its source -- the briefing asks for that working alongside
  the cell. A cell reading `ok` with no working behind it is not evidence the
  rule ran, and a rule applied by feel reliably finds nothing.
- **The `projectAnchor`, only when one is in play.** A subagent resolves the
  project from its own working directory exactly like any other caller, so a
  review running against another project's anchor has to hand it over and
  require it on every read call. Left out, the reviewer reads a different
  store than the one the report names it read -- and the report still looks
  complete.

And explicitly **not**: why a record was written the way it was, what was
discussed when it was drafted, which findings you expect, or any prior review's
verdict. Rule 3 is only worth anything if the briefing actually withholds it.

Where a type's specialist skill has a review mode, that mode's rules are the
rules -- this skill does not invent its own. Where it has none (see the coverage
table), no reviewer is launched for that type and the report says so.

### 4. Assemble the report

In this order:

1. **Scope** -- which project, which resource types, how many resources each,
   when.
2. **Mechanical findings** -- per tool, as the tool reported them, `Facts` kept
   apart from `Suspicions` and from each tool's own not-checked list.
3. **One table per resource type** -- exactly as the subagent returned it. Do
   not merge tables across types (the rule columns differ), do not drop rows
   that read `ok` (the point is the completeness of the grid), and do not
   silently fill an empty cell.
4. **Corpus-wide findings** -- contradiction and duplication between records,
   plus anything a subagent reported outside its table.
5. **Coverage** -- the table below, filled in for this run: which types were
   reviewed, which were not, and what a reader would still have to do by hand.
6. **What follows** -- the findings ranked, each naming the specialist skill
   that would resolve it and what it would take. Proposals only; nothing here
   is done in this pass.

### 5. Hand it over

Ask where the report goes and put it there. Then stop -- do not continue into
the specialist skill's dialogue in the same turn unless the user asks for it,
and never act on a finding because it looks obvious.

## Coverage -- what this review reaches today

The reader-level review modes differ in maturity. This table belongs in every
report, filled in for the run it describes:

| Resource type | Reader-level review mode today | What the review does not reach |
|---|---|---|
| Architecture decision | The rule table of `/arknet:adr`, one row per record | -- the mode is a table already; it transfers unchanged |
| Requirement, Constraint, Use case, Glossary term | The full-set audit checklists of `/arknet:req-interview` | The checklists are written for a dialogue, not a grid: the reviewer renders one row per resource from them, and a question the checklist would put to the user becomes a finding in a cell instead of an answer |
| Bounded Context | `/arknet:bc-audit` finds *candidates* in the requirements/use-case/glossary set | It does not review a context already recorded -- there is no mode that puts the language-break test to an existing boundary, so a context that never was one is not found |
| Context relationship | `/arknet:context-map` elicits a relationship | No review mode: a recorded relationship type is not re-tested |
| Actor, Role | none | Not reviewed at all |

Report the right-hand column as an open gap of the review, not as a clean
result. Where the store holds resources of a type with no review mode, name the
count -- a reader deciding whether to trust the report needs to see what it did
not look at.

## Scope boundary

- **Never writes.** See rule 4. Every write belongs to the specialist skill the
  finding is routed to, on the user's decision.
- **Never interviews.** The relentless one-at-a-time questioning belongs to
  `/arknet:req-interview`, the candidate dialogue to `/arknet:bc-audit`, the
  pair-at-a-time elicitation to `/arknet:context-map`. This skill reads and
  reports.
- **Never invents a rule.** A resource type whose specialist skill has no review
  mode is reported as unreviewed. An improvised checklist would look like
  coverage and be worth less than the admitted gap.
- **Not a substitute for the triage.** `/arknet:health-check` stays the cheap
  read for a vague status question; this pass is the expensive one it routes to.
