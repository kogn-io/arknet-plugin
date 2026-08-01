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
  names) presented as rules of the skill. Where a skill needs an example, ship
  one beside it under `skills/<name>/reference/` rather than pointing at files
  the reader does not have. Rules that must hold everywhere are the skill's;
  everything else follows the project being worked on.
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
- **A skill that calls an MCP tool merged into `arknet` after this plugin's
  last-tested baseline must not let that surface as a raw "unknown tool"
  error.** The plugin and the `arknet` server release independently, and
  Claude Code has no channel that lets a skill actively query which server
  version it is talking to (the MCP `initialize` handshake's
  `serverInfo.version` is client-level, not something a tool call can read).
  So: note next to the tool, in the skill's own tool table, which `arknet`
  issue/PR introduced it, and add a protocol step that catches the resulting
  unknown-tool error and tells the user plainly that their connected `arknet`
  server predates what the skill needs -- instead of relaying the raw MCP
  error or failing silently. See `/arknet:bc-audit`'s `actor_usecase_matrix`/
  `term_cooccurrence` entries for the pattern.

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
