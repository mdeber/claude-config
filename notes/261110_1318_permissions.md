# Fewer permission prompts on scotty · mode: interactive · human: Mike

## Evidence
- `permissions.defaultMode` was unset, so every new session started in manual mode and asked for any
  command not on the allow list. That was the main source of prompts.
- 13 recent transcripts, 134 Bash calls (mostly this setup work, so a thin sample): reads (cat, ls,
  grep, git status/log/diff) dominate but never prompt; prompts come from writes: git commit/add (55),
  python3 (28), mkdir (22), sed -i, heredoc writes, git push (10).
- Docs (code.claude.com permissions, permission-modes, auto-mode-config; fetched 261110): rules are
  checked deny → ask → allow, first match wins, specificity ignored. So the `chmod +x` allow added
  261106 never took effect while `chmod*` was in ask, and an `mv -n` exception cannot be expressed.
  `autoMode.*` arrays replace the built-ins unless they contain "$defaults". In auto mode, broad
  interpreter allow rules are suspended and narrow ones still skip the classifier.

## DECISION: auto mode is the default (Mike, 261110)
`permissions.defaultMode: "auto"`. The classifier approves routine work and blocks risky actions;
the ask list is what still always prompts.

## DECISION: describe this machine to the classifier
`autoMode.environment` = $defaults + five entries: PNI HPC research use, trusted storage paths,
Slurm/tmux as routine, github.com/mdeber as trusted source control, irreplaceable data. Verified with
`claude auto-mode config` (26 environment entries, 72 soft_deny intact). The built-in "Primary use:
software development" line remains beside ours; dropping $defaults would lose the trust definitions.

## DECISION: allow and ask lists
- allow +: mkdir, git add, git commit, git push (force forms stay denied by rules and hook).
- allow −: conda run*, tmux new-session -d*, awk* (each runs arbitrary code past the classifier), and
  entries Claude Code already auto-allows with stricter checks (ls, cat, head, tail, wc, df, grep,
  sort, uniq, git status/diff/log).
- ask −: chmod* (so chmod +x works), git push*. ask keeps: scancel, rm, mv, chown, pip/conda install,
  conda create, curl, wget.
- Tightening chmod (600/700) is not rule-blocked; CLAUDE.md forbids it and the classifier judges it.

## Also
bash-guard now also blocks force pushes written with a leading plus on the refspec, which neither
the deny rules nor the old regex caught; 8 pipe tests passed on a copy before install.
The hook matches command text, so heredocs that merely mention a blocked form are blocked too
(twice on 261110). Fails safe; reword the text rather than work around it.

## Smoke test 4: the loop in auto mode (261110 13:39–13:41)
Project: /jukebox/scratch/md6347/tests/loop_smoke_261110/auto; report: check_auto.sh there.
Observed: both iterations ran claude-opus-5-5 in mode=auto (the new driver default). Iteration 1 wrote
and ran a script via `source config/hpc.sh && conda run -p "$ENV_PY" python ...` (no allow rule
covers it, so the classifier approved it), spawned a haiku/low subagent that checked the output
(PASS, 10 rows), wrote and submitted an sbatch job, committed, WAITING. Iteration 2 verified the exit
marker (0), recorded results, committed, DONE. Zero tool errors, zero permission blocks, clean tree.
Cost 0.40 + 0.25 = 0.66 (haiku subagent 0.004). No classifier usage appears in modelUsage, so its
cost, if any, is not visible here. sacct answered from scotty again.
Inference: routine research steps pass the classifier unattended; one clean run is not evidence that
it never blocks something legitimate. A block would surface as NEEDS_MIKE with the message logged.
