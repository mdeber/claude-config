#!/usr/bin/env bash
# ------------------------------------------------------------------
# bash-guard.sh — PreToolUse hook for Claude Code's Bash tool.
# 1. Appends every command to ~/.claude/logs/bash.log  (time <tab> cwd <tab> command).
# 2. Denies recursive/forced deletes and history-rewriting git (incl. +refspec pushes) wherever they appear in the
#    command string, so wrappers (tmux, conda run, xargs, bash -c) don't bypass it.
#    Mike runs those himself.
# Input : hook JSON on stdin.  Output: nothing (allow) or a permissionDecision deny (block).
# Test  : echo '{"tool_input":{"command":"rm -rf x"}}' | ~/.claude/hooks/bash-guard.sh
# written: 261106  by: Claude Code / Mike
# ------------------------------------------------------------------
input=$(cat)
cmd=$(printf '%s' "$input" | /usr/bin/jq -r '.tool_input.command // empty' 2>/dev/null)
cwd=$(printf '%s' "$input" | /usr/bin/jq -r '.cwd // empty' 2>/dev/null)
mkdir -p "$HOME/.claude/logs"
printf '%s\t%s\t%s\n' "$(date +%FT%T)" "${cwd:-$PWD}" "${cmd//$'\n'/ }" >> "$HOME/.claude/logs/bash.log"

q="'"
pre="(^|[[:space:];&|\`(\"$q])"
pat="${pre}rm[[:space:]]+(-[[:alnum:]]*[rR]|--recursive)"
pat="$pat|${pre}find[[:space:]].*-delete"
pat="$pat|${pre}rsync[[:space:]].*--delete"
pat="$pat|${pre}git[[:space:]]+(clean|reset[[:space:]]+--hard|push[[:space:]].*(--force|-f([[:space:]]|$)))"
pat="$pat|${pre}(shred|truncate)[[:space:]]"
pat="$pat|${pre}git[[:space:]]+push[[:space:]]([^;&|]*[[:space:]])?\+[^[:space:]]"   # +refspec = force push
if printf '%s' "$cmd" | grep -Eq -- "$pat"; then
  /usr/bin/jq -n --arg r "bash-guard: recursive/forced delete or git history rewrite. Mike runs these himself; ask him. (~/.claude/hooks/bash-guard.sh)" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
fi
exit 0
