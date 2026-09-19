# Contributing

Thanks for your interest in the arknet plugin.

## Maintenance status

This project is maintained on a best-effort basis by a single maintainer, in
spare time. Issues and pull requests are read and reviewed as capacity allows --
there is no service-level promise and no guaranteed turnaround. A slow or absent
response is not a judgement on your contribution; it just reflects available
time.

## Where things live

- **Code, issues, and pull requests** live on GitHub:
  [`github.com/kogn-io/arknet-plugin`](https://github.com/kogn-io/arknet-plugin).
  Bugs, feature requests, and questions about the plugin (skills, manifest,
  distribution `.mcp.json`) go here as issues.
- The **arknet MCP server** the skills talk to is a separate project:
  [`github.com/kogn-io/arknet`](https://github.com/kogn-io/arknet). Anything
  about the server itself -- tools, the domain model, the ontology -- belongs
  there, not here.

## Before you open a pull request

For anything beyond a trivial fix (typo, obvious one-line bug), **open an issue
first** and wait for a short go-ahead. This protects your time as much as the
maintainer's: a large or unsolicited PR that does not fit the project's scope
or design may not be merged, and it is frustrating for everyone to discover
that after the work is done.

Good candidates that rarely need discussion:

- Fixing a clearly wrong instruction or broken reference in a skill.
- Correcting documentation.

Things to raise in an issue first:

- New skills.
- Changes to a skill's triggering conditions or scope (what it should and
  should not fire on).
- Changes to `.claude-plugin/plugin.json` or the distribution `.mcp.json`.

## Working on a change

- Branch off `main`; pull requests target `main`.
- Keep pull requests **small and focused** -- one concern per PR. Split unrelated
  changes.
- Follow existing patterns across the skills; look before you guess.
- **Skills run in arbitrary projects -- do not encode one project's specifics.**
  No paths into another repository, no citing its instruction files as
  authority, no house conventions (artifact language, character set, section
  names) presented as rules of the skill. Where a skill needs an example, or a
  self-contained variant of its checklists for a mode `SKILL.md`'s own
  protocol does not cover, ship it beside it under `skills/<name>/references/`
  rather than pointing at files the reader does not have. Rules that must hold
  everywhere are the skill's; everything else follows the project being
  worked on.
- **A subagent this plugin ships (under an `agents/` directory) cannot declare
  its own `mcpServers` at all** -- Claude Code silently ignores that
  frontmatter field for plugin-bundled agents. Give such a subagent arknet
  access by listing the tool names (`mcp__arknet__req_add`, etc.) in its
  `tools:` field; that always resolves to the shared HTTP daemon already
  registered in the root `.mcp.json`, so there is no separate rule to apply
  here and no risk of a second local instance colliding with the daemon's
  file lock.
- Bump the `version` in `.claude-plugin/plugin.json` when a skill's shipped text
  changes **and the version currently on `main` has already been released**.
  Claude Code caches skill content by version, so a bump only buys anything for
  a version that ships. While `main` carries an unreleased version, further
  changes accumulate under it: one bump per release, not per pull request.
- **A skill that starts calling an arknet MCP tool needs nothing extra here** --
  naming the tool as a whole word in the skill's `SKILL.md` is enough; the
  compatibility hook derives which tools a skill needs from that text against
  `hooks/arknet-tools-baseline.json`, a generated snapshot of the arknet
  server's `tools/list`, not from a hand-maintained list. When the arknet
  server itself changes (a tool or parameter added, renamed or dropped), run
  `scripts/refresh-arknet-baseline.sh` by hand and review the resulting diff
  of the baseline file as part of the pull request -- that diff is the
  actual review artifact, not the file's content in isolation. Point it at a
  daemon running the **released** arknet the plugin ships alongside -- the
  published image or tag a user installs -- not at one built from a local
  checkout. A local build is ahead of the last release as often as it is
  behind it, and a baseline taken from it freezes a tool surface nobody is
  running: the check then passes for parameters a user's daemon rejects, or
  fails for ones it offers. The file records which daemon answered, so the
  claim is checkable, and it has three readings, not two: a semver tag
  (`vX.Y.Z`) is a release image and the only thing the refresh may be taken
  against; `dev` is an un-parameterized local `docker build`; a bare commit
  sha is the continuous build published as `:latest`, which follows the
  default branch rather than a release. The sha case is the trap, because a
  `:latest` pulled shortly after a release carries the release commit and so
  looks current -- it is still the wrong source, and it also degrades what a
  user is told, since the compat hook names both versions in its warning only
  when both parse as semver. Pin the daemon to the release tag before
  refreshing rather than reading a sha as "close enough", and if `:latest` is
  what this machine normally runs, keep the pin in an untracked
  `docker-compose.override.yml` on the arknet side -- the tracked compose file
  tells users to build locally, so a release tag written into it would label a
  local build as a release. Never run the refresh script unattended (a release
  workflow, a hook): an automatic regeneration would make the baseline track
  the server it exists to be checked against, silently absorbing exactly the
  drift the mechanism is meant to surface.
  `scripts/refresh-arknet-baseline.sh --check` reports the opposite
  direction -- tools or parameters the server now offers that the baseline
  (and by extension the shipped skills) does not mention yet -- without
  writing anything; run it when you suspect the server has moved ahead of
  what the plugin documents.
- **An arknet tool's own description is documentation, not proof of
  behaviour.** It is a layer of the server's docs like any other, and it can
  lag the code it describes: a rule it does not mention may hold all the
  same, so its silence settles nothing. Decide a behavioural claim against
  the service source (`git grep` in an arknet checkout, against
  `origin/main`) rather than against the description, and keep the two
  questions apart -- the live schema and the baseline answer what a tool
  *takes*, never what it *does*. Where one description departs from its
  siblings, that departure is itself the finding, not a licence to believe
  the minority: `actor_delete` and `term_delete` say nothing about the code
  staying taken while the six other `*_delete` tools say it outright, and
  the service keeps every code taken regardless. Behaviour verified that way
  may be documented here even where the description does not carry it --
  name the source in the pull request, and file an issue in the service repo
  so the description catches up.
- **A skill change that changes the flow or rules a skill describes pulls the
  matching `README.md` section along, in the same pull request.** The same
  drift as above, mirrored within this repo: `README.md` summarizes a
  skill's behaviour for a reader who has not opened `SKILL.md`, and a new
  step, a new rule, or a changed default that lands only in the skill file
  leaves that summary describing a flow the skill no longer follows. This is
  a process reflex too, not an automated check -- apply it to a material
  change (a step reordered, a rule added or dropped), not to a wording pass
  that leaves the described behaviour the same.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):
`type(scope): subject` (e.g. `fix(adr): ...`). Common types: `feat`, `fix`,
`docs`, `refactor`, `chore`, `ci`. Breaking changes get a `!` after the type or
a `BREAKING CHANGE:` footer. The project follows [Semantic
Versioning](https://semver.org/).

## AI-assisted contributions

AI-assisted contributions are allowed. If you use such tools, you remain
responsible for what you submit: understand the change, make sure it is correct,
and test it as you would any other change. Unreviewed machine-generated output is
not a shortcut around the bar above -- and large or sweeping AI-generated changes
may be rejected on scope alone, regardless of correctness.

## Licensing

By submitting a contribution you agree that it is licensed under the project's
[Apache 2.0 license](LICENSE). Do not submit code you do not have the right to
contribute under that license.

## Reporting bugs

Open an [issue](https://github.com/kogn-io/arknet-plugin/issues) with a minimal
reproduction and the expected vs. actual behaviour. For anything
security-sensitive, do **not** post publicly -- see [SECURITY.md](SECURITY.md).
