#!/usr/bin/env bash
# Stop hook: nudges once per session that a store-writing arknet MCP tool
# was called and the project holds an export snapshot that is probably
# stale now. Never the reason a session fails to stop -- any failure here
# (missing jq, malformed input, no transcript, no snapshot) exits silently
# instead of surfacing an error or blocking the stop.
set -u

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat) || exit 0
[ -n "$input" ] || exit 0

stop_hook_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null) || exit 0
[ "$stop_hook_active" = "true" ] && exit 0

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null) || exit 0
transcript_path=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null) || exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null) || exit 0

[ -n "$session_id" ] || exit 0
[ -n "$transcript_path" ] || exit 0
[ -f "$transcript_path" ] || exit 0
[ -n "$cwd" ] || exit 0
[ -d "$cwd" ] || exit 0

# Store-writing arknet tool names. MCP tool names are
# "mcp__<server>__<tool>" -- the server segment varies per installation
# (e.g. "arknet", "plugin_arknet_arknet"), so match on the tool suffix
# only. Kept in sync with the write-tool families used across the shipped
# skills (adr/req/uc/term/bc/constraint/actor/project).
WRITE_TOOL_REGEX='^mcp__[A-Za-z0-9_]+__(adr_(add|update|delete|set_status|supersede)|req_(add|update|set_status|link_[a-z_]+)|uc_(add|update|link_[a-z_]+)|term_(add|update|delete)|bc_(add|link_[a-z_]+)|constraint_(add|update)|actor_(add|update|delete)|project_(add|adopt|attach_anchor|rename|update))$'

# Read the transcript line by line rather than as one multi-document jq
# input -- fromjson? turns a malformed line into `empty` instead of
# aborting the whole scan, so one bad line can't hide a real match earlier
# or later in the file.
wrote=$(jq -R -r --arg re "$WRITE_TOOL_REGEX" '
  fromjson?
  | select(.type == "assistant")
  | .message.content[]?
  | select(.type == "tool_use")
  | .name
  | select(test($re))
' "$transcript_path" 2>/dev/null | head -1) || exit 0
[ -n "$wrote" ] || exit 0

# Discover an export snapshot: a directory holding at least one .trig file
# (a project_export full dump), outside target/, node_modules/, .git/,
# bounded search depth so this stays cheap in a large working tree.
snapshot_dir=$(find "$cwd" -maxdepth 4 \
  \( -path '*/target' -o -path '*/node_modules' -o -path '*/.git' \) -prune -o \
  -type f -name '*.trig' -print 2>/dev/null | head -1 | xargs -r dirname) || exit 0
[ -n "$snapshot_dir" ] || exit 0

# Once per session: a marker file named after the session id.
marker="${TMPDIR:-/tmp}/arknet-export-freshness-nudge-${session_id}"
[ -e "$marker" ] && exit 0
: > "$marker" 2>/dev/null || exit 0

jq -n --arg msg "arknet store was written this session and $snapshot_dir holds an export snapshot that is probably stale now -- regenerate it before committing." \
  '{systemMessage: $msg}' 2>/dev/null

exit 0
