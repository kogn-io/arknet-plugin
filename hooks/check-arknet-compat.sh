#!/usr/bin/env bash
# SessionStart hook: warns if the connected arknet MCP server no longer
# matches what hooks/arknet-tools-baseline.json (a generated snapshot, see
# scripts/refresh-arknet-baseline.sh) says the shipped skills were last
# verified against. Has no dedup of its own -- the matcher in
# hooks/hooks.json bounds how often it runs (startup, resume, clear), so a
# /clear repeats the warning on purpose, the emptied context no longer
# carrying the earlier one.
#
# A tool is "needed" by a skill when that skill's SKILL.md names the tool
# as a whole word, checked only against tool names the baseline actually
# has -- no hand-maintained list. For each such tool this compares the
# live server against the baseline: does the tool still exist, and does
# every baseline parameter for it still exist live. It only ever reports
# the server falling behind the baseline (missing tool, missing
# parameter) -- the server offering more than the baseline knows about is
# a maintainer concern, see scripts/refresh-arknet-baseline.sh --check.
#
# Never the reason a session fails to start -- any failure here (missing
# curl/jq, unreachable server, malformed response, no baseline file) exits
# silently instead of surfacing an error.
set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MCP_CONFIG="$PLUGIN_ROOT/.mcp.json"
BASELINE="$PLUGIN_ROOT/hooks/arknet-tools-baseline.json"
SKILLS_DIR="$PLUGIN_ROOT/skills"

command -v curl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[ -f "$MCP_CONFIG" ] || exit 0
[ -f "$BASELINE" ] || exit 0
[ -d "$SKILLS_DIR" ] || exit 0

baseline_tool_names=$(jq -r '.tools | keys[]?' "$BASELINE" 2>/dev/null | sort -u)
[ -n "$baseline_tool_names" ] || exit 0

# A skill "needs" a baseline tool when its SKILL.md names it as a whole
# word -- extract every word-token from the skill text and intersect with
# the baseline's tool names, rather than grepping per tool name.
skill_map_json="{}"
for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  skill_name=$(basename "$(dirname "$skill_md")")
  words=$(grep -oE '[A-Za-z_][A-Za-z0-9_]*' "$skill_md" 2>/dev/null | sort -u)
  [ -n "$words" ] || continue
  matched=$(comm -12 <(printf '%s\n' "$baseline_tool_names") <(printf '%s\n' "$words"))
  [ -n "$matched" ] || continue
  matched_json=$(printf '%s\n' "$matched" | jq -R . | jq -s .)
  skill_map_json=$(printf '%s' "$skill_map_json" | jq --arg skill "$skill_name" --argjson tools "$matched_json" '. + {($skill): $tools}')
done
[ "$skill_map_json" != "{}" ] || exit 0

url=$(jq -r '.mcpServers.arknet.url // empty' "$MCP_CONFIG" 2>/dev/null)
[ -n "$url" ] || exit 0

headers=$(mktemp) || exit 0
init_body=$(mktemp) || exit 0
trap 'rm -f "$headers" "$init_body"' EXIT

curl -s -m 3 -X POST "$url" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"arknet-plugin-compat-check","version":"1"}}}' \
  -D "$headers" -o "$init_body" || exit 0

# Streamable HTTP transport: tools/list needs the session id the server
# handed back on initialize.
session_id=$(sed -n 's/^[Mm]cp-[Ss]ession-[Ii]d:[[:space:]]*//p' "$headers" | tr -d '\r\n')
[ -n "$session_id" ] || exit 0

init_json=$(sed -n 's/^data://p' "$init_body")
[ -n "$init_json" ] || init_json=$(cat "$init_body")
live_version=$(printf '%s' "$init_json" | jq -r '.result.serverInfo.version // empty' 2>/dev/null)

curl -s -m 3 -X POST "$url" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "Mcp-Session-Id: $session_id" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' -o /dev/null

tools_response=$(curl -s -m 3 -X POST "$url" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "Mcp-Session-Id: $session_id" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}') || exit 0

# The server answers as one SSE frame ("data: {...}") rather than a bare
# JSON body -- strip that framing if present, use the body as-is otherwise.
tools_json=$(printf '%s\n' "$tools_response" | sed -n 's/^data://p')
[ -n "$tools_json" ] || tools_json="$tools_response"

live_tools_json=$(printf '%s' "$tools_json" | jq -c '[.result.tools[]? | {name: .name, params: ((.inputSchema.properties // {}) | keys)}]' 2>/dev/null)
[ -n "$live_tools_json" ] && [ "$live_tools_json" != "null" ] || exit 0

report=$(jq -n \
  --argjson skillMap "$skill_map_json" \
  --slurpfile baseline "$BASELINE" \
  --argjson live "$live_tools_json" \
  '
  ($baseline[0]) as $b
  | ($live | map({key: .name, value: (.params)}) | from_entries) as $liveMap
  | ($skillMap | to_entries | map(
      .key as $skill
      | (
          .value | map(
            . as $t
            | if ($liveMap | has($t) | not) then
                {tool: $t, kind: "tool"}
              else
                (($b.tools[$t] // []) - ($liveMap[$t] // [])) as $missing
                | if ($missing | length) > 0 then
                    {tool: $t, kind: "params", missing: $missing}
                  else empty end
              end
          )
        ) as $issues
      | select(($issues | length) > 0)
      | {skill: $skill, issues: $issues}
    )) as $affected
  | select(($affected | length) > 0)
  | ($affected | sort_by(.skill)) as $sorted
  | ($sorted | map(
      "- " + .skill + " needs: " + (
        .issues | map(
          if .kind == "tool" then .tool + " (tool missing)"
          else .tool + " missing param(s): " + (.missing | join(", "))
          end
        ) | join("; ")
      )
    )) as $lines
  | {
      lines: ($lines[0:5]),
      more: (($lines | length) - 5)
    }
  ' 2>/dev/null)

[ -n "$report" ] || exit 0

# Version line: names both versions if they both look like SemVer
# (^v?[0-9]+\.[0-9]+\.[0-9]+), otherwise says only that the builds differ.
# Never interpreted beyond that -- a continuous build reports a commit
# SHA, not a comparable version.
baseline_version=$(jq -r '.serverInfo.version // empty' "$BASELINE" 2>/dev/null)
semver_re='^v?[0-9]+\.[0-9]+\.[0-9]+'
if printf '%s' "$live_version" | grep -Eq "$semver_re" && printf '%s' "$baseline_version" | grep -Eq "$semver_re"; then
  version_line="the daemon reports $live_version, the baseline was taken against $baseline_version"
else
  version_line="the daemon is a different build than the baseline was taken against"
fi

lines_text=$(printf '%s' "$report" | jq -r '.lines[]')
more=$(printf '%s' "$report" | jq -r '.more')

context="arknet compatibility check: the connected arknet MCP server is behind what the installed skills were verified against ($version_line):
$lines_text"
if [ "$more" -gt 0 ] 2>/dev/null; then
  context="$context
...and $more more"
fi
context="$context

These skills may fail or behave unexpectedly until the arknet-mcp daemon and this plugin are on matching versions."

jq -n --arg text "$context" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $text}}'
exit 0
