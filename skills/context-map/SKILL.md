---
description: "Elicits DDD context-map relationships (Partnership, Shared Kernel, Customer-Supplier, Conformist, Anti-Corruption Layer, Open Host Service, Published Language, Separate Ways) between two already-existing Bounded Contexts, and records confirmed ones via bc_link_context. Presents the relationship-type vocabulary and any already-recorded relationship as facts; the classification judgement stays with the user, same discipline as /arknet:bc-audit. Trigger (also DE, since the user may phrase it in German): /arknet:context-map, 'map the bounded contexts', 'what's the relationship between these contexts', 'is this a shared kernel or a customer-supplier', 'record a context relationship'; DE: 'erstelle die Context Map', 'welche Beziehung besteht zwischen diesen Kontexten', 'Context-Map-Beziehung erfassen'. NOT a greenfield 'which Bounded Contexts does your system need' interview -- requires at least two Bounded Contexts to already exist (bc_list); use /arknet:bc-audit first if the store holds fewer than two. NOT tactical design (Aggregate/Entity/ValueObject/DomainEvent) -- no tool surface for that yet."
---

# /arknet:context-map -- Bounded-Context Relationships

An **elicitation against an existing pair of contexts**, not a boundary-drawing
exercise. `/arknet:bc-audit` decides *where* the boundaries are; this skill
decides *how two already-drawn boundaries relate* -- upstream/downstream,
shared model, or no relationship at all. It never invents a Bounded Context
to fill a gap in the map; it only records relationships between contexts the
user already confirmed via `bc_add`.

## Precondition: at least two existing Bounded Contexts

Run `bc_list` first. Fewer than two contexts means there is nothing to map
yet -- stop and point the user at `/arknet:bc-audit` (or plain `bc_add`, if
the second context is already agreed on and just needs registering) instead
of inventing a context to complete a pair.

## The tools

| Tool | Role |
|---|---|
| `bc_list` | Read every registered Bounded Context first -- the pool of pairs this skill can map. |
| `resource_get` | Read a Bounded Context's existing statements, including any `ContextRelationship` edges already recorded for it, before proposing a new one. |
| `bc_link_context(upstreamBcId, downstreamBcId, relationshipType)` | Record a confirmed relationship. Pure CRUD -- it never judges which type applies, and it is **not idempotent**: calling it again for the same pair creates a second edge rather than updating the first. |
| `impact_analysis` | Optional context on either Bounded Context before or after linking -- what already references it -- but this tool does not itself propagate through the relationship edge just created; treat any ripple reasoning about the relationship as yours, not the tool's. |

The eight `relationshipType` values `bc_link_context` accepts: `PARTNERSHIP`,
`SHARED_KERNEL`, `CUSTOMER_SUPPLIER`, `CONFORMIST`, `ANTICORRUPTION_LAYER`,
`OPEN_HOST_SERVICE`, `PUBLISHED_LANGUAGE`, `SEPARATE_WAYS` -- the classic
context-map vocabulary (Evans/Vernon). Presenting this list, and any
relationship `resource_get` already shows for the pair, is as far as the
tools go; which value fits is a judgement call for the user, not something
either tool infers.

## Protocol

1. **Read the map.** `bc_list` for the full set of contexts. If the user
   named two contexts already, confirm both exist and pull their ids; if
   they named only a domain area, ask which two contexts they mean rather
   than guessing from a name fragment.
2. **Check what's already recorded.** `resource_get` on both contexts
   before proposing anything new. If a relationship already exists between
   this exact pair, surface it and ask whether the user wants to record an
   *additional* edge (rare -- e.g. two contexts holding both a Shared
   Kernel and a separate Open Host Service for a different concern) or
   whether this is actually a correction to the existing one. There is no
   update/delete tool for `bc_link_context`: a wrong edge stays in the
   store, so confirm before writing rather than after.
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

## Scope boundary

- **No tactical design.** Aggregate, Entity, Value Object, Domain Event --
  none of it belongs here, and none of it has a tool surface yet.
- **No boundary-drawing.** If the user wants to discuss whether two
  contexts should exist at all, or where a boundary should sit, that is
  `/arknet:bc-audit`'s job -- this skill only maps relationships between
  contexts that already exist.
