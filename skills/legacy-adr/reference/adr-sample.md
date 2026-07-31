> **This is a teaching sample shipped with the `/arknet:adr` skill, not a real decision of
> any project.** It is invented. Read the record below, then the notes after it, which say
> what makes it a gold standard and which mistakes it deliberately avoids.
>
> The sample is in English and uses the English section names. A project whose ADRs are
> written in another language keeps that language and those section names -- see
> "Adapt to the project" in `SKILL.md`.

---

# ADR-007: Publish integration events through a transactional outbox

- Status: Accepted (2026-03-11)
- Related: ADR-004

## Context

Order state changes have to reach the billing and notification services. The service owns a
relational database and writes its state changes in a transaction; the broker is a separate
system with its own availability.

Publishing inside the transaction couples two systems that fail independently. Either the
commit succeeds and the publish fails -- consumers never learn about a state change that
did happen -- or the publish succeeds and the commit rolls back, and consumers act on a
state change that never happened. Both have occurred in the previous service generation,
and both were diagnosed only through customer reports, because nothing in the system
recorded that an event was owed.

Order state is the source of truth for downstream billing. Silent divergence between what
the database holds and what consumers were told is the failure we are deciding against.

## Decision

Integration events are written into an outbox table in the same transaction as the state
change they describe. A separate relay reads that table and publishes to the broker.
Application code never publishes to the broker directly.

The relay guarantees at-least-once delivery. Consumers are therefore required to be
idempotent; that requirement is part of the contract we publish, not an implementation
detail of the relay.

## Consequences

**Positive:** a state change and the obligation to announce it commit or fail together, so
the database can no longer diverge silently from what consumers were told. Broker downtime
becomes a delay rather than a data loss -- unpublished events accumulate in a table that can
be inspected and counted, which makes the backlog a visible operational quantity instead of
an invisible one.

**Negative / deliberately deferred (YAGNI):** every consumer now carries the cost of
idempotency, including consumers for which duplicates would have been harmless. Events
arrive with a delay bounded by the relay's polling interval rather than immediately, so
end-to-end latency is no longer the broker's latency alone.

Ordering across different aggregates is not guaranteed and we deliberately do not solve it
here -- no current consumer needs it, and buying it would mean a single-threaded relay or
partition keys, both of which cost more than the problem is worth today. If a consumer ever
needs cross-aggregate ordering, that is a new decision, not an adjustment to this one.

## Alternatives

- **Publish inside the transaction, roll back on publish failure.** Makes the broker a
  participant in every write path: its downtime becomes the service's downtime, and the
  rollback itself can fail after a successful publish. Rejected.
- **Two-phase commit across database and broker.** Solves the consistency question in
  principle, but the broker in use offers no usable XA support, and the operational cost of
  distributed transactions exceeds that of idempotent consumers. Rejected.
- **Change data capture from the database log.** Removes the outbox table and the relay, and
  would likely be the better answer at a larger scale. It ties the event schema to the
  physical table layout, which we are still changing frequently. Rejected for now
  (revisitable once the schema stabilises).

---

## Why this is a gold standard

**The context names forces, not history.** It says what pulls in which direction --
independent failure modes, order state as source of truth downstream -- and it says what
went wrong before in terms that stay true regardless of the current code. It does not say
"we are currently on version 3.2 of the broker library".

**The decision is one decision** -- the independence test in `SKILL.md`, applied. Outbox
instead of inline publishing. The idempotency requirement is not a second decision smuggled
in; it is a facet of the same reversal -- undo the outbox and the requirement goes with it.
Had the record also decided *which* broker to use, that would have been a second ADR: the
broker could have gone the other way without touching this one.

**The consequences are consequences.** They state what is durably true afterwards, positive
and negative, rather than restating the decision in different words. The deferred point
carries its reason and its trigger ("if a consumer ever needs cross-aggregate ordering") --
that is a result of the decision, not a worklist item.

**The alternatives are substantive.** Each names a real option with the reason it lost, and
one is marked revisitable with the condition under which it would be reconsidered. None of
them is filler.

**No implementation detail.** No class names, no method signatures, no polling interval in
milliseconds, no table DDL. The record says *outbox table* and *relay* -- roles, not code.
Someone reading it in three years learns why the shape is what it is; the code tells them
what it currently looks like.

**No status, no addendum.** The record does not say how far the migration has got, which
services are already on it, or which PR delivered the relay. When the third consumer moves
over, nothing here changes -- that is tracker content. Once this record went to `Accepted`,
everything above the notes froze.
