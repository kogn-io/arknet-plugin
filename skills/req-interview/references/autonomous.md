# Autonomous mode -- no dialogue partner

This file stands on its own: the checklists below, plus the marking
convention, are everything a run needs once the tool surface itself
(`req_add`/`uc_add`/`term_add`/... and their parameters) is already known
from the MCP tools' own schemas. It does not restate the interrogation
protocol in `SKILL.md` -- that protocol's pacing (one question at a time,
draft-then-confirm) does not apply here.

**When this applies:** a finished document -- a specification, a ticket, an
existing spec, a change notice -- is the source, and nobody is available to
answer a question. Greenfield or brownfield does not matter; the absence of
a return channel does.

**What stays exactly as in dialogue mode:**

- The precondition: the project must resolve to a project in the store
  (`project_list`). No match -> stop, write nothing, and hand back pointing
  at `/arknet:init` -- guessing a registration call is exactly as wrong here
  as in dialogue mode.
- Everything resolvable by research, the store, or the project's own
  documented ubiquitous language is resolved that way, never turned into an
  assumption for convenience. Only what dialogue mode would have put to the
  user as a scope/priority/shape question becomes an assumption here.
- The write order: roles and terms first, then requirements, then use
  cases -- dependency order, not elicitation order. Held onto without a
  dialogue partner, this is the one rule already shown to carry on its own.
- The ripple check after every written change (`impact_analysis`, then
  `text_search` for a wording change) -- unaffected by the absence of
  dialogue.

**The one substitution:** wherever the interrogation protocol says *ask the
user*, this mode makes a reasoned decision instead and marks it as an
assumption (see below). A shape question ("is this an actor or a role?",
"is this one use case or two?") is still resolved at a concrete draft, the
same way dialogue mode resolves it -- the draft is written with the disputed
field filled in as the best-supported reading; there is simply no
confirmation step afterward, and the disputed field's value is what gets
marked.

**Never a silent default.** A decision genuinely cannot be made from the
document at hand -- not "hard", genuinely absent -- do not invent one to
fill the field. Leave that one point out (skip the optional field, or hold
the whole item back) and name the gap in the run's report, rather than
write a guess wearing an assumption marker as cover.

## Marking an assumption

The store has no dedicated field for this yet (a structural gap, tracked
elsewhere, not something this convention works around by inventing a
field). Until it does, an assumption is marked in prose, in whichever field
already carries reasoning for that resource -- `rationale` for a
requirement or constraint, a trailing sentence in `description`, `goal`,
`definition` where no dedicated reasoning field exists -- and always as its
own sentence, never folded into the middle of a normative one. The
sentence starts with the literal marker `ASSUMPTION:`, so that a later,
resource-type-independent `text_search("ASSUMPTION:")` finds every one
this run left, regardless of which field or resource carries it. State
what was decided and why, in the same why-not-what tone as `rationale`:

> ASSUMPTION: the source document names no retry limit; treated as
> unranked (COULD_HAVE) pending confirmation.

Also name every assumption once more in the run's own report back to
whoever invoked it -- the field carries it in the store, the report carries
it to the reader who is not going to run `text_search` on spec. A run that
writes resources from a document and leaves no `ASSUMPTION:` sentence
anywhere has not decided anything without a dialogue partner; it has
decided silently, which is the failure this convention exists to prevent.

## Checklist per requirement

Linguistic-defect filter first (SOPHIST/Rupp):

- Passive voice / missing actor -- name the active subject.
- Nominalisation -- unfold the hidden process into steps, inputs, outcome.
- Incomplete comparative -- than what, measured how; make it checkable or
  drop it.
- Universal quantifier ("all"/"every"/"never"/"always") -- hunt the
  counter-case.
- Underspecified process word/condition ("on error, abort"; "if needed") --
  which error, then exactly what; which condition, decided by whom.

Then the quality attributes (ISO/IEC/IEEE 29148):

- Completeness -- missing scenarios, edge cases, actors/roles, failure/
  timeout paths?
- Unambiguity -- readable more than one way?
- Consistency -- conflicts with another requirement/use case/term (check
  against `req_list`/`uc_list`/`term_list`, not in isolation)?
- Testability -- at least one objective `acceptanceCriteria` entry, not a
  restatement of `description`?
- Rationale -- states *why*, not a restatement of *what*; missing is an
  `ASSUMPTION:` candidate, not a field left empty.
- Dependencies -- what does it presuppose/affect?
- Non-functional aspects -- performance, security, scalability, failure
  behaviour considered against the existing NFR set?
- Priority differentiation -- does it genuinely differ from the rest, or
  is `MUST_HAVE` a placeholder? What breaks if this is cut?
- Type classification -- FR vs. NFR vs. Constraint, see the test below.

**FR vs. NFR vs. Constraint, one test:** could the project decide
otherwise? No, and the statement names who/what imposes it (law, contract,
platform, budget, organisation) -> Constraint. Yes, and it is a gradable
quality property -> NFR. Yes, and it is a functional behaviour -> FR. A
binary-phrased acceptance criterion is not itself evidence for Constraint --
self-set NFRs are phrased binary too, for testability.

## Checklist per use case

Cockburn completeness:

- Trigger clear? Primary/supporting role correct and already registered
  (`role_add` before `uc_add`) -- the function driving it, not just
  whichever carrier happens to call it.
- Goal-in-context in one sentence, no technical how.
- Main flow (`steps`) gaplessly numbered, each step a testable state
  transition.
- Alternative/exception flows (`extensions`) -- empty run, partial
  failure, timeout, abort considered?
- `realises` link -- at least one step fulfils an existing FR/NFR? A
  missing link is an `ASSUMPTION:` candidate ("no requirement in the
  document covers this step; use case recorded standalone"), not a link
  invented to avoid the gap.
- Title differentiation -- reads as the role's broader goal, not the
  linked requirement's title carried over verbatim.

## Checklist per glossary term

- Unambiguous against existing terms (`term_list` first) -- no hidden
  synonym or homonym?
- Unambiguous against established external meaning, even with no local
  hit -- does the label already carry an industry-standard connotation
  this definition would silently contradict?
- Definition precise enough for two independent readers to land on the
  same thing?
- Actually an actor or a role, not a term (see the actor/role checklist)?
- Duplication against a related term -- re-derive a shared fact via
  cross-reference rather than re-enumerating it in a second definition.
- Implementation-free -- no system/software/storage technology named.
- Architecture-decision-free -- no source-of-record, persistence choice,
  tenancy model, or trigger/ownership statement smuggled into what the
  word *means*.
- Config-free -- no concrete, dated value the document elsewhere marks as
  changeable.

## Checklist per actor

- Carrier, not function -- exists whether or not the project models it
  (person, organisation, system), answers "what is it", not "what does it
  do here".
- `type` correct (`HUMAN`/`SYSTEM`/`LEGAL`/`GROUP`) -- no in-place fix once
  written, so get it right before `actor_add`; a wrong-typed actor found
  later is an `ASSUMPTION:` note plus a named correction path
  (`actor_delete` + fresh `actor_add`), not a silent leave-as-is.
- Occupies a role, or is deliberately free-standing (an external system
  worth recording on its own)?
- Distinct from every other actor already written this run.

## Checklist per role

- Anti-rigid function, not a proper name -- survives a change of
  occupant?
- Named by at least one use case (`primaryRole`/`supportingRoles`) -- a
  role with no driving use case in the document is not written in on
  spec.
- Distinct from every other role already written this run.
- `filledBy` stated where the document names a carrier, left empty and
  marked as such where it does not -- not silently assumed unfilled
  without saying so was a choice.
- `description` states the responsibility, not a restatement of the name.
