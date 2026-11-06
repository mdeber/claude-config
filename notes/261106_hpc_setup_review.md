# 261106 — Claude Code on the PNI HPC: review of config, template, and loop design
agent: Claude Code (Fable 5.1) · human: Mike · status: PROPOSAL, nothing applied yet

## Verified facts (this session)
- Scratch: /jukebox/scratch/md6347 = /mnt/bucket/scratch/md6347 (separate FS from lab dirs).
  Holds envs/, pkgs/, tools/pni-project-template (git, 1 commit "template v0", no remote).
- The desktop app ships a full Claude Code CLI to scotty: ~/.claude/remote/ccd-cli/<ver> (2.1.317).
  Standalone it reports "Not logged in" — auth is bridged from the laptop. `claude auth login`
  exists for a one-time standalone login. This version has --max-budget-usd, --permission-mode,
  --allowedTools, --append-system-prompt; no --max-turns in --help.
- Claude memory is per working directory: ~/.claude/projects/<cwd-slug>/memory/. A memory
  written in claude-test does not load in a template project. Lab-wide rules therefore belong in
  CLAUDE.md / rules/method.md, not memory. Memory dirs are tracked in the ~/.claude repo.
- Template is consistent with method.md. "Fails twice → stop" appears in three files.
- No `gh`, no SSH keys, no GitHub auth on scotty.

## 1. Deletes — layered, strongest first
1. Filesystem: raw-data directories read-only (chmod a-w). Only layer that also covers deletes
   from inside scripts, R, Python, rsync. Mike's action; Claude never chmods.
2. Git for code/docs (template already commits per session; ~/.claude now a repo).
3. Audit: PreToolUse hook on Bash appends timestamp/cwd/command to ~/.claude/logs/bash.log.
   Nothing is quiet.
4. Block: same hook scans the WHOLE command string for rm -r/-R/--recursive, find -delete,
   rsync --delete, git clean / reset --hard / push --force, shred → exit 2 (blocked, Claude sees
   why). This closes the tmux/conda-run/awk wrapper hole without adding prompts; the allow list
   stays as is. settings.json `deny` gets the prefix forms too (declarative, survives hook errors).
   Deny holds regardless of mode; `ask` only protects while someone is there to answer.
5. method.md Code: scripts never delete; they write to out/ and overwrite only their own outputs.
Not doing: moving tmux/conda run/awk to ask (Mike: not a concern; costs prompts for things
CLAUDE.md asks for).

## 2. NFS traversal — keep the bound, drop the ladder
The numeric ladder (3 default / >4 needs reason / never 10+) came from one session's failures.
What matters: bounded (`timeout 60`, `-maxdepth`), pruned dep trees, shallow-then-narrow, one
top dir at a time, never unbounded. Three lines. Delete the "narrow it don't scale it" section —
method.md "When stuck" already says it; keep only "Slurm is not a way to make a slow walk finish".

## 3. Scotty vs Slurm — one decidable rule
Current 8 cores / 64 GB is wrong by Mike's account. Proposed (numbers are DEFAULTS for Mike to set):
  Scotty: interactive; < ~2 h and < ~100 GB; anything that must outlive the session (tmux, never
  foreground); watchers/launchers. Leave headroom (`uptime`). > ~300 GB fails; >100 GB for hours or
  anything for days gets killed.
  Slurm: longer, bigger, GPU, sweeps, or anything whose loss to a kill would hurt — written sbatch.
  Tiebreak: queue backed up and it fits scotty → scotty. Stop deliberating there.
"Never run long work in-session" becomes "never in the session foreground".

## 4. tmux loops — bring Claude back when a job finishes
- Chain compute with `sbatch --dependency=afterok:<jobid>` (native, no watcher).
- Watcher only to re-enter Claude: tmux `cc-watch-<jobid>` runs
  code/pipeline/continue_after.sh <jobid> <stage>: poll squeue every 5 min → sacct state →
  `claude -p "<continuation prompt>" --permission-mode acceptEdits --max-budget-usd N`
  in the project root, transcript to scratch/claude_runs/<jobid>_<stage>.log (gitignored).
- Continuation prompt = the template's session protocol: check outputs vs plan.md "done when",
  write log entry (mode: unattended), update STATUS, commit. v1: PREPARE the next sbatch, do not
  submit. Stop at any decision criterion that needs Mike. Human submits in the morning.
- v2 (later, if v1 earns trust): allow sbatch inside a stage chain via --allowedTools.
- Prereqs (Mike): stable `claude` on PATH (install to ~/.local/bin or scratch/tools/bin; the
  ccd-cli path is version-hashed) and one `claude auth login` on scotty.
- Transparency: log header gains `mode: interactive | unattended`; every unattended run is a
  log entry + a transcript file; STATUS says it was unattended.

## 5. Memory vs logs — three records, three jobs (→ method.md)
  docs/ in the project: everything about the work. Git. Auditable by anyone.
  ~/.claude (CLAUDE.md, rules/): how Mike wants Claude to work everywhere. Its own git repo.
  Claude memory (per project dir): preferences, feedback, environment quirks no repo records.
  Never a result, a decision, or the reasoning behind one.
  Test: if a memory file vanished, no result would become unexplained.
MEMORY.md "missing" is expected: each project dir starts empty. Earlier memories written this
session are scoped to claude-test; the method.md edit (c779f25) is what carries.

## Template follow-ups (its own repo, separate commit)
- docs/log/README.md header: add `mode: interactive | unattended`.
- code/pipeline/continue_after.sh (above) + one "Unattended continuation" paragraph in CLAUDE.md.
- Drop the duplicated "fails twice" line (method.md owns it).
- Template has no remote and lives in scratch: same single-copy risk as ~/.claude had.

## Open for Mike
1. Scotty defaults: ~2 h / ~100 GB — confirm or replace.
2. Raw data read-only: do it? (I can list the dirs; I will not run chmod.)
3. Loop v1 = verify, log, commit, prepare-not-submit. OK?
4. Install standalone `claude` + `claude auth login` on scotty (your action).
5. Is /jukebox/scratch purged on a schedule? (envs and the template live there.)

## 261106 update — Mike's corrections
- DECISION: scotty rule = memory ceiling ~300 GB; prefer spock when actual compute > ~30 min
  (simply faster there) and for GPU (scotty has GPU; spock is faster). Processes may run for days
  and use high memory; under 100 GB is safe indefinitely. The kill risk is an idle high-memory
  process held for days (a 200 GB object in a tmux R/Python session nobody touches), not runtime
  or memory per se. Replaces the 8-core/64 GB budget and my 2 h/100 GB draft.
- DECISION: permissions on PNI are open and inherit from the lab dirs. Never make files
  user-private (no chmod 600/700, no umask 077).
- DECISION: no blanket raw-data chmod. The rule is judgment: never modify irreplaceable data in
  place; read-only is good practice when the task won't write there; ask before writing into a
  directory you didn't create.
- DECISION: extended autonomy is a mode entered only when Mike asks. In it Claude may submit
  jobs and iterate for days (research → plan → implement → run → analyze → rethink → rerun →
  report), under the template protocol and git. So v1 allows sbatch inside the loop, not
  prepare-only; plan decision points still stop unless the goal names which Claude may take.
- DECISION: make the standalone login work (claude on scotty + `claude auth login`).
- Still open: is /jukebox/scratch purged on a schedule?
