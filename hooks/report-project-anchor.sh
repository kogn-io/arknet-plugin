#!/usr/bin/env bash
# SessionStart hook: reports which registered arknet project (if any) the
# current directory resolves to as an anchor, so a session opened in a git
# worktree or a second checkout notices the missing ANCHOR rather than
# guessing it needs a new PROJECT. Separate from hooks/check-arknet-compat.sh
# on purpose -- that hook warns about server/plugin drift, this one reports
# routing information, and the two have different reasons to repeat.
#
# No once-per-session marker (unlike hooks/export-freshness-nudge.sh): /clear
# keeps the same session_id, and the whole point of this report is that it
# is orientation information the session may no longer be carrying in
# context after a /clear or a compaction summary -- a marker would silence
# exactly the repeats that matter. The matcher in hooks/hooks.json
# (startup|resume|clear|compact) is what bounds how often this runs;
# "fork" is left out because a forked session still carries the context
# that had the report in it.
#
# Never the reason a session fails to start -- any failure here (missing
# curl/jq, no .mcp.json, unreachable server, malformed response, isError in
# the tool result) exits silently instead of surfacing an error.
set -u

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MCP_CONFIG="$PLUGIN_ROOT/.mcp.json"

command -v curl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[ -f "$MCP_CONFIG" ] || exit 0

input=$(cat) 2>/dev/null
cwd=""
if [ -n "$input" ]; then
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
fi
# Trim surrounding whitespace, whatever the source.
cwd=$(printf '%s' "${cwd:-}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
[ -n "$cwd" ] || cwd="$PWD"
[ -n "$cwd" ] || exit 0

url=$(jq -r '.mcpServers.arknet.url // empty' "$MCP_CONFIG" 2>/dev/null)
[ -n "$url" ] || exit 0

headers=$(mktemp) || exit 0
init_body=$(mktemp) || exit 0
trap 'rm -f "$headers" "$init_body"' EXIT

curl -s -m 3 -X POST "$url" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"arknet-plugin-anchor-report","version":"1"}}}' \
  -D "$headers" -o "$init_body" || exit 0

# Streamable HTTP transport: tools/call needs the session id the server
# handed back on initialize.
session_id=$(sed -n 's/^[Mm]cp-[Ss]ession-[Ii]d:[[:space:]]*//p' "$headers" | tr -d '\r\n')
[ -n "$session_id" ] || exit 0

curl -s -m 3 -X POST "$url" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "Mcp-Session-Id: $session_id" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' -o /dev/null

# project_list takes no arguments and needs no anchor header -- it is the
# list of all registered projects and their anchors, not a lookup scoped to
# this directory.
list_response=$(curl -s -m 3 -X POST "$url" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "Mcp-Session-Id: $session_id" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"project_list","arguments":{}}}') || exit 0

# The server answers as one SSE frame ("data: {...}") rather than a bare
# JSON body -- strip that framing if present, use the body as-is otherwise.
list_json=$(printf '%s\n' "$list_response" | sed -n 's/^data://p')
[ -n "$list_json" ] || list_json="$list_response"

is_error=$(printf '%s' "$list_json" | jq -r '.result.isError // false' 2>/dev/null)
[ "$is_error" = "false" ] || exit 0

list_text=$(printf '%s' "$list_json" | jq -r '.result.content[]? | select(.type=="text") | .text' 2>/dev/null)
[ -n "$list_text" ] || exit 0

# Parse project_list's line-oriented text. One line per project, stopping
# at the "# Unregistered datasets" section header:
#   <label> [<anchor1> (path), <anchor2> (uuid), ...] (id: <id>) - <optional description> [...]
# label = everything before the FIRST " [". The anchor list = between that
# first " [" and the FIRST following "]". An item is a path anchor when it
# ends with " (path)"; its value is the part before that suffix. Compare
# path-anchor values exactly to cwd (the server matches by exact string,
# no prefix/path normalisation) -- but also, as a hint only, note a listed
# path anchor that is a strict parent directory of cwd.
resolved_label=""
parent_anchor=""
parent_label=""

while IFS= read -r line; do
  [ -n "$line" ] || continue
  case "$line" in
    "# Unregistered datasets"*) break ;;
  esac
  case "$line" in
    *" ["*"]"*) ;;
    *) continue ;;
  esac

  label="${line%% [*}"
  rest="${line#*" ["}"
  anchor_list="${rest%%]*}"

  IFS=',' read -ra anchor_items <<< "$anchor_list"
  for raw_item in "${anchor_items[@]}"; do
    item=$(printf '%s' "$raw_item" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    case "$item" in
      *" (path)")
        path_value="${item% (path)}"
        if [ "$path_value" = "$cwd" ]; then
          resolved_label="$label"
        elif [ -z "$resolved_label" ] && [ -z "$parent_anchor" ]; then
          case "$cwd" in
            "$path_value"/*)
              parent_anchor="$path_value"
              parent_label="$label"
              ;;
          esac
        fi
        ;;
    esac
  done
  [ -n "$resolved_label" ] && break
done <<EOF
$list_text
EOF

if [ -n "$resolved_label" ]; then
  context="arknet project anchor: this directory $cwd resolves to project \"$resolved_label\" -- arknet tool calls from this session read and write that project's model."
else
  context="arknet project anchor: no registered arknet project has $cwd as an anchor, so arknet tool calls from this session have no project and will be rejected. If this is a git worktree or a second checkout of a project that is already registered, do NOT call project_add (it would silently create a second project and there is no project_delete) -- run /arknet:init, which picks between project_attach_anchor, project_adopt and project_add."
  if [ -n "$parent_anchor" ]; then
    context="$context
A parent directory, $parent_anchor, is registered as an anchor of project \"$parent_label\" -- you may have started in a subdirectory of it."
  fi
fi

jq -n --arg text "$context" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $text}}'
exit 0
