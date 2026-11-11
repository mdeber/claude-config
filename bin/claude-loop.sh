#!/usr/bin/env bash
# ------------------------------------------------------------------
# claude-loop.sh — run Claude unattended on one goal in a template project,
#                  re-entering after every Slurm wait. Only when the user asks for it.
# usage   : cd <project root>
#           tmux new-session -d -s cc-loop-<project> \
#             '~/.claude/bin/claude-loop.sh "<goal>" | --goal-file <path>  [--max-iter N] [--max-days D] [--budget USD] [--model M] [--allow-dirty]'
#           A goal file (multi-paragraph, kept in scratch/loop/ or committed in docs/) is the normal form.
# state   : scratch/loop/state — ONE line, written by Claude at the end of each iteration:
#             WAITING <jobid> [<jobid>...]   jobs submitted; re-enter when they all finish
#             CONTINUE                        more to do now; re-enter immediately
#             DONE                            goal reached
#             NEEDS_USER <one line why>       stop; a decision is the user's
# outputs : scratch/loop/iter_<n>.jsonl (full transcript: every tool call and result, for audit),
#           scratch/loop/iter_<n>.log (the iteration's final report), scratch/loop/driver.log
# env     : ~/.claude/bin/claude (or CLAUDE_BIN), logged in standalone once (`claude auth login`)
#           CLAUDE_LOOP_PERMISSION_MODE (default auto: the classifier reviews every action, subagents
#           included, and anything that would prompt is denied; the bash-guard hook and deny/ask rules
#           apply in every mode. bypassPermissions skips the classifier.)
#           CLAUDE_LOOP_POLL seconds between squeue checks (default 60)
#           CLAUDE_LOOP_MODEL or --model: model for every iteration (default opus). Pinned because the
#           CLI default changed between iterations of one run (261110); the model used is logged.
# budget  : --budget is checked after each turn, so one turn can overshoot it (cap 0.05 -> spent 0.14).
#           It includes subagent cost.
# note    : sacct is often unreachable from scotty; jobs are judged by their <jobid>.exit marker
#           and outputs (code/README.md), not by accounting.
# written : 261106  by: Claude Code / Mike
# ------------------------------------------------------------------
set -uo pipefail

GOAL=""; MAX_ITER=20; MAX_DAYS=3; BUDGET=10; ALLOW_DIRTY=0; MODEL=${CLAUDE_LOOP_MODEL:-opus}
while [ $# -gt 0 ]; do
  case $1 in
    --goal-file)   GOAL=$(cat "$2"); shift 2 ;;
    --max-iter)    MAX_ITER=$2; shift 2 ;;
    --max-days)    MAX_DAYS=$2; shift 2 ;;
    --budget)      BUDGET=$2;   shift 2 ;;
    --model)       MODEL=$2;    shift 2 ;;
    --allow-dirty) ALLOW_DIRTY=1; shift ;;
    -*) echo "unknown argument: $1" >&2; exit 2 ;;
    *)  GOAL=$1; shift ;;
  esac
done
[ -n "$GOAL" ] || { echo 'usage: claude-loop.sh "<goal>" | --goal-file <path>  [--max-iter N] [--max-days D] [--budget USD] [--model M] [--allow-dirty]' >&2; exit 2; }
CLAUDE=${CLAUDE_BIN:-$HOME/.claude/bin/claude}
PERM=${CLAUDE_LOOP_PERMISSION_MODE:-auto}
POLL=${CLAUDE_LOOP_POLL:-60}

[ -f CLAUDE.md ] && [ -d docs ] && [ -d .git ] || { echo "run from a project root (needs CLAUDE.md, docs/, .git)" >&2; exit 2; }
command -v "$CLAUDE" >/dev/null || { echo "claude not on PATH (set CLAUDE_BIN)" >&2; exit 2; }
if [ "$ALLOW_DIRTY" = 0 ] && [ -n "$(git status --porcelain)" ]; then
  echo "working tree is dirty; commit first or pass --allow-dirty" >&2; exit 2
fi

mkdir -p scratch/loop
STATE=scratch/loop/state
LOG=scratch/loop/driver.log
[[ $MAX_DAYS =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "--max-days must be a number (fractions allowed)" >&2; exit 2; }
DEADLINE=$(awk -v d="$MAX_DAYS" -v n="$(date +%s)" 'BEGIN { printf "%d", n + d * 86400 }')
log() { printf '%s\t%s\n' "$(date +%FT%T)" "$*" | tee -a "$LOG"; }

# The stored login refreshes itself, but its refresh token has a fixed end date; past it, the next
# iteration fails at startup (rc != 0, no state) and the driver stops. Refuse to start if the run could reach it.
rexp=$(/usr/bin/jq -r '.claudeAiOauth.refreshTokenExpiresAt // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
if [ -n "$rexp" ] && [ "$DEADLINE" -gt $(( rexp / 1000 )) ]; then
  echo "refusing: login expires $(date -d @$(( rexp / 1000 )) +%FT%T), before --max-days ends. Run 'claude auth login' (or shorten --max-days) and relaunch." >&2; exit 2
fi
log "start goal=\"$GOAL\" max_iter=$MAX_ITER max_days=$MAX_DAYS budget=$BUDGET model=$MODEL perm=$PERM"
PROMPT="GOAL: $GOAL"
for i in $(seq 1 "$MAX_ITER"); do
  [ "$(date +%s)" -lt "$DEADLINE" ] || { log "stop: max-days reached"; exit 1; }
  rm -f "$STATE"
  PROTOCOL="You are running UNATTENDED inside claude-loop.sh (iteration $i of $MAX_ITER; budget \$$BUDGET this iteration). Follow this project's CLAUDE.md session protocol and its 'Extended autonomy' section. Work toward the goal below; submit Slurm jobs with sbatch when compute is needed. Before you stop you MUST: (1) write docs/log/<YYMMDD_HHMM>_<topic>.md with 'mode: unattended' in its header, (2) overwrite docs/STATUS.md, (3) git add and commit, (4) write exactly one line to $STATE: 'WAITING <jobids>' if you submitted jobs and need their results, 'CONTINUE' if there is more to do now, 'DONE' if the goal is reached, or 'NEEDS_USER <why>' at any plan decision point or anything irreversible. Never delete data or outputs. Never modify irreplaceable raw data. If the permission layer or the auto-mode classifier denies or blocks a command, do NOT route around it (no bash -c, no wrapper script, no other tool for the same effect): note the denial in the log entry and, if it blocks the goal, stop with NEEDS_USER."
  log "iter $i start"
  "$CLAUDE" -p "$PROTOCOL

$PROMPT" --model "$MODEL" --permission-mode "$PERM" --max-budget-usd "$BUDGET" --output-format stream-json --verbose \
    < /dev/null > "scratch/loop/iter_$i.jsonl" 2> "scratch/loop/iter_$i.err"
  rc=$?
  /usr/bin/jq -r 'select(.type=="result") | .result // empty' "scratch/loop/iter_$i.jsonl" > "scratch/loop/iter_$i.log" 2>/dev/null
  used=$(/usr/bin/jq -r 'select(.type=="system" and .subtype=="init") | "\(.model) mode=\(.permissionMode)"' "scratch/loop/iter_$i.jsonl" 2>/dev/null | head -1)
  meta=$(/usr/bin/jq -r 'select(.type=="result") | "end=\(.subtype // "?") cost_usd=\(.total_cost_usd // "?") turns=\(.num_turns // "?") session=\(.session_id // "?")"' "scratch/loop/iter_$i.jsonl" 2>/dev/null | tail -1)
  state=MISSING; rest=""
  [ -f "$STATE" ] && read -r state rest < "$STATE"
  log "iter $i end rc=$rc state=$state $rest model=${used:-?} $meta"
  case $state in
    WAITING)
      [ -n "$rest" ] || { log "stop: WAITING with no job ids"; exit 1; }
      for j in $rest; do
        last=""
        while st=$(squeue -h -j "$j" -o '%T' 2>/dev/null) && [ -n "$st" ]; do
          last=$st
          [ "$(date +%s)" -lt "$DEADLINE" ] || { log "stop: max-days reached while job $j is $st (the job keeps running)"; exit 1; }
          sleep "$POLL"
        done
        log "job $j left the queue (last seen: ${last:-never in queue})"
      done
      summary=$(sacct -X -n -j "${rest// /,}" -o JobID,JobName%30,State,Elapsed,MaxRSS 2>/dev/null)
      [ -n "$summary" ] || summary="(sacct unavailable from scotty: judge each job by its <jobid>.exit marker and its outputs)"
      log "jobs finished: $(printf '%s' "$summary" | tr -s ' \n' ' ')"
      PROMPT="GOAL: $GOAL

The Slurm jobs you were waiting on have finished:
$summary

Check their outputs against the plan stage's 'done when', then continue." ;;
    CONTINUE)
      PROMPT="GOAL: $GOAL

Continue from docs/STATUS.md." ;;
    DONE|NEEDS_USER)
      log "stop: $state $rest"; exit 0 ;;
    *)
      log "stop: no valid state written (rc=$rc)"; exit 1 ;;
  esac
done
log "stop: max-iter reached"; exit 1
