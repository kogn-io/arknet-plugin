#!/usr/bin/env bash
# Maintainer tool, run by hand in a repo checkout -- never from CI, never
# from a hook. Talks to the arknet MCP server named in the repo's own
# .mcp.json (same streamable-HTTP handshake as hooks/check-arknet-compat.sh:
# initialize, read back the Mcp-Session-Id, notifications/initialized,
# tools/list, strip the SSE "data:" framing if the server used it) and
# writes hooks/arknet-tools-baseline.json: one line per tool with its
# sorted parameter names, tools sorted alphabetically, so a regenerated
# baseline produces a readable git diff. serverInfo (name, version) from
# the same handshake is recorded alongside as metadata -- shown by the
# compat hook, never parsed as anything more than a string.
#
# Regenerating replaces what the file currently says the server offers;
# review the diff before committing it. Point it at a daemon running the
# RELEASED arknet the plugin ships alongside -- the published image or tag a
# user installs -- not at one built from a local checkout. The baseline is
# what the shipped skills are checked against, so a surface nobody runs is
# worse than a stale one, and the serverInfo.version recorded alongside says
# which was used: "dev" is a local build. It is load-bearing beyond the
# record, too -- hooks/check-arknet-compat.sh only names both versions in its
# warning when both parse as semver, so a "dev" baseline degrades what a user
# is told to "the daemon is a different build". This intentionally never runs
# unattended -- an automatic regeneration (release workflow, hook) would
# make the baseline track the server it is supposed to be checked against,
# and the whole point of the file is to freeze what shipped skills were
# last verified against.
#
# Usage:
#   scripts/refresh-arknet-baseline.sh           write the baseline file
#   scripts/refresh-arknet-baseline.sh --check    report drift, write nothing
#
# --check compares the live server against the existing baseline in both
# directions -- tools/parameters the server offers that the baseline does
# not know about, and tools/parameters the baseline lists that the live
# server no longer has -- and exits non-zero if either side differs. It is
# the maintainer-facing counterpart to the user-facing compat hook, which
# only ever checks the direction that affects a user (server behind the
# baseline).
set -u

mode="write"
if [ "${1:-}" = "--check" ]; then
  mode="check"
elif [ "${1:-}" != "" ]; then
  echo "usage: $0 [--check]" >&2
  exit 2
fi

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_CONFIG="$PLUGIN_ROOT/.mcp.json"
BASELINE="$PLUGIN_ROOT/hooks/arknet-tools-baseline.json"

command -v curl >/dev/null 2>&1 || { echo "refresh-arknet-baseline: curl not found" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "refresh-arknet-baseline: jq not found" >&2; exit 1; }
[ -f "$MCP_CONFIG" ] || { echo "refresh-arknet-baseline: $MCP_CONFIG not found" >&2; exit 1; }

url=$(jq -r '.mcpServers.arknet.url // empty' "$MCP_CONFIG" 2>/dev/null)
[ -n "$url" ] || { echo "refresh-arknet-baseline: no mcpServers.arknet.url in $MCP_CONFIG" >&2; exit 1; }

headers=$(mktemp) || exit 1
init_body=$(mktemp) || exit 1
trap 'rm -f "$headers" "$init_body"' EXIT

curl -s -m 10 -X POST "$url" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"arknet-plugin-baseline-refresh","version":"1"}}}' \
  -D "$headers" -o "$init_body" || { echo "refresh-arknet-baseline: initialize call failed against $url" >&2; exit 1; }

session_id=$(sed -n 's/^[Mm]cp-[Ss]ession-[Ii]d:[[:space:]]*//p' "$headers" | tr -d '\r\n')
[ -n "$session_id" ] || { echo "refresh-arknet-baseline: no Mcp-Session-Id header in initialize response" >&2; exit 1; }

init_json=$(sed -n 's/^data://p' "$init_body")
[ -n "$init_json" ] || init_json=$(cat "$init_body")

server_name=$(printf '%s' "$init_json" | jq -r '.result.serverInfo.name // empty' 2>/dev/null)
server_version=$(printf '%s' "$init_json" | jq -r '.result.serverInfo.version // empty' 2>/dev/null)
[ -n "$server_name" ] || server_name="unknown"
[ -n "$server_version" ] || server_version="unknown"

curl -s -m 10 -X POST "$url" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "Mcp-Session-Id: $session_id" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' -o /dev/null

tools_response=$(curl -s -m 10 -X POST "$url" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "Mcp-Session-Id: $session_id" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}') || { echo "refresh-arknet-baseline: tools/list call failed" >&2; exit 1; }

# The server answers as one SSE frame ("data: {...}") rather than a bare
# JSON body -- strip that framing if present, use the body as-is otherwise.
tools_json=$(printf '%s\n' "$tools_response" | sed -n 's/^data://p')
[ -n "$tools_json" ] || tools_json="$tools_response"

live_tools=$(printf '%s' "$tools_json" | jq -c '[.result.tools[]? | {name: .name, params: ((.inputSchema.properties // {}) | keys)}]' 2>/dev/null)
[ -n "$live_tools" ] && [ "$live_tools" != "null" ] || { echo "refresh-arknet-baseline: could not parse tools/list response" >&2; exit 1; }

tool_count=$(printf '%s' "$live_tools" | jq 'length')
[ "$tool_count" -gt 0 ] || { echo "refresh-arknet-baseline: server reported zero tools" >&2; exit 1; }

if [ "$mode" = "check" ]; then
  [ -f "$BASELINE" ] || { echo "refresh-arknet-baseline: $BASELINE does not exist yet -- nothing to check against" >&2; exit 1; }

  report=$(jq -n \
    --slurpfile baseline "$BASELINE" \
    --argjson live "$live_tools" \
    '
    ($baseline[0]) as $b
    | ($live | map({key: .name, value: (.params | sort)}) | from_entries) as $liveMap
    | ($b.tools // {}) as $baselineMap
    | ($liveMap | keys) as $liveNames
    | ($baselineMap | keys) as $baselineNames
    | ($liveNames - $baselineNames) as $toolsServerOnly
    | ($baselineNames - $liveNames) as $toolsBaselineOnly
    | (
        [$liveNames[] as $t | select($baselineMap | has($t))
          | (($liveMap[$t] // []) - ($baselineMap[$t] // [])) as $extra
          | select(($extra | length) > 0)
          | {tool: $t, params: $extra}
        ]
      ) as $paramsServerOnly
    | (
        [$baselineNames[] as $t | select($liveMap | has($t))
          | (($baselineMap[$t] // []) - ($liveMap[$t] // [])) as $extra
          | select(($extra | length) > 0)
          | {tool: $t, params: $extra}
        ]
      ) as $paramsBaselineOnly
    | {
        toolsServerOnly: $toolsServerOnly,
        toolsBaselineOnly: $toolsBaselineOnly,
        paramsServerOnly: $paramsServerOnly,
        paramsBaselineOnly: $paramsBaselineOnly
      }
    | (($toolsServerOnly | length) + ($toolsBaselineOnly | length) + ($paramsServerOnly | length) + ($paramsBaselineOnly | length)) as $total
    | if $total == 0 then empty else . end
    ' 2>/dev/null)

  if [ -z "$report" ]; then
    echo "refresh-arknet-baseline --check: no drift -- server and baseline agree ($tool_count tools)."
    exit 0
  fi

  echo "refresh-arknet-baseline --check: drift between the live server and $BASELINE"
  echo "$report" | jq -r '
    (.toolsServerOnly // [] | map("  tool on server, not in baseline: " + .) | .[]),
    (.toolsBaselineOnly // [] | map("  tool in baseline, not on server: " + .) | .[]),
    (.paramsServerOnly // [] | map("  " + .tool + ": param(s) on server, not in baseline: " + (.params | join(", "))) | .[]),
    (.paramsBaselineOnly // [] | map("  " + .tool + ": param(s) in baseline, not on server: " + (.params | join(", "))) | .[])
  '
  exit 1
fi

# Write mode: build the baseline file. Each tool renders as one compact,
# single-line JSON array (via jq's tojson) so the whole tool list stays
# git-diff-friendly -- a changed tool touches exactly one line.
tools_lines=$(printf '%s' "$live_tools" | jq -r '
  sort_by(.name)
  | map("    " + (.name | tojson) + ": " + (.params | sort | tojson))
  | join(",\n")
')

tmp_out=$(mktemp) || exit 1
{
  printf '{\n'
  printf '  "serverInfo": {\n'
  printf '    "name": %s,\n' "$(printf '%s' "$server_name" | jq -R .)"
  printf '    "version": %s\n' "$(printf '%s' "$server_version" | jq -R .)"
  printf '  },\n'
  printf '  "tools": {\n'
  printf '%s\n' "$tools_lines"
  printf '  }\n'
  printf '}\n'
} > "$tmp_out"

if ! jq empty "$tmp_out" 2>/dev/null; then
  echo "refresh-arknet-baseline: generated baseline is not valid JSON, aborting" >&2
  rm -f "$tmp_out"
  exit 1
fi

param_count=$(jq '[.tools[] | length] | add // 0' "$tmp_out")
mv "$tmp_out" "$BASELINE"
echo "refresh-arknet-baseline: wrote $BASELINE ($tool_count tools, $param_count parameters) against $server_name $server_version"
