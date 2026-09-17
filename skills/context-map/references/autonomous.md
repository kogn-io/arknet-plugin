# Autonomous mode -- no dialogue partner

**When this applies:** a document already states or implies how two
existing Bounded Contexts relate, and nobody is available to confirm the
classification. This mode runs elicitation mode's own judgement as a
decision instead of a question; it does not carry the elicitation
protocol's pacing (one pair, one question, wait for the answer) along --
that mechanic does not apply here.

**What stays exactly as in elicitation mode:**

- The precondition: at least two Bounded Contexts must already exist
  (`bc_list`). Fewer than two -> stop, write nothing, hand back pointing at
  `/arknet:bc-audit` -- inventing a context to complete a pair is exactly
  as wrong here as in elicitation mode.
- The evidence: `domainVision`, linked glossary terms, and the
  requirements/use cases that cross the pair -- never invented,
  regardless of how plausible a type looks without it.
- Direction: for the five asymmetric types (`CUSTOMER_SUPPLIER`,
  `CONFORMIST`, `ANTICORRUPTION_LAYER`, `OPEN_HOST_SERVICE`,
  `PUBLISHED_LANGUAGE`), `upstreamBcId` is still the side whose model
  prevails; for the three symmetric ones the tool's upstream/downstream
  pair is still bookkeeping, never a real asymmetry to report.
- `bc_link_context` itself: same idempotent write, same triple.

**The one substitution:** the review mode's own four rules (see
`SKILL.md`) double as the *decision* test here, run before the write
instead of after it:

- Re-derivable (C1) -- name, from the two contexts' material, what makes
  this type fit rather than a neighbour, and which neighbour was ruled
  out.
- Direction (C2) -- for an asymmetric type, which side's model the other
  clearly adapts to.
- Obligation (C3) -- does anything in the material already carry what the
  type commits the pair to (a translation layer, a jointly-owned model, a
  published, documented model)?
- Distinguishes the pair (C4) -- would the chosen type fit any pair that
  merely exchanges data, or does it say something specific about *this*
  one?

A "no" on C1 is not a reason to fall back to a default type (`PARTNERSHIP`
is not a safe default): if no material lets you name a fit, do not write
the relationship at all -- report the pair as unresolved and name what
material is missing, the same way elicitation mode would surface an open
question rather than guess. Where C1 does clear, but C2's direction is
genuinely unreadable from the material, decide from whatever signal
exists and mark it, rather than leave direction unresolved for a type that
requires one.

## Marking an assumption

`bc_link_context` carries no prose field -- unlike a requirement's
`rationale` or a term's `definition`, there is nowhere on the edge itself
to attach why a type was chosen. Do **not** work around this by writing the
reasoning into either context's `domainVision`: a relationship-to-another-
context statement there is exactly the "component description instead of
domain meaning" failure `/arknet:bc-audit`'s review mode (rule B6) already
flags, autonomous or not.

Instead, mark every autonomous classification in the run's own report back
to whoever invoked it -- one line per edge written, in the same form as
elsewhere:

> ASSUMPTION: OrderManagement / Billing recorded as
> `CUSTOMER_SUPPLIER` (OrderManagement upstream) -- Billing's glossary
> terms consistently restate OrderManagement's order concepts with no
> terms of its own for them, and no shared-ownership or translation-layer
> evidence rules out the neighbouring types.

A run that writes `bc_link_context` calls from a document and reports only
"the map is now filled in" has classified without a dialogue partner and
left no trace of why -- report the reasoning every time, not only when
asked.
