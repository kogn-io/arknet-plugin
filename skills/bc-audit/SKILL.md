---
description: "Audits an already-filled arknet store (requirements, use cases, glossary) for emergent Bounded Context candidates -- never a greenfield 'which contexts does your system need' interview. Reads role_usecase_matrix/term_cooccurrence as raw data, tests each cluster for a language break (the same fact getting different rules on each side), presents only candidates that clear that test to the user with its own assessment first, and reports a clustering that traces only to responsibility/module split/data volume as an observation without a context proposal; then writes confirmed contexts via bc_add/bc_link_term. Carries a second, write-free review mode that puts the same language-break test to a boundary the store already holds, plus the store-decidable checks (does it carry terms, does any context relationship touch it, is its subdomain classification consistent with its domain vision) -- the mode /arknet:store-review invokes for this resource type. Trigger (also DE, since the user may phrase it in German): /arknet:bc-audit, 'find bounded context candidates', 'audit the bounded contexts', 'where should we split contexts', 'is this a real context boundary', 'review the recorded bounded contexts', 'is BC-n still a real boundary'; DE: 'pruefe auf Bounded Contexts', 'wo trennen sich die Kontexte', 'Bounded-Context-Kandidaten finden', 'review die eingetragenen Kontexte'. NOT for a project whose req/uc/term store is still empty (use /arknet:req-interview first to fill it). NOT for tactical design (Aggregate/Entity/ValueObject/DomainEvent) -- no tool surface yet. NOT for context-map relationship types (Partnership/Anti-Corruption-Layer/...) -- see /arknet:context-map for those."
---

# /arknet:bc-audit -- Bounded Context Candidates from the Existing Store

An **audit**, not an interview. Bounded Context boundaries are supposed to
emerge from language collisions already present in a filled requirements/
use-case/glossary store -- not be drawn on a blank whiteboard before the
domain vocabulary exists (anti-BDUF). This skill therefore never asks
"which Bounded Contexts does your system need" from nothing; it reads the
store that already exists and finds candidates in it.

Two modes, one test. **Candidate mode** (the default) looks for a boundary
the store implies but does not yet hold, and ends in a write. **Review
mode** takes a boundary the store already holds and puts the same
language-break test to it, and writes nothing. Which one applies follows
from the request: "where should we split", "find candidates" is the
former; "review the recorded contexts", "is BC-3 a real boundary", and any
call from `/arknet:store-review` is the latter. When the request does not
say, ask -- the two produce different output and only one of them touches
the store.

## Precondition: a filled store, not a blank slate

Run `term_list`, `req_list`, `uc_list` first. If the store is empty or
sparse, stop here and point the user at `/arknet:req-interview` instead --
there is no meaningful collision to find in an empty store, and drawing
context boundaries before any requirement/use-case/term exists is exactly
the greenfield BDUF this skill is designed not to do.

## The tools

| Tool | Role |
|---|---|
| `term_list`, `req_list`, `uc_list`, `bc_list` | Read the whole requirements/use-case/glossary set and every already-registered Bounded Context before anything else. Each takes `displayLocale?`; a line carrying an inline `[fallback: ...]` tag is an entry **missing** in that language, shown under another one. Call `uc_list` with `withSteps: true`: this skill never calls `uc_get`, so without it a use case contributes its title and goal and nothing else, while the vocabulary a naming collision surfaces in sits in the numbered steps and extensions -- the same text `term_cooccurrence` counts over. |
| `bc_get` | A single recorded context in full -- its `domainVision`, `subdomain`, the glossary terms linked to it, and every `ContextRelationship` edge in both directions. The material review mode works from. |
| `role_usecase_matrix` | Raw bipartite data: which use cases each role appears in (`primaryRole`/`supportingRole`), and vice versa, plus which actors occupy each role (`filledBy`). No clustering, no judgement -- that stays with you and the user. |
| `term_cooccurrence` | Raw data: which glossary terms are named together in the same requirement/use-case text, and which never co-occur -- the material for "is this one term or a homonym with two meanings per context?". |
| `bc_add(name, domainVision, subdomain?, ownedBy?, language?)` | Register a confirmed Bounded Context. `domainVision` must come out of the discussion with the user, never be invented to fill the field. `language` names the BCP-47 tag `name`/`domainVision` are written in, falling back to the project's configured default language if omitted. |
| `bc_update(id, name?, domainVision?, terms?, language?)` | Correct an already-registered context's name/domain vision, or restate either in a further language -- the correction path `bc_add` alone does not have. `terms` (list of `TERM-N` codes) replaces the context's ubiquitous-language term links wholesale: omitted leaves them untouched, an empty list clears them all, a non-empty list is the full set going forward. Use it to replace the whole set at once; to remove a single term without restating the rest, use `bc_unlink_term` instead. One call carries one language tag, same discipline as the write tools in `/arknet:req-interview`. |
| `bc_delete(id)` | Remove a context recorded by mistake -- a boundary that turned out not to be one: drawn before the language break was understood, or two that collapsed into one. The whole resource goes, not a field: `bc_update` corrects one that stays. Refused while anything still points at it -- a `ContextRelationship` via `upstream`/`downstream` (drop it with `bc_unlink_context`: a relationship is its own resource and is never deleted along with a context), a decision via `affectsContext`, a requirement via `scopedTo`, a domain via `hasContext`. The terms it links hold nothing: those are its own edges and go with it, the glossary terms themselves stay. The `BC-n` code stays taken. |
| `bc_link_term(bcId, termId)` | Link the new context to each glossary term the user confirmed belongs to it -- one call per term, still one code at a time (unlike the requirement/use-case term-link tools, this one has not moved to a list). Idempotent no-op if already linked. |
| `bc_unlink_term(bcId, termId)` | Remove one already-linked term from a context without restating the rest -- never a silent no-op, a term that is not currently linked is rejected. |
| `impact_analysis` | Ripple check on every term just linked. |

`role_usecase_matrix` and `term_cooccurrence` are raw-data read tools by
design (see `kogn-io/arknet#108`) -- they never propose a boundary
themselves, matching how `store_check`/`trace_matrix` already work in
`/arknet:req-interview`: facts in, judgement stays with the interviewing
agent and the user.

## Protocol

1. **Read the requirements, use cases, glossary and existing contexts.**
   `term_list`, `req_list`, `uc_list(withSteps: true)`, `bc_list`, in full --
   this is the baseline every candidate gets checked against. Read them
   under one language (`displayLocale`) and watch the inline
   `[fallback: ...]` tags: a tagged line is an entry the store does not
   hold in that language at all.
   A term you are about to weigh as a naming collision may just be the same
   concept surfacing under two languages, so resolve the tags before reading
   anything into the wording. A project maintaining more than one language
   needs its Bounded Contexts in each of them too, the same as its
   requirements and terms -- `store_check`'s `LANGUAGE` check reports any
   context still missing one.
2. **Find candidate collisions, then test each one for a language break.**
   Call `role_usecase_matrix` and `term_cooccurrence` and look for language
   that clusters or splits: a role whose use cases fall into two unrelated
   groups, a term that never co-occurs with another term used right next to
   it elsewhere, two terms that always appear together and might be the same
   concept named twice. These tools hand you structure, not a verdict -- the
   boundary judgement is yours to draw, then the user's to confirm.

   Every cluster or split found this way still needs one more test before it
   becomes a candidate: is there a single fact or concept that gets
   different rules on each side of the split -- the same word carrying two
   meanings, the same thing subject to different constraints depending on
   who is talking about it? That difference in rules for the same fact is
   the language break, and it is the evidence step 3 presents. A clustering
   that traces only to who is responsible for it, which module it lives in,
   or how much data passes through it -- with no fact that changes meaning
   or rule across the split -- is not a context candidate. Note it as an
   observation without a context proposal instead: still worth surfacing to
   the user, but explicitly labelled as such, never offered for
   confirmation as a Bounded Context in step 3.
3. **Present each candidate, one at a time.** Before presenting a
   candidate's name, run a short naming self-check:
   - Where does this name come from -- the collision just found in step 2,
     or old context/memory from an earlier session? If the latter,
     re-derive it from what step 2 actually shows instead of reusing it;
     a name that was only ever a discussion suggestion is not a finding.
   - Does the name fit the project's own architecture/domain premises,
     where documented (e.g. a project-local `CLAUDE.md`)? A name that
     contradicts a stated principle -- e.g. "this app only mediates, it
     owns no data" ruling out a "Verwaltung"/"management" name -- needs to
     be revised before it reaches the user.
   - If this run presents more than one candidate: do their names follow
     the same pattern/category, or is a deviation substantively
     justified? Inconsistent naming across candidates from the same run
     (e.g. one "-assistenz", one "-verwaltung" with no reason for the
     difference) is a signal to fix before presenting, not after.

   Then give your own assessment first, and open it with the language
   break the candidate rests on: name the fact or concept, and the
   different rules it gets on each side of the split ("X means/requires
   ... here, but .../... there, and that's why these use cases read as
   two contexts to me"). An assessment that cannot name that difference
   has not found a language break -- fall back to reporting it as an
   observation without a context proposal (see step 2) instead of
   presenting it as a candidate. Then ask the user directly: is this a
   deliberate boundary, or a coincidental clustering that doesn't
   warrant a context split? Same pacing discipline as
   `/arknet:req-interview`: one candidate, one question, wait for the
   answer.
4. **On confirmation, write it in.** `bc_add` with a `domainVision`
   phrased from what the user just said, not invented to satisfy the
   field's minimum length; `bc_add` writes only the language named by its
   `language` argument (or the project default) -- in a project maintaining
   more than one language, restate the context in each further language
   right after with `bc_update id language=...`, one call per language,
   before moving to the next candidate. Then `bc_link_term` for every
   glossary term the user placed inside this context.
5. **Ripple check.** `impact_analysis` on every term just linked to the
   new Bounded Context -- does the new boundary cut across a `usesTerm`/
   `realises` edge that used to be uncontroversial? Surface anything it
   finds as a decision for the user (see `/arknet:req-interview`'s ripple
   protocol for the same pattern), never resolve it silently.

## Review mode: a boundary the store already holds

Candidate mode asks whether a boundary *should* exist. Review mode asks
whether one that *does* exist still earns its keep -- and it is the mode
`/arknet:store-review` invokes. Same evidence standard, opposite direction:
there the language break has to be found before a context is written, here
it has to be re-found in a context already written, from the store alone.
A boundary whose language break nobody can name today is a finding, not a
settled fact -- it may have been named once, in a conversation that left no
trace in the store.

Read `bc_list` for the full set, then `bc_get` per context, plus
`term_list`, `req_list`, `uc_list(withSteps: true)` and `term_cooccurrence`
as the material the break is tested against -- the same reading candidate
mode does, on the same store.

Six rules. The review table has one row per recorded context and one column
per rule -- the table below defines the rules, it is not the output. The
first three are decidable from the store alone; the last three are the
reading, and B4 is the one the mode exists for.

| # | Rule | A finding reads |
|---|---|---|
| B1 | **Terms linked.** Does the context carry at least one `bc_link_term` edge? | No term edge -- the boundary is unbacked in the store: nothing says which language falls inside it. Whatever the break was, it is not recorded. |
| B2 | **Related in the map.** Does at least one `ContextRelationship` edge touch it, in either direction? | No edge at all. Say which of the two it is where the material lets you: a context that genuinely stands alone (whose `SEPARATE_WAYS` edge is then simply unrecorded -- an elicitation for `/arknet:context-map`, not something this mode writes) or a map incomplete here. Unrecorded is not the same as unrelated, and the store cannot tell them apart by itself. |
| B3 | **Subdomain classified.** Is `subdomain` set (`CORE_DOMAIN`, `SUPPORTING_DOMAIN`, `GENERIC_DOMAIN`), and does it match what `domainVision` claims? | Unset, or a `domainVision` describing off-the-shelf work filed as `CORE_DOMAIN` -- the classification drives build-vs-buy, so a wrong one is not cosmetic. Note in the cell that `bc_update` does not touch `subdomain`: it is fixed at creation, so this finding has no in-place correction and the user needs to know that before deciding. |
| B4 | **The language break, re-found.** Name the fact or concept that gets *different rules* inside this context than outside it, working from the terms linked to it and the requirements/use cases that use them. | No such fact can be named from the store -- the strongest finding this mode produces. Do not soften it into "unclear"; report which reading was attempted and what the store gave back. Where B1 already found no term edge, B4 has nothing to read: say that rather than leaving the cell to imply a reading happened. |
| B5 | **Not a responsibility or module split.** Does the boundary trace only to who owns it, which module it lives in, or how much data flows through it -- with no fact changing meaning or rule across it? | Yes, it does: the same exclusion candidate mode applies before proposing a context (step 2), applied here to one already recorded. A context caught by B5 necessarily has no B4 answer either -- fill both cells anyway, they are different evidence and a reader checking the grid needs to see both were asked. |
| B6 | **Domain vision, not a component description.** Does `domainVision` say what is true *inside* the boundary, or does it enumerate what the context contains and which parts talk to it? | A vision reading as a building-block list says nothing about language, and cannot be checked against B4. |

Two findings have no row of their own, because they only exist across the
set -- report them separately:

- **Terms in two contexts.** The same `TERM-n` linked to more than one
  context is the interesting case, not an error: either the word genuinely
  carries two meanings and each context should hold its *own* term, or the
  boundary between them is not where the store says it is.
- **A term in no context at all.** With contexts recorded, a term outside
  every one of them is either an oversight or evidence that the recorded
  set does not cover the domain. `store_check`'s `ORPHAN` check reports
  unreferenced terms; this is a different question and no tool asks it.

Review mode **writes nothing** -- no `bc_add`, no `bc_update`, no
`bc_link_term`. A confirmed finding is a candidate-mode conversation or a
`/arknet:context-map` call afterwards, on the user's decision. When the mode
was invoked directly by the user rather than by `/arknet:store-review`,
offer that next step once; do not take it in the same turn.

## Scope boundary

- **No tactical design.** Aggregate, Entity, Value Object, Domain Event --
  none of it belongs here, and none of it has a tool surface yet. That is
  a later, separate skill once a Bounded Context/tool surface exists for
  it.
- **No context-map relationship types.** Partnership, Anti-Corruption
  Layer, Shared Kernel, and the rest of the classic context-map vocabulary
  are not modelled by `bc_link_term`, which only carries the
  context-to-term edge. Do not invent a relationship type in prose to fill
  the gap -- if the user wants a BC-to-BC relationship recorded, point them
  at `/arknet:context-map` instead of approximating it here.
