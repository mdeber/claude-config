#!/usr/bin/env bash
# ------------------------------------------------------------------
# claude-loop.sh — run Claude unattended on one goal in a template project,
#                  re-entering after every Slurm wait. Only when Mike asks for it.
# usage   : cd <project root>
#           tmux new-session -d -s cc-loop-<project> \
#             '~/.claude/bin/claude-loop.sh "<goal>" [--max-iter N] [--max-days D] [--budget USD] [--allow-dirty]'
# state   : scratch/loop/state — ONE line, written by Claude at the end of each iteration:
#             WAITING <jobid> [<jobid>...]   jobs submitted; re-enter when they all finish
#             CONTINUE                        more to do now; re-enter immediately
#             DONE                            goal reached
#             NEEDS_MIKE <one line why>       stop; a decision is Mike's
# outputs : scratch/loop/iter_<n>.log (transcripts), scratch/loop/driver.log
# env     : claude on PATH (or CLAUDE_BIN), logged in standalone once (`claude auth login`)
#           CLAUDE_LOOP_PERMISSION_MODE (default bypassPermissions; the bash-guard hook still applies)
# written : 261106  by: Claude Code / Mike
# ------------------------------------------------------------------
set -uo pipefail

GOAL=${1:?usage: claude-loop.sh "<goal>" [--max-iter N] [--max-days D] [--budget USD] [--allow-dirty]}; shift
MAX_ITER=20; MAX_DAYS=3; BUDGET=10; ALLOW_DIRTY=0
while [ $# -gt 0 ]; do
  case $1 in
    --max-iter)    MAX_ITER=$2; shift 2 ;;
    --max-days)    MAX_DAYS=$2; shift 2 ;;
    --budget)      BUDGET=$2;   shift 2 ;;
    --allow-dirty) ALLOW_DIRTY=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
CLAUDE=${CLAUDE_BIN:-claude}
PERM=${CLAUDE_LOOP_PERMISSION_MODE:-bypassPermissions}

[ -f CLAUDE.md ] && [ -d docs ] && [ -d .git ] || { echo "run from a project root (needs CLAUDE.md, docs/, .git)" >&2; exit 2; }
command -v "$CLAUDE" >/dev/null || { echo "claude not on PATH (set CLAUDE_BIN)" >&2; exit 2; }
if [ "$ALLOW_DIRTY" = 0 ] && [ -n "$(git status --porcelain)" ]; then
  echo "working tree is dirty; commit first or pass --allow-dirty" >&2; exit 2
fi

mkdir -p scratch/loop
STATE=scratch/loop/state
LOG=scratch/loop/driver.log
DEADLINE=$(( $(date +%s) + MAX_DAYS * 86400 ))
log() { printf '%s\t%s\n' "$(date +%FT%T)" "$*" | tee -a "$LOG"; }

log "start goal=\"$GOAL\" max_iter=$MAX_ITER max_days=$MAX_DAYS budget=$BUDGET perm=$PERM"
PROMPT="GOAL: $GOAL"
for i in $(seq 1 "$MAX_ITER"); do
  [ "$(date +%s)" -lt "$DEADLINE" ] || { log "stop: max-days reached"; exit 1; }
  rm -f "$STATE"
  PROTOCOL="You are running UNATTENDED inside claude-loop.sh (iteration $i of $MAX_ITER; budget \$$BUDGET this iteration). Follow this project's CLAUDE.md session protocol and its 'Extended autonomy' section. Work toward the goal below; submit Slurm jobs with sbatch when compute is needed. Before you stop you MUST: (1) write docs/log/<YYMMDD_HHMM>_<topic>.md with 'mode: unattended' in its header, (2) overwrite docs/STATUS.md, (3) git add and commit, (4) write exactly one line to $STATE: 'WAITING <jobids>' if you submitted jobs and need their results, 'CONTINUE' if there is more to do now, 'DONE' if the goal is reached, or 'NEEDS_MIKE <why>' at any plan decision point or anything irreversible. Never delete data or outputs. Never modify irreplaceable raw data."
  log "iter $i start"
  "$CLAUDE" -p "$PROTOCOL

$PROMPT" --permission-mode "$PERM" --max-budget-usd "$BUDGET" > "scratch/loop/iter_$i.log" 2>&1
  rc=$?
  state=MISSING; rest=""
  [ -f "$STATE" ] && read -r state rest < "$STATE"
  log "iter $i end rc=$rc state=$state $rest"
  case $state in
    WAITING)
      [ -n "$rest" ] || { log "stop: WAITING with no job ids"; exit 1; }
      for j in $rest; do
        while squeue -h -j "$j" 2>/dev/null | grep -q .; do sleep 300; done
      done
      summary=$(sacct -X -n -j "${rest// /,}" -o JobID,JobName%30,State,Elapsed,MaxRSS 2>/dev/null)
      log "jobs finished: $(printf '%s' "$summary" | tr -s ' \n' ' ')"
      PROMPT="GOAL: $GOAL

The Slurm jobs you were waiting on have finished:
$summary

Check their outputs against the plan stage's 'done when', then continue." ;;
    CONTINUE)
      PROMPT="GOAL: $GOAL

Continue from docs/STATUS.md." ;;
    DONE|NEEDS_MIKE)
      log "stop: $state $rest"; exit 0 ;;
    *)
      log "stop: no valid state written (rc=$rc)"; exit 1 ;;
  esac
done
log "stop: max-iter reached"; exit 1
