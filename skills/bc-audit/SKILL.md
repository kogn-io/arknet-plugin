---
description: "Audits an already-filled arknet store (requirements, use cases, glossary) for emergent Bounded Context candidates -- never a greenfield 'which contexts does your system need' interview. Reads actor_usecase_matrix/term_cooccurrence as raw data, presents each candidate collision to the user with its own assessment first, then writes confirmed contexts via bc_add/bc_link_term. Trigger (also DE, since the user may phrase it in German): /arknet:bc-audit, 'find bounded context candidates', 'audit the bounded contexts', 'where should we split contexts', 'is this a real context boundary'; DE: 'pruefe auf Bounded Contexts', 'wo trennen sich die Kontexte', 'Bounded-Context-Kandidaten finden'. NOT for a project whose req/uc/term store is still empty (use /arknet:req-interview first to fill it). NOT for tactical design (Aggregate/Entity/ValueObject/DomainEvent) -- no tool surface yet. NOT for context-map relationship types (Partnership/Anti-Corruption-Layer/...) -- see /arknet:context-map for those."
---

# /arknet:bc-audit -- Bounded Context Candidates from the Existing Store

An **audit**, not an interview. Bounded Context boundaries are supposed to
emerge from language collisions already present in a filled requirements/
use-case/glossary store -- not be drawn on a blank whiteboard before the
domain vocabulary exists (anti-BDUF). This skill therefore never asks
"which Bounded Contexts does your system need" from nothing; it reads the
store that already exists and finds candidates in it.

## Precondition: a filled store, not a blank slate

Run `term_list`, `req_list`, `uc_list` first. If the store is empty or
sparse, stop here and point the user at `/arknet:req-interview` instead --
there is no meaningful collision to find in an empty store, and drawing
context boundaries before any requirement/use-case/term exists is exactly
the greenfield BDUF this skill is designed not to do.

## The tools

| Tool | Role |
|---|---|
| `term_list`, `req_list`, `uc_list` | Read the whole requirements/use-case/glossary set before anything else. |
| `actor_usecase_matrix` | Raw bipartite data: which use cases each actor appears in (`primaryActor`/`supportingActor`), and vice versa. No clustering, no judgement -- that stays with you and the user. |
| `term_cooccurrence` | Raw data: which glossary terms are named together in the same requirement/use-case text, and which never co-occur -- the material for "is this one term or a homonym with two meanings per context?". |
| `bc_add(name, domainVision, subdomain?, ownedBy?)` | Register a confirmed Bounded Context. `domainVision` must come out of the discussion with the user, never be invented to fill the field. |
| `bc_link_term` | Link the new context to each glossary term the user confirmed belongs to it. |
| `impact_analysis` | Ripple check on every term just linked. |

`actor_usecase_matrix` and `term_cooccurrence` are raw-data read tools by
design (see `kogn-io/arknet#108`) -- they never propose a boundary
themselves, matching how `orphan_check`/`trace_matrix` already work in
`/arknet:req-interview`: facts in, judgement stays with the interviewing
agent and the user.

## Protocol

1. **Read the requirements, use cases and glossary.** `term_list`,
   `req_list`, `uc_list`, in full -- this is the baseline every candidate
   gets checked against.
2. **Find candidate collisions.** Call `actor_usecase_matrix` and
   `term_cooccurrence` and look for language that clusters or splits: an
   actor whose use cases fall into two unrelated groups, a term that never
   co-occurs with another term used right next to it elsewhere, two terms
   that always appear together and might be the same concept named twice.
   These tools hand you structure, not a verdict -- the boundary judgement
   is yours to draw, then the user's to confirm.
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

   Then give your own assessment first ("these use cases split along
   actor X, which reads as two contexts to me because ..."), and ask the
   user directly: is this a deliberate boundary, or a coincidental
   clustering that doesn't warrant a context split? Same pacing
   discipline as `/arknet:req-interview`: one candidate, one question,
   wait for the answer.
4. **On confirmation, write it in.** `bc_add` with a `domainVision`
   phrased from what the user just said, not invented to satisfy the
   field's minimum length. Then `bc_link_term` for every glossary term the
   user placed inside this context.
5. **Ripple check.** `impact_analysis` on every term just linked to the
   new Bounded Context -- does the new boundary cut across a `usesTerm`/
   `realises` edge that used to be uncontroversial? Surface anything it
   finds as a decision for the user (see `/arknet:req-interview`'s ripple
   protocol for the same pattern), never resolve it silently.

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
