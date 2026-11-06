# PNI environment (md6347)

## Where things are
- **scotty** = login node, also usable for real work. 44 cores, ~1 TB RAM, SHARED with all of PNI.
- **spock** = Slurm compute. Submit from scotty; never log in to spock.
- Canonical paths use `/jukebox` (= `/mnt/cup/labs`; `/jukebox/scratch` = `/mnt/bucket/scratch`, a
  separate filesystem from the lab dirs).
- `/jukebox` is an **automount root**: `ls /jukebox` looks empty. This is normal. Never conclude a
  path is missing from a listing of `/jukebox` — access the full path directly.
- `/Volumes/pena`, `/Volumes/krienen` are Mike's laptop SMB mounts. Translate to
  `/jukebox/pena`, `/jukebox/krienen` in anything that runs on the HPC.
- Labs: `/jukebox/pena`, `/jukebox/krienen`. Both run near capacity; `df -h` before writing
  large outputs, and prefer scratch for intermediates.
- Mike's scratch: `/jukebox/pena/mike`, `/jukebox/krienen/lab_members/mike`, `/jukebox/scratch/md6347`.
- Home `~` = `/mnt/cup/people/md6347`, NFS. Config and old envs only. Not for data, code, or new envs.
- Primary group is `games`; lab dirs are setgid so files inherit `g_pena`/`g_krienen`. umask 002.

## Compute budget (the system enforces nothing — these are the limits)
- On scotty: inspection, file ops, small interactive analysis. Stay under ~8 cores and ~64 GB.
- Real computation goes to Slurm as a written sbatch script. Never run long work in-session: the
  session dies with the laptop's connection, Slurm jobs don't.

## When something doesn't work, narrow it — don't scale it
- Wrap any exploratory command that touches `/jukebox` in `timeout 60`.
- If an approach fails twice, STOP and report what you learned plus what you'd try next.
  Do not escalate to a bigger/longer/parallel version of the same approach. Escalating resources
  to brute-force a question that should be narrowed is always the wrong move — ask instead.
- Slurm is for computation that is understood and specified, never for making a failing
  exploratory command finish.

## NFS traversal
Metadata operations on `/jukebox` are slow and shared. Recursive traversal is the main way to
hang a session and degrade the filesystem for everyone.
- `-maxdepth 3` by default. Above 4 requires a reason; there is no case for 10+.
- Always prune dependency trees, which hold enormous file counts and are never the target:
  `-name R -prune -o -name site-packages -prune -o -name .git -prune -o -name renv -prune -o`
  (also conda env directories, `node_modules`, `lib/`).
- Prefer walking one top-level subdirectory at a time, reporting as you go, over one deep scan.
- Never run unbounded `find`, `du`, or `ls -R`.

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