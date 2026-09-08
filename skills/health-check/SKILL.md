---
description: "Read-only triage layer for vague overall-status questions ('is everything okay?', 'is the model consistent?', 'anything left to do?') that match no specific skill by name. Bundles orphan_check/trace_matrix (structural facts), open PROPOSED ADRs (adr_list) and mechanical ADR corpus findings (adr_check), and Bounded Contexts with no recorded context-map relationship (bc_list vs bc_link_context edges) into one report, clearly split into hard facts vs. judgement candidates, then routes on to /arknet:store-review -- the one pass that runs every resource type's reader-level rules over the whole store -- instead of duplicating any review or dialogue itself. Trigger (also DE, since the user may phrase it in German): /arknet:health-check, 'is everything okay', 'is the model/store consistent', 'anything left to do', 'give me a status overview', 'what's the state of the architecture model'; DE: 'ist alles in Ordnung', 'ist das Modell konsistent', 'gibt es noch was zu tun', 'wie ist der Stand', 'Statusuebersicht'. NOT the review itself (/arknet:store-review) and not a replacement for the interactive audits (/arknet:bc-audit, /arknet:context-map, /arknet:req-interview full-set-audit mode) -- overview and routing only, this skill never writes, never runs an interrogation dialogue and never applies a reader-level rule table. NOT for a request that already names a specific concern (a BC boundary, a context relationship, one requirement) -- go straight to the matching skill instead."
---

# /arknet:health-check -- Read-Only Status Overview and Routing

A **triage layer**, not an audit. When the user's question is vague enough that
it does not name which specific concern they mean -- consistency of the whole
store, an open architecture decision, a missing Bounded Context boundary --
this skill reads the existing fact-tools, reports what they show, and routes
the user on to `/arknet:store-review`, the pass that actually reviews what the
findings point at. It never writes to the store, never runs an interrogation
dialogue and never applies a reader-level rule table itself; all three belong
to the skills it routes to.

## Is this the right skill?

If the user's question already names a specific concern -- a Bounded Context
boundary, a context-map relationship, one requirement/use case/term, an ADR --
go straight to the matching skill (`/arknet:bc-audit`, `/arknet:context-map`,
`/arknet:req-interview`, `/arknet:adr`) instead. This skill exists only for the
case where the question is too vague to name one.

If the user asks for a **review** rather than a status -- the whole store gone
through against every rule it has, before a set of records is accepted or a
release is cut -- that is `/arknet:store-review`, the pass that runs the
mechanical checks and each type's reader-level rules in one go and returns a
table per resource type. This skill is the cheap read; that one is the
expensive pass, and the routing below hands over to it rather than
approximating it here.

## The tools

| Tool | Role | Category |
|---|---|---|
| `orphan_check` | Requirements no use case realises; glossary terms never referenced; constraints no requirement or use case is bound by. Report these three lists as-is. Its fourth list -- terms named in text without a backing edge (including a use case's prose fields, not just its `goal`, and an ADR's context, decision, consequences, and options) -- matches on word boundaries without stemming, so it also surfaces an everyday word used in its ordinary sense (e.g. a common noun that happens to coincide with a glossary term) alongside real gaps; read it as a candidate list for a human, not a finding on par with the other three. | Hard fact (mentions list: hint) |
| `trace_matrix` | Per requirement: which terms it uses, which use case(s) realise it. | Hard fact |
| `adr_list` | Every recorded decision with its status; filter the result to `PROPOSED` yourself -- the tool has no status parameter. | Hard fact |
| `adr_check` | Every recorded decision, checked for what is mechanically decidable and reported as `Facts`/`Suspicions` plus a not-checked list -- reads only, changes nothing. Report the `Facts` block as-is; a `Suspicion` or a not-checked entry is a candidate for `/arknet:adr`, not a finding on par with a `Fact` -- do not phrase either as a defect, and never propose a status change from either block. | Hard fact |
| `bc_list` | Every registered Bounded Context, with its recorded `ContextRelationship` edges (see `/arknet:context-map`) shown inline -- the pool to check for missing relationships. | Judgement candidate |

No new MCP tools -- all five already exist and are used the same way their
owning skills (`/arknet:req-interview`, `/arknet:adr`, `/arknet:context-map`)
already use them.

## Protocol

1. **Hard structural facts, no interpretation needed.**
   - `orphan_check` -- report the orphaned-requirements, unreferenced-terms,
     and unbound-constraints lists as-is. Its fourth list -- terms named in
     text without a backing edge -- is not a hard fact; it matches on word
     boundaries without stemming and routinely names an everyday word used in
     its ordinary sense alongside a real gap, so it moves to step 2 instead of
     being listed here.
   - `trace_matrix` -- report any requirement with no realising use case; a
     requirement `orphan_check` already flagged does not need repeating here,
     but a requirement `trace_matrix` shows with an empty `realises` list and
     `orphan_check` missed (e.g. because a use case references it in prose
     without the `realises` edge) is a separate, additional finding.
   - `adr_list` -- filter to `PROPOSED` and report each one: still waiting on
     an accept/reject decision. **"Waiting" is not "waiting to be accepted."**
     `/arknet:adr` weighs a record against R0 -- worth recording at all --
     before it weighs its status, and deleting a record that should never
     have been an ADR is a legitimate outcome -- while it is still
     `PROPOSED`, and equally for an `ACCEPTED` record no other decision
     points at. Report the record as open; do not phrase it as a pending
     accept, and do not suggest one.
   - `adr_check` -- report the `Facts` block as-is, each a hard fact the same
     way `orphan_check`/`trace_matrix` findings are. Its `Suspicions` and
     not-checked list are not hard facts -- route them to `/arknet:adr` as a
     hint in step 2 instead of listing them here, and never propose a status
     change from either block.
2. **Judgement candidates, hint only.** `bc_list` for every registered
   context, checking each one's `ContextRelationship` edges as shown inline
   by that same call. A context with zero edges is a **hint**, not a
   defect -- some contexts are legitimately unrelated to any other. Report it
   as "no relationship recorded for X yet -- worth a look with
   `/arknet:context-map`?", never as a finding on par with an orphaned
   requirement. Likewise, `adr_check`'s `Suspicions` and its not-checked list
   are hints, one per entry -- "worth a look with `/arknet:adr`?", never a
   finding on par with a `Fact`. And `orphan_check`'s fourth list -- terms
   named in text without a backing edge -- is a hint, one per entry: the
   word-boundary match is deliberately left unsharpened, because a wrong edge
   costs more than a missed one, so one false-positive class recurs in
   particular -- an everyday word used in its ordinary sense that happens to
   coincide with a glossary term. Phrase each entry as "worth a look with
   `/arknet:req-interview`?", never as a finding on par with an orphaned
   requirement or an unreferenced term.
3. **Report, hard facts and hints visibly separated.** Two headed sections,
   never merged into one list:
   - **Harte Befunde** -- everything from step 1. These are facts; state them
     plainly.
   - **Hinweise** -- the step-2 candidates. These need a human judgement call;
     phrase them as questions, not conclusions.
4. **Route, don't resolve -- to one skill, not four.** Every finding this
   skill produces is a candidate for the same next step: `/arknet:store-review`,
   which runs the reader-level rules of each resource type over the whole store
   and reports one table per type. Name it once for the set, rather than
   sending the user to a different specialist skill per finding -- picking the
   right one per finding is the work this skill exists to spare them, and a
   review assembled from four separate invocations is the one that ends up
   partly skipped. Two cases still go straight to a specialist skill instead:
   the user names one concrete resource they want dealt with now -- an
   `orphan_check` unbacked-mention hint the user reads as a genuinely missing
   edge is the common one, and `/arknet:req-interview` records it -- or they
   ask to write something, in which case `/arknet:req-interview`,
   `/arknet:adr`, `/arknet:bc-audit` and `/arknet:context-map` own that write.
   Either way, offer the hand-off; do not start the other skill in the same
   turn unless the user asks you to continue straight into it.
5. **Empty store.** If `orphan_check`/`trace_matrix` return nothing and
   `bc_list` is empty, say so plainly and point at `/arknet:req-interview`
   (greenfield or brownfield entry point) as the place to start -- an empty
   store is not itself a finding, just a starting point.

## Scope boundary

- **Never writes.** No `_add`/`_update`/`_set_status`/`_link_*` call anywhere
  in this skill. Every write belongs to the specialist skill this one routes
  to.
- **Never interrogates.** No relentless one-at-a-time questioning, no
  candidate-naming self-check -- those disciplines belong to
  `/arknet:req-interview`, `/arknet:bc-audit`, and `/arknet:context-map`
  respectively; this skill only reports what their underlying fact-tools
  already show.
- **No staleness heuristic against `role_usecase_matrix`/`term_cooccurrence`.**
  Deliberately out of scope for now: neither tool carries a timestamp, and a
  "since the last `/arknet:bc-audit` run" signal would need one. Inventing a
  store-size threshold instead would fake a precision the store cannot
  back up. A later iteration may add this once a real signal exists; until
  then, `/arknet:bc-audit` stays something the user is routed to on request,
  not something this skill infers is due.
- **No automatic/proactive trigger.** This skill runs when a vague status
  question matches it, same as any other skill -- it does not run itself
  after every write tool call. A trigger like that would be a Claude Code
  hook, outside the skill mechanism.
