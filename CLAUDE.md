# PNI environment (md6347)

## Where things are
- **scotty** = login node, also usable for real work. 44 cores, ~1 TB RAM, GPU. SHARED with all of PNI.
- **spock** = Slurm compute. Submit from scotty; never log in to spock.
- Canonical paths use `/jukebox` (= `/mnt/cup/labs`; `/jukebox/scratch` = `/mnt/bucket/scratch`, a
  separate filesystem from the lab dirs).
- `/jukebox` is an **automount root**: `ls /jukebox` looks empty. This is normal. Never conclude a
  path is missing from a listing of `/jukebox` — access the full path directly.
- `/Volumes/pena`, `/Volumes/krienen` are Mike's laptop SMB mounts. Translate to
  `/jukebox/pena`, `/jukebox/krienen` in anything that runs on the HPC.
- Labs: `/jukebox/pena`, `/jukebox/krienen`. Both run near capacity; `df -h` before writing
  large outputs, and prefer scratch for intermediates.
- Mike's scratch: `/jukebox/pena/mike`, `/jukebox/krienen/lab_members/mike`, `/jukebox/scratch/md6347`
  (conda envs in `envs/`; the project template in `tools/project-template`).
- Home `~` = `/mnt/cup/people/md6347`, NFS. Config and old envs only. Not for data, code, or new envs.
- Primary group is `games`; lab dirs are setgid so files inherit `g_pena`/`g_krienen`. umask 002.

## Compute: scotty or Slurm — decide in one line, then move on
- **Scotty**: interactive work; anything whose actual compute is under ~30 min; anything that must
  outlive this session (in tmux, never in the session foreground); watchers and job launchers.
  Memory ceiling ~300 GB. Under 100 GB is safe indefinitely, and processes can run for days.
  What gets killed: a process holding large memory for days while computing nothing — the idle
  R/Python session left in tmux with a 200 GB object loaded. Don't leave those behind.
  It is shared: `uptime` before anything heavy, and leave headroom.
- **Slurm (spock)**: compute over ~30 min, GPU work, parallel sweeps — it is simply faster there.
  Always a written sbatch script with explicit `--time`, `--mem`, `--cpus-per-task`.
- Don't deliberate beyond this. Queue backed up and it fits scotty → scotty is fine.

## Subagents: delegate contained work, keep the judgment
- Spawn an agent when a piece of work is contained (clear input → output) and doing it here would
  fill this context with material you only need the conclusion of: reading many documents,
  literature search, wide read-only surveys, an independent check of an analysis. Run independent
  pieces in parallel; size the fan-out to the job.
- Keep for yourself: scientific choices, interpretation, plan changes, and the living docs.
- Mike wants you to decide when to delegate, and to set `model` and `effort` explicitly on every
  spawn:
  - `haiku`, `low`: mechanical and high-volume. Pulling fixed fields from many files, listings,
    format conversion.
  - `sonnet`, `medium`: reading to understand and summarize. A batch of documents, a paper, an
    area of code.
  - `opus`, `high`: synthesis across sources, verification, anything whose error would reach a
    result or a doc.
  - `fable`: only when Mike asks, or after `opus` has failed at the task (about twice the price).
  Step up a tier when the material is subtle, and record why.
- The brief is the agent's whole context: goal, input paths, output path and format, what to leave
  out, how to mark uncertainty. The agent writes its work to a file and returns a few lines; read
  the file selectively, don't have it pasted back.
- A subagent's output is a source, not a result: spot-check its claims against the originals
  before they enter docs/. In a project, save the brief beside the output and name both, with
  model and effort, in the log entry.
- Condensing a pile of documents into one need-to-know document: the `digest-docs` skill.

## Data and permissions
- Irreplaceable data (sequencer output, fastq, alignment/cellranger output — anything registered in
  docs/data.md with an external provenance) is never modified in place; derived outputs go beside
  it or under data/derived. If a task won't write to a data directory, leaving it read-only is good
  practice. Ask before writing into a directory you didn't create.
- Recursive or forced deletes (`rm -r`, `find -delete`, `rsync --delete`, `git clean`,
  `git reset --hard`, `git push --force`) are Mike's to run, not Claude's. The Bash hook blocks
  them and logs every command to `~/.claude/logs/bash.log`.
- Permissions on PNI servers are open and inherit from the lab dirs (setgid, umask 002). Never
  tighten them: no chmod 600/700, no umask 077, nothing user-private.

## NFS traversal
Metadata operations on `/jukebox` are slow and shared; an unbounded walk hangs the session and
degrades the filesystem for everyone.
- Bound every traversal: `timeout 60`, `-maxdepth`, and prune dependency trees
  (`-name R -prune -o -name site-packages -prune -o -name .git -prune -o -name renv -prune -o`;
  also conda envs, `node_modules`, `lib/`).
- Walk one top-level directory at a time, shallow first; go deeper only where the shallow pass
  points. Never unbounded `find`, `du`, or `ls -R`. Slurm is not a way to make a slow walk finish.

## Conda
Non-interactive shells have no `conda`. Source it first:
  source /mnt/cup/PNI-facilities/Computing/sw/pkg/Rhel9/ANACONDAPY/2024.02/etc/profile.d/conda.sh
Or `module load anacondapy/2024.02`.
In scripts prefer `conda run -p <env> <cmd>` over `conda activate`.
- Python default: `/jukebox/scratch/md6347/envs/scvi_daisy`
- R default:      `/jukebox/scratch/md6347/envs/r4.4`
Other envs in `/jukebox/scratch/md6347/envs/`. Some software comes from modules (`module avail`:
cellranger, cudatoolkit, bcl2fastq, nextflow, macs, R/4.4.1, Intel-oneapi, etc.).

## Slurm
- Account `pni`. Partitions: `all` (default), `debug`. Nodes: 18x A100-40G (76 cores, 1 TB),
  8x L40S-46G (144 cores).
- QOS caps concurrent resources per user, and priority drops as the cap loosens:
  normal (prio 5000, cpu=532, mem=7T), long (4800, cpu=400, 4T), very-long (4500, cpu=300, 3T).
  Neither partition nor QOS sets a wall-clock limit, so `--time` is self-imposed. Set `--time`,
  `--mem`, and `--cpus-per-task` explicitly on every job; never rely on defaults.
- Use `normal` unless Mike says otherwise.

## tmux
Mike lives in tmux. Use it freely for anything long-running, detached, or worth watching.
- Always start detached: `tmux new-session -d -s <name> '<command>'`
- Name sessions `cc-<purpose>-<id>`, e.g. `cc-watch-4471382`, so Mike can find them.
- **Never run `tmux attach`** — it blocks on a terminal you don't have and hangs the session.
  Read output with `tmux capture-pane -p -t <name> -S -200` instead.
- Check liveness with `tmux has-session -t <name>` or `tmux ls`.
- Tell Mike the session name whenever you start one, so he can attach himself.
- Clean up finished sessions, but never kill one you didn't start.
- Extended autonomy (only when Mike asks for it): `~/.claude/bin/claude-loop.sh "<goal>"`, run
  detached as `cc-loop-<project>` from the project root. It re-enters headless Claude after every
  Slurm wait; the protocol is in the project template's CLAUDE.md.
