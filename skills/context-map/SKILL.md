---
description: "Elicits DDD context-map relationships (Partnership, Shared Kernel, Customer-Supplier, Conformist, Anti-Corruption Layer, Open Host Service, Published Language, Separate Ways) between two already-existing Bounded Contexts, and records confirmed ones via bc_link_context. Presents the relationship-type vocabulary and any already-recorded relationship as facts; the classification judgement stays with the user, same discipline as /arknet:bc-audit. Carries a second, write-free review mode that puts the elicitation's own question back to each recorded edge -- is the type re-derivable from the two contexts' material, does the direction match an asymmetric type, does anything carry the obligation the type implies -- plus the map-wide reading of how many distinct types are actually in use; the mode /arknet:store-review invokes for this resource type. Trigger (also DE, since the user may phrase it in German): /arknet:context-map, 'map the bounded contexts', 'what's the relationship between these contexts', 'is this a shared kernel or a customer-supplier', 'record a context relationship', 'review the context map', 'is that really a shared kernel'; DE: 'erstelle die Context Map', 'welche Beziehung besteht zwischen diesen Kontexten', 'Context-Map-Beziehung erfassen', 'review die Context Map'. NOT a greenfield 'which Bounded Contexts does your system need' interview -- requires at least two Bounded Contexts to already exist (bc_list); use /arknet:bc-audit first if the store holds fewer than two. NOT tactical design (Aggregate/Entity/ValueObject/DomainEvent) -- no tool surface for that yet."
---

# /arknet:context-map -- Bounded-Context Relationships

An **elicitation against an existing pair of contexts**, not a boundary-drawing
exercise. `/arknet:bc-audit` decides *where* the boundaries are; this skill
decides *how two already-drawn boundaries relate* -- upstream/downstream,
shared model, or no relationship at all. It never invents a Bounded Context
to fill a gap in the map; it only records relationships between contexts the
user already confirmed via `bc_add`.

Two modes. **Elicitation mode** (the default) works out the type for a pair
that has none recorded, and ends in a `bc_link_context` call. **Review
mode** takes the edges the store already holds and puts the elicitation's
own question back to each recorded answer, and writes nothing. "Map these
two contexts", "what's the relationship" is the former; "review the context
map", "is that really a Shared Kernel", and any call from
`/arknet:store-review` is the latter.

## Precondition: at least two existing Bounded Contexts

Run `bc_list` first. Fewer than two contexts means there is nothing to map
yet -- stop and point the user at `/arknet:bc-audit` (or plain `bc_add`, if
the second context is already agreed on and just needs registering) instead
of inventing a context to complete a pair.

## The tools

| Tool | Role |
|---|---|
| `bc_list` | Read every registered Bounded Context first -- the pool of pairs this skill can map. Every context's `ContextRelationship` edges, in both directions, are shown inline. |
| `bc_get` | Read a single Bounded Context's existing statements, including every `ContextRelationship` edge already recorded for it (both directions), before proposing a new one. |
| `bc_link_context(upstreamBcId, downstreamBcId, relationshipType)` | Record a confirmed relationship. Pure CRUD -- it never judges which type applies. Idempotent over the exact (upstream, downstream, relationshipType) triple: calling it again with the same three values returns the relationship already recorded rather than creating a second one; two different types between the same pair remain two distinct relationships. |
| `bc_unlink_context(upstreamBcId, downstreamBcId, relationshipType)` | Remove a previously recorded relationship, addressed by the exact triple `bc_link_context` took to create it. Rejects a triple that is not currently recorded rather than silently doing nothing. |
| `impact_analysis` | Optional context on either Bounded Context before or after linking -- what already references it -- but this tool does not itself propagate through the relationship edge just created; treat any ripple reasoning about the relationship as yours, not the tool's. |

The eight `relationshipType` values `bc_link_context` accepts: `PARTNERSHIP`,
`SHARED_KERNEL`, `CUSTOMER_SUPPLIER`, `CONFORMIST`, `ANTICORRUPTION_LAYER`,
`OPEN_HOST_SERVICE`, `PUBLISHED_LANGUAGE`, `SEPARATE_WAYS` -- the classic
context-map vocabulary (Evans/Vernon). Presenting this list, and any
relationship `bc_get`/`bc_list` already shows for the pair, is as far as the
tools go; which value fits is a judgement call for the user, not something
either tool infers.

## Protocol

1. **Read the map.** `bc_list` for the full set of contexts. If the user
   named two contexts already, confirm both exist and pull their ids; if
   they named only a domain area, ask which two contexts they mean rather
   than guessing from a name fragment.
2. **Check what's already recorded.** `bc_get` (or the inline edges already
   shown by `bc_list`) on both contexts before proposing anything new. If a
   relationship already exists between this exact pair, surface it and ask
   whether the user wants to record an *additional* edge (rare -- e.g. two
   contexts holding both a Shared Kernel and a separate Open Host Service
   for a different concern) or whether this is actually a correction to the
   existing one -- a correction is `bc_unlink_context` on the wrong triple
   followed by `bc_link_context` on the right one.
3. **Elicit the relationship, one pair at a time.** Give your own read
   first, grounded in what the two contexts' `domainVision` and glossary
   terms actually say (never invented) -- e.g. "X calls Y's API and adapts
   its own model to whatever Y returns, which reads as Conformist to me
   because X has no leverage over Y's model" -- then ask the user to
   confirm, correct, or reject. One pair, one question, wait for the
   answer -- same pacing discipline as `/arknet:req-interview` and
   `/arknet:bc-audit`.
4. **Resolve direction, but only where the type has one.**
   `CUSTOMER_SUPPLIER`, `CONFORMIST`, `ANTICORRUPTION_LAYER`,
   `OPEN_HOST_SERVICE`, and `PUBLISHED_LANGUAGE` are asymmetric --
   `upstreamBcId` is the context whose model prevails, `downstreamBcId`
   the one that adapts to it -- so confirm which side is which before
   calling the tool. `PARTNERSHIP`, `SHARED_KERNEL`, and `SEPARATE_WAYS`
   are symmetric in DDD terms; the tool still requires an
   `upstreamBcId`/`downstreamBcId` pair for these, so say so plainly to
   the user ("the tool needs an order for bookkeeping, but neither side
   leads here") rather than implying a real asymmetry that isn't there.
5. **On confirmation, write it in.** `bc_link_context` with the confirmed
   type and direction. Report back the resulting edge in plain language
   (e.g. "recorded: OrderManagement is upstream of Billing via Open Host
   Service"), not the raw tool call.

## Review mode: the edges the store already holds

Elicitation asks which type fits. Review asks whether the type recorded
*does* fit -- the same question, put to an answer already given. The
evidence is the same material elicitation works from and nothing else: the
two contexts' `domainVision`, their linked glossary terms, and the
requirements and use cases that cross the pair. A type that cannot be
re-derived from that material is a finding, whatever conversation produced
it originally.

Read `bc_list` for every context with its edges shown inline, then `bc_get`
on each context in a pair whose edge you are testing, plus `term_list`,
`req_list` and `uc_list` as the material.

Four rules. The review table has one row per recorded relationship -- not
per context pair: two edges between the same pair are two rows -- and one
column per rule. The table below defines the rules, it is not the output.

| # | Rule | A finding reads |
|---|---|---|
| C1 | **The type is re-derivable.** Can you name, from the two contexts' domain visions and terms, what makes *this* type fit rather than a neighbouring one? Say which neighbour you ruled out and why. | The type cannot be grounded in the material -- report which type the material *does* suggest, as an observation, not as a correction to apply. A cell reading `ok` with no ruled-out neighbour behind it is not evidence the rule ran. |
| C2 | **Direction matches the type.** For the five asymmetric types (`CUSTOMER_SUPPLIER`, `CONFORMIST`, `ANTICORRUPTION_LAYER`, `OPEN_HOST_SERVICE`, `PUBLISHED_LANGUAGE`): is `upstreamBcId` genuinely the context whose model prevails? | Direction reversed -- the map then reads the power relationship backwards, which is the one thing a context map exists to show. For the three symmetric types the cell states that the order is bookkeeping and stops there; a reversal is not a finding for them. |
| C3 | **The type carries its own obligation.** Each type implies work: `ANTICORRUPTION_LAYER` an actual translation layer, `SHARED_KERNEL` a jointly-owned model and the coordination it takes, `PUBLISHED_LANGUAGE` a published, documented model the downstream reads. Does anything in the store carry that obligation? | The type is recorded but nothing in the store backs what it commits the project to -- an aspiration filed as a fact. |
| C4 | **Not a restatement of "they talk to each other".** Does the recorded type distinguish this pair from any other pair, or would it fit every pair equally? | A type chosen because two contexts exchange data at all, rather than because of how their models relate. Usually shows up with the corpus-wide finding below. |

Two findings only exist across the whole map -- report them separately,
outside the table:

- **Type uniformity.** Count the distinct `relationshipType` values in use.
  Every edge carrying the same type is the map's characteristic failure: a
  map that says the same thing everywhere distinguishes nothing, and the
  type was most likely picked once and repeated. Report the count as the
  fact it is (`13 edges, 1 distinct type`), then the reading. A small store
  where two edges share a type is not that finding -- do not inflate it.
- **Justification uniformity.** Where the same reasoning was given for
  every edge, the reasoning was not made per pair. This is visible even
  where the types differ.

An unrelated context -- one no edge touches at all -- is
`/arknet:bc-audit`'s B2, not a row here: this mode reviews edges that
exist, and B2 covers the ones that do not.

Review mode **writes nothing** -- no `bc_link_context`, no
`bc_unlink_context`, not even to reverse a direction C2 shows is backwards.
Correcting an edge is elicitation mode's unlink-then-link, on the user's
decision, in a later turn.

## Scope boundary

- **No tactical design.** Aggregate, Entity, Value Object, Domain Event --
  none of it belongs here, and none of it has a tool surface yet.
- **No boundary-drawing.** If the user wants to discuss whether two
  contexts should exist at all, or where a boundary should sit, that is
  `/arknet:bc-audit`'s job -- this skill only maps relationships between
  contexts that already exist.
