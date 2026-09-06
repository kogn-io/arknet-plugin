---
description: "One-time onboarding of the project you are working in to arknet. Two jobs: it appends a short routing block to that project's CLAUDE.md, so every later session learns that the architecture model lives in the arknet store and not in files; and it makes the current directory resolve to the right project in the store, choosing between project_add, project_adopt and project_attach_anchor before anything is written -- a wrong choice silently creates a second project and there is no project_delete to undo it. Trigger (also DE, since the user may phrase it in German): /arknet:init, 'attach this project to arknet', 'set up arknet for this project', 'onboard this project', 'register this project with arknet', 'is this directory registered with arknet'; DE: 'dieses Projekt an arknet anbinden', 'arknet fuer dieses Projekt einrichten', 'Projekt registrieren', 'ist dieses Verzeichnis registriert'. NOT the brownfield requirements interview -- interrogating an existing codebase for requirements, use cases and glossary terms is /arknet:req-interview ('interrogate the existing codebase'), which runs after this skill. NOT a status report on what the store already holds (use /arknet:health-check). NOT a per-session step -- this runs once per project, and re-running it is safe."
---

# /arknet:init -- Onboard a Project to arknet

A **one-time setup**, not a modelling skill. It writes no requirement, no
use case, no term. It does two things, and the first matters more than the
second:

1. **The routing block.** A project using arknet has nothing that tells a
   fresh session where its architecture model lives. Without that sentence, a
   session asked for an ADR writes `docs/adr/0001-....md` and never learns
   that the store exists. The block in the project's `CLAUDE.md` is what
   closes that gap.
2. **The anchor.** The directory the session starts in has to resolve to the
   right project in the store -- and there are three different tools for
   getting there. Picking the wrong one is not correctable: `project_add`
   called from a second checkout silently creates a **second project**, and
   the tool surface has no `project_delete`.

Dialogue discipline is `/arknet:req-interview`'s: **one question at a time,
each with your own proposal attached**, derived from what the repository
actually shows (its README title, its git remote name, the language its
existing documentation is written in) -- never a blank prompt. You propose,
the user decides.

## Step 1: resolve the anchor

Run `project_list` first, always. It reports every registered project with
its anchors, and below that the datasets in the store that no project claims
yet. Compare the current working directory against both halves of that
output, then place the situation in one of four cases. Ask the user to
confirm which case applies -- a git worktree and a fresh clone look identical
from inside the directory, and only the user knows which it is.

| What `project_list` shows for this directory | The right call |
|---|---|
| An anchor of an existing project matches the current directory | Nothing to register -- go to the review below, then step 3. |
| No matching anchor, but a listed project **is** this project, worked on from another directory (a git worktree, a second checkout, another IDE workspace) | `project_attach_anchor(anchor: "<this directory>", callerAnchor: "<one of that project's anchors, as listed>")` |
| No matching anchor, but an **unregistered dataset** belongs to this project (data written before projects were registered, or restored from a backup) | `project_adopt(datasetId: "<id as listed>", label: "<label>")` |
| No matching anchor, nothing to attach to and nothing to adopt | `project_add(label: "<label>", ...)` -- see step 2 |

**Why the distinction is worth a question:** from an unregistered directory
`project_add` and `project_adopt` both succeed, and `project_add` in the
second row would not warn -- it would create a second, empty project
alongside the real one, and the session would then write its model into the
wrong one. `project_attach_anchor` called without `callerAnchor` from that
same directory fails instead, with an error that names `project_add` as one
remedy -- which is exactly how the wrong call gets made. There is no
`project_delete`, so say this out loud before proposing a call, rather than
after.

**Already registered:** report the project's state as `project_list` gives
it -- label, `defaultLanguage`, `languages`, description -- and offer
`project_update` for whatever is missing. Push hardest on an absent
`languages` set: it is the only thing `store_check` compares the store
against, so a project without it gets `LANGUAGE: not checked` and the check
is silently off. That is not a cosmetic gap.

**The anchor parameters.** `project_add`/`project_adopt` take an optional
`anchor` (+ `anchorType`), and `project_attach_anchor`/`project_update`/
`project_rename` an optional `callerAnchor`. Both exist for clients that
cannot supply their own origin directory. Claude Code does supply it, so
**omit them** -- with one exception that is the whole point of the second
row: `project_attach_anchor` finds the project to extend through the
*caller's* anchor, and from a worktree the caller's anchor is the very
directory that is not registered yet. So from the new directory the call
needs both `anchor` (the new directory) **and** `callerAnchor` (an anchor
the project already has, copied from `project_list`). Without
`callerAnchor` it fails as "not registered with any project".

## Step 2: the fields

Only for `project_add` and for a `project_update` filling gaps. One question
per field, proposal attached, in this order:

- **`label`** -- the project's cross-project-unique, human-readable name.
  Propose the repository or directory name (`basename` of the working
  directory, or the git remote's repository name), not the README's prose
  title.
- **`defaultLanguage`** -- a BCP-47 tag, the fallback for calls and reads that
  name no language of their own. Propose the language the repository's own
  documentation is written in.
- **`languages`** -- the set of languages the project **undertakes to
  maintain** its model in. This is a commitment, not a fallback: it is what
  `store_check` checks against. Propose the languages the repository's docs
  actually use today (one is a perfectly good answer), and say what declaring
  none costs. `defaultLanguage` has to be a member of a non-empty set, or the
  call is refused.
- **`description`** -- optional, one or two sentences on what the project is.
  Propose one derived from the README's opening paragraph, and tag it with
  `language`. An untagged description cannot later be complemented by a
  second-language variant without overwriting it.

## Step 3: the CLAUDE.md routing block

Append this block to the project's `CLAUDE.md`, creating the file if it does
not exist. Write it **verbatim**, in English, whatever the project's
`defaultLanguage` is -- the reader is Claude Code, not a human:

```markdown
<!-- arknet:init -->
## Architecture model

This project's architecture model -- requirements, use cases, glossary terms,
bounded contexts, architecture decisions and constraints -- lives in the
arknet store, not in files in this repository. Read it and change it through
the `/arknet:*` skills.

Do not create requirement, use-case, glossary or ADR markdown files for this
project. A model kept in two places drifts, and the store is the one that
counts.
<!-- /arknet:init -->
```

Rules for writing it:

- **Append, never overwrite, never reorder.** The rest of `CLAUDE.md` is
  untouched -- other sections keep their position and their wording. This
  holds regardless of whether Claude Code's built-in `/init` ran before or
  after this skill; the two write different things and never need an order.
- **Idempotent.** The `<!-- arknet:init -->` / `<!-- /arknet:init -->` pair is
  there so a later run can *recognise* the block: on re-run, replace
  everything between the markers in place instead of appending a second copy.
  If the markers are absent, append the block at the end of the file.
- **Nothing that the store already holds** goes in: no label, no languages,
  no anchor path, no description. A copy of a stored field drifts from the
  store, which is exactly the failure the block exists to prevent.
- **No tool lists, no version numbers, no build state.** Tool schemas reach
  the agent directly and age with every server release.
- **No export path.** An export is a snapshot *out of* the store, never a
  source *for* it; naming a directory here hands the agent a file to edit
  again. If the project keeps one, it belongs in README/CONTRIBUTING, where a
  human looks it up.

Show the user the block (and, on a re-run, the diff against what is already
there) before writing, and say which file you are about to touch.

## Running it again

Safe by design, and the normal way to fix an incomplete registration: step 1
reports the resolved project instead of registering anything, step 2 becomes
a `project_update` offer for the fields still empty, step 3 replaces the
marked block with the current wording. Nothing is duplicated and nothing is
overwritten outside the markers.

## Scope boundary

- **No model content.** This skill never calls `req_add`, `uc_add`,
  `term_add`, `adr_add` or any other store-content tool. Once the project
  resolves and the block is in place, hand off to `/arknet:req-interview`
  ("interrogate the existing codebase" for a brownfield project, or an idea
  in a sentence for a greenfield one).
- **No renaming as a side effect.** `project_rename` changes a label the user
  is unhappy with and nothing else; it is not part of the onboarding flow and
  is never called to "tidy up" a label the user did not complain about.
- **Not a status report.** What the store already contains, and whether it is
  consistent, is `/arknet:health-check`'s question, not this skill's.
