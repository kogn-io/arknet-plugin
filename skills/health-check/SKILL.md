---
description: "Read-only triage layer for vague overall-status questions ('is everything okay?', 'is the model consistent?', 'anything left to do?') that match no specific skill by name. Bundles orphan_check/trace_matrix (structural facts), open PROPOSED ADRs (adr_list), and Bounded Contexts with no recorded context-map relationship (bc_list vs bc_link_context edges) into one report, clearly split into hard facts vs. judgement candidates, then points at the matching specialist skill (/arknet:req-interview full-set-audit mode, /arknet:bc-audit, /arknet:context-map, /arknet:adr) instead of duplicating its dialogue. Trigger (also DE, since the user may phrase it in German): /arknet:health-check, 'is everything okay', 'is the model/store consistent', 'anything left to do', 'give me a status overview', 'what's the state of the architecture model'; DE: 'ist alles in Ordnung', 'ist das Modell konsistent', 'gibt es noch was zu tun', 'wie ist der Stand', 'Statusuebersicht'. NOT a replacement for the interactive audits themselves (/arknet:bc-audit, /arknet:context-map, /arknet:req-interview full-set-audit mode) -- overview and routing only, this skill never writes and never runs an interrogation dialogue. NOT for a request that already names a specific concern (a BC boundary, a context relationship, one requirement) -- go straight to the matching skill instead."
---

# /arknet:health-check -- Read-Only Status Overview and Routing

A **triage layer**, not an audit. When the user's question is vague enough that
it does not name which specific concern they mean -- consistency of the whole
store, an open architecture decision, a missing Bounded Context boundary --
this skill reads the existing fact-tools, reports what they show, and routes
the user to the specialist skill that actually resolves each finding. It never
writes to the store and never runs an interrogation dialogue itself; the
dialogue belongs to the skill it routes to.

## Is this the right skill?

If the user's question already names a specific concern -- a Bounded Context
boundary, a context-map relationship, one requirement/use case/term, an ADR --
go straight to the matching skill (`/arknet:bc-audit`, `/arknet:context-map`,
`/arknet:req-interview`, `/arknet:adr`) instead. This skill exists only for the
case where the question is too vague to name one.

## The tools

| Tool | Role | Category |
|---|---|---|
| `orphan_check` | Requirements no use case realises; glossary terms never referenced; terms named in text without a backing edge. | Hard fact |
| `trace_matrix` | Per requirement: which terms it uses, which use case(s) realise it. | Hard fact |
| `adr_list` | Every recorded decision with its status; filter the result to `PROPOSED` yourself -- the tool has no status parameter. | Hard fact |
| `bc_list` | Every registered Bounded Context -- the pool to check for missing relationships. | Judgement candidate |
| `resource_get` | Per Bounded Context from `bc_list`, read its recorded `ContextRelationship` edges (see `/arknet:context-map`). | Judgement candidate |

No new MCP tools -- all five already exist and are used the same way their
owning skills (`/arknet:req-interview`, `/arknet:adr`, `/arknet:context-map`)
already use them.

## Protocol

1. **Hard structural facts, no interpretation needed.**
   - `orphan_check` -- report the three lists as-is (orphaned requirements,
     unreferenced terms, unbacked term references).
   - `trace_matrix` -- report any requirement with no realising use case; a
     requirement `orphan_check` already flagged does not need repeating here,
     but a requirement `trace_matrix` shows with an empty `realises` list and
     `orphan_check` missed (e.g. because a use case references it in prose
     without the `realises` edge) is a separate, additional finding.
   - `adr_list` -- filter to `PROPOSED` and report each one: still waiting on
     an accept/reject decision.
2. **Judgement candidates, hint only.** `bc_list` for every registered
   context, then `resource_get` on each to check its recorded
   `ContextRelationship` edges. A context with zero edges is a **hint**, not a
   defect -- some contexts are legitimately unrelated to any other. Report it
   as "no relationship recorded for X yet -- worth a look with
   `/arknet:context-map`?", never as a finding on par with an orphaned
   requirement.
3. **Report, hard facts and hints visibly separated.** Two headed sections,
   never merged into one list:
   - **Harte Befunde** -- everything from step 1. These are facts; state them
     plainly.
   - **Hinweise** -- the step-2 candidates. These need a human judgement call;
     phrase them as questions, not conclusions.
4. **Route, don't resolve.** For each finding, name which specialist skill
   would resolve it -- `/arknet:req-interview` (full-set-audit mode) for
   orphaned/untraced requirements or terms, `/arknet:adr` for open `PROPOSED`
   decisions, `/arknet:context-map` for a Bounded Context with no recorded
   relationship. Offer to hand off; do not start that skill's dialogue
   yourself in the same turn unless the user explicitly asks you to continue
   straight into it.
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
- **No staleness heuristic against `actor_usecase_matrix`/`term_cooccurrence`.**
  Deliberately out of scope for now: neither tool carries a timestamp, and a
  "since the last `/arknet:bc-audit` run" signal would need one. Inventing a
  store-size threshold instead would fake a precision the data cannot
  back up. A later iteration may add this once a real signal exists; until
  then, `/arknet:bc-audit` stays something the user is routed to on request,
  not something this skill infers is due.
- **No automatic/proactive trigger.** This skill runs when a vague status
  question matches it, same as any other skill -- it does not run itself
  after every write tool call. A trigger like that would be a Claude Code
  hook, outside the skill mechanism.
