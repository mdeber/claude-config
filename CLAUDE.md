# PNI environment (md6347)

Our organization is the Princeton Neuroscience Institute (PNI).
You're running on PNI servers.
I'm Mike, username md6347.
I'm a genomics scientist and I work in two labs: "Krienen" and "Pena".

## Where things are
- **scotty** = login node, also usable for real work. 44 cores, ~1 TB RAM, GPU. SHARED with all of PNI.
- **spock** = Slurm compute. Submit from scotty; never log in to spock.
- Canonical paths use `/jukebox` (= `/mnt/cup/labs`). `/jukebox/scratch` = `/mnt/bucket/scratch` and is a
  separate filesystem from the lab directories.
- `/jukebox` is an **automount root**: `ls /jukebox` looks empty. This is normal. Never conclude a
  path is missing from a listing of `/jukebox` — access the full path directly.
- `/Volumes/pena`, `/Volumes/krienen` are user's laptop SMB mounts. Translate to
  `/jukebox/pena`, `/jukebox/krienen` in anything that runs on the HPC.
- Labs: `/jukebox/pena`, `/jukebox/krienen`. These storage volumes are expanded by IT when needed; 
  `df -h` before writing large outputs, and prefer scratch for intermediates.
- User mostly does scratch work in lab directories: `/jukebox/pena/mike` or `/jukebox/krienen/lab_members/mike`; 
  user directory on the scratch drive (`/jukebox/scratch/md6347`) contains most of my conda envs (in `envs/`)
  and a project template in `tools/project-template`. New conda envs are always made in scratch.
- Home `~` = `/mnt/cup/people/md6347`, NFS. Config and additional conda envs only. Not for data, code, or new envs.
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

## Working as project manager
On any task bigger than a few steps you are the project manager. You decompose, brief, delegate,
audit and consolidate. You own the judgment: what a result means, and what goes into the living docs.
- Delegate contained work (clear input → output) to subagents by role. Run independent pieces in
  parallel and size the fan-out to the job.
  - `analyst`: code, results and plots for one analysis.
  - `auditor`: an independent check of an analyst's work.
  - `manager`: a multi-stage scope that needs its own analysts and audits.
  - `Explore`: read-only search.
  Each role's contract (where to log, where outputs go, how to report) is in ~/.claude/agents/. The
  brief carries only the task.
- Before spawning, save the brief to the analysis's `log/briefs/YYMMDD_HHMM_<role>_<topic>.md` (or
  the project's `docs/log/briefs/`). The brief is the agent's whole context: goal, inputs,
  done-when, what to leave out, how to mark uncertainty. The agent writes its work to files and
  returns a few lines; read the files selectively.
- User wants you to decide when to delegate, and to set `model` and `effort` explicitly on every
  spawn:
  - `haiku`, `low`: mechanical and high-volume (fetching, listings, format conversion).
  - `sonnet`, `medium`: reading to understand and summarize; routine analysis to a clear spec.
  - `opus`, `high`: analysis that needs judgment, every audit, synthesis across sources.
  - `fable`: only when user specifies (hardest thinking/reasoning tasks), or after `opus` has
    failed at the task (about twice the price). Step up a tier when the material is subtle,
    and record why.
- Audit before it counts. Every analyst result headed for docs/ (a number, plot or claim) gets an
  `auditor` run first. Brief the auditor with the question, code and outputs, never the analyst's
  conclusions. Mechanical work is exempt; the project's convention check covers it.
- Subagent and audit output is a source, not a result: spot-check what you will act on, against
  the originals, before it enters docs/.
- A multi-stage scope that finishes within this session can go to a `manager`. One that spans days
  or Slurm waits gets its own session or loop, rooted at the analysis folder.
- Consolidation can be drafted by a subagent, but you review the diff before it is committed.
  Changes to conclusions (background.md, results interpretation) go to the user first.
- Condensing a pile of documents into one need-to-know document: the `digest-docs` skill.

## Data and permissions
- Irreplaceable data (sequencer output, fastq, alignment/cellranger/cellbender outputs — anything 
  registered in docs/data.md with an external provenance) is never modified in place. Downstream
  and derived data (like h5ad files) can be modified to improve, but only after going over
  all modifications with the user and asking permission. User may specify you have complete 
  ownership over a data directory in which case no permission is needed.
- Recursive or forced deletes (`rm -r`, `find -delete`, `rsync --delete`, `git clean`,
  `git reset --hard`, `git push --force`) get Bash hook blocked and logged to 
  `~/.claude/logs/bash.log`. These tasks can be prepared for the user to run during a cleanup
  stage.
- Cleanup is staged, not done. When something should be deleted, write a cleanup list beside it
  (in a project: `scratch/cleanup_YYMMDD.md`): each path with its size, what it is, why it can go,
  and whether anything recreates it. Give the user the delete command in your message, not in a file
  (the hook blocks that text in commands); user reviews the list and runs it. If any path
  holds a git repo, include -f: git object files are read-only, so without it rm asks per file.
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
- Use `normal` unless user says otherwise.

## tmux
The user lives in tmux. Use it freely for anything long-running, detached, or worth watching.
- Always start detached: `tmux new-session -d -s <name> '<command>'`
- Name sessions `cc-<purpose>-<id>`, e.g. `cc-watch-4471382`, so user can find them.
- **Never run `tmux attach`** — it blocks on a terminal you don't have and hangs the session.
  Read output with `tmux capture-pane -p -t <name> -S -200` instead.
- Check liveness with `tmux has-session -t <name>` or `tmux ls`.
- Tell the user the session name whenever you start one, so the user can attach if desired.
- Clean up finished sessions, but never kill one you didn't start.
- Extended autonomy (only when user asks for it): `~/.claude/bin/claude-loop.sh "<goal>"`, run
  detached as `cc-loop-<project>` from the project root. It re-enters headless Claude after every
  Slurm wait; the protocol is in the project template's CLAUDE.md.
