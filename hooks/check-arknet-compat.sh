#!/usr/bin/env bash
# SessionStart hook: warns if the connected arknet MCP server is missing a
# tool a shipped skill needs (see hooks/required-tools.json). Has no dedup
# of its own -- the matcher in hooks/hooks.json bounds how often it runs
# (startup, resume, clear), so a /clear repeats the warning on purpose,
# the emptied context no longer carrying the earlier one.
# Never the reason a session fails to start -- any failure here (missing
# curl/jq, unreachable server, malformed response) exits silently instead
# of surfacing an error.
set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MCP_CONFIG="$PLUGIN_ROOT/.mcp.json"
REQUIREMENTS="$PLUGIN_ROOT/hooks/required-tools.json"

command -v curl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[ -f "$MCP_CONFIG" ] || exit 0
[ -f "$REQUIREMENTS" ] || exit 0

url=$(jq -r '.mcpServers.arknet.url // empty' "$MCP_CONFIG" 2>/dev/null)
[ -n "$url" ] || exit 0

headers=$(mktemp) || exit 0
trap 'rm -f "$headers"' EXIT

curl -s -m 3 -X POST "$url" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"arknet-plugin-compat-check","version":"1"}}}' \
  -D "$headers" -o /dev/null || exit 0

# Streamable HTTP transport: tools/list needs the session id the server
# handed back on initialize.
session_id=$(sed -n 's/^[Mm]cp-[Ss]ession-[Ii]d:[[:space:]]*//p' "$headers" | tr -d '\r\n')
[ -n "$session_id" ] || exit 0

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

live_tools_json=$(printf '%s' "$tools_json" | jq -c '[.result.tools[]?.name]' 2>/dev/null)
[ -n "$live_tools_json" ] && [ "$live_tools_json" != "null" ] || exit 0

jq -n \
  --argjson required "$(cat "$REQUIREMENTS")" \
  --argjson live "$live_tools_json" \
  '
  ($required | to_entries
    | map({skill: .key, missing: (.value - $live)})
    | map(select(.missing | length > 0))
  ) as $affected
  | if ($affected | length) == 0 then empty else
    {
      hookSpecificOutput: {
        hookEventName: "SessionStart",
        additionalContext: (
          "arknet compatibility check: the connected arknet MCP server is missing tool(s) that some installed skills need:\n"
          + ($affected | map("- " + .skill + " needs: " + (.missing | join(", "))) | join("\n"))
          + "\n\nThese skills may fail or behave unexpectedly until the arknet-mcp daemon is updated."
        )
      }
    }
  end
  '
exit 0
