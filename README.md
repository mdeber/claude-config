# claude-config

Claude Code configuration for the Princeton Neuroscience Institute (PNI) HPC: scotty (login node)
and spock (Slurm). It is one person's working `~/.claude`, kept in git so the setup and its history
can be reviewed. Others at PNI can reuse it.

Most of it is written for PNI: `/jukebox` paths, the `pni` Slurm account, scotty's shared login
node, the lab directory permissions. The principles carry over to other places, but the files
would need more rewriting than they would here.

Companion repo: [ai-project-template](https://github.com/mdeber/ai-project-template), the
project layout that `rules/method.md` and the extended-autonomy loop expect.

## What's here

| Path | What it does | Reuse as is? |
|---|---|---|
| `CLAUDE.md` | Environment facts Claude loads in every session: who you are, where storage is, scotty vs Slurm, conda, Slurm QOS, tmux, NFS rules, data-safety rules, when to use subagents. | **Edit**: personal paths, envs, labs |
| `rules/method.md` | How research is done: write the plan down before running anything, verify results before interpreting them, keep a record in files and git, know when to stop and ask. | Yes |
| `settings.json` | Permissions (auto mode, allow/ask/deny lists), auto-mode environment description, and the Bash hook. | **Edit**: the `autoMode.environment` entries |
| `hooks/bash-guard.sh` | Logs every Bash command to `~/.claude/logs/bash.log` and blocks recursive/forced deletes and git history rewrites, even when wrapped in tmux, `bash -c`, `xargs`, or a script. | Yes |
| `bin/claude` | Stable path to the CLI that the Claude desktop app installs on scotty (`~/.claude/remote/ccd-cli/<version>`). | Yes, if you use the desktop app |
| `bin/claude-loop.sh` | Extended autonomy: runs Claude headless on one goal in a template project and re-enters after every Slurm wait. | Yes |
| `skills/digest-docs/` | Skill: condense a pile of documents (old chat logs, notes, papers) into one need-to-know doc, with subagents doing the reading. | Yes |
| `notes/` | Design records: why each piece is the way it is, smoke-test results, dead ends. | Read; delete in your copy if you like |

Not tracked (see `.gitignore`, which tracks only an allowlist): credentials, sessions, logs,
caches, synced skills/plugins, and `projects/`, where Claude keeps per-user memory.

## Setting it up for yourself

1. **Fork or copy the repo** to your own GitHub account. Keep it private if your `CLAUDE.md` names
   paths or projects you don't want public.
2. **Put it in `~/.claude`.** If you've used Claude Code before, `~/.claude` already exists and
   holds state you should keep. Clone your copy somewhere else, then move only the git directory in.
   Replace `<you>` and the clone location:
   ```bash
   git clone git@github.com:<you>/claude-config.git /jukebox/scratch/<netid>/claude-config-clone
   ```
   ```bash
   mv /jukebox/scratch/<netid>/claude-config-clone/.git ~/.claude/.git && cd ~/.claude && git status
   ```
   `git status` then lists every file where your existing copy differs from the repo. Take the
   repo's version file by file with `git checkout -- <file>`, or merge by hand. The rest of the
   clone directory can be removed afterwards.
3. **Edit `CLAUDE.md`.** These are the parts that are yours:
   - the opening lines (who you are, your labs);
   - "Where things are": your lab and scratch directories;
   - "Conda": your default Python/R envs;
   - anything that describes one person's habits (tmux, compute preferences).

   The data-safety, NFS traversal, subagent, and Slurm sections apply to anyone at PNI.
4. **Edit `settings.json` → `autoMode.environment`.** These entries tell the auto-mode reviewer
   what is routine for *you*: your account, your trusted directories, your GitHub user. Leave
   `"$defaults"` as the first entry, and leave `hard_deny` alone. Check the result with:
   ```bash
   ~/.claude/bin/claude auto-mode config
   ```
5. **Make the scripts executable** if git didn't keep the mode: `chmod +x ~/.claude/bin/* ~/.claude/hooks/*`.
6. **Start a new Claude session.** Settings, hooks, CLAUDE.md, and rules load at session start.

Commit your edits in `~/.claude` like any other repo. When something about how Claude behaves
changes, the commit message should name the behavior, so the history explains itself.

## Operating principles

These are the reasons the files look the way they do. They're worth keeping even if you rewrite
everything else.

- **Being right beats being fast.** `rules/method.md` asks for every task to be written down
  first: the question, the inputs, the method, the outputs, and what each possible result would
  mean. Outputs get checked before they're interpreted. Observed, inferred, and confidence are
  kept separate.
- **The record lives in files.** Chat context disappears and no other session can see it.
  Decisions and dead ends go into the project's `docs/log/` at the moment they happen. Claude's
  memory is only for preferences, never for results.
- **Deletes are staged; you run them.** Claude writes a cleanup list (path, size, why it can go)
  and hands you the command. The hook blocks recursive deletes, `git clean`, `reset --hard`, and
  force pushes outright, and `settings.json` denies them too.
- **Irreplaceable data is never modified.** That covers sequencer output, fastq, BAMs, and
  cellranger/cellbender outputs. Derived data (h5ad etc.) is changed only after you've reviewed
  the change.
- **Permissions stay open.** Lab directories are setgid with umask 002. Claude never tightens
  them.
- **A denied command is a stop.** Claude doesn't route around a block with `bash -c`, tmux, or a
  wrapper script. It says what was denied and why it wanted to run it.
- **Bounded NFS walks.** `/jukebox` metadata is slow and shared. Every `find`/`du`/`ls -R` gets a
  `timeout`, a `-maxdepth`, and prunes for dependency trees, one top-level directory at a time.
- **Subagents for contained work.** Claude delegates reading and surveys, picks the model and
  effort for each agent, and keeps the scientific judgment for itself. An agent's output is a
  source to check, not a result.

## Tips

**Permissions and auto mode**
- `defaultMode: "auto"` only takes effect in `~/.claude/settings.json`, not in project settings.
  In auto mode a classifier reviews each action, including subagents' actions. Anything blocked
  shows up as a denial, not a prompt.
- Rules are checked in the order deny → ask → allow, and the first match wins. So an `ask` rule
  overrides a more specific `allow` rule: `Bash(mv*)` in ask means no form of `mv` can be allowed.
- Don't allowlist interpreters or wrappers (`python*`, `conda run*`, `tmux new-session*`, `awk*`).
  Each one is a way to run arbitrary code without review.

**The bash-guard hook**
- It matches command *text*. A heredoc or `echo` that merely mentions one of the blocked forms
  gets blocked too. That's intended (it fails safe), so reword the text rather than working
  around the hook.
- Test it by piping hook JSON in, for example a harmless `ls`:
  `echo '{"tool_input":{"command":"ls"}}' | ~/.claude/hooks/bash-guard.sh` (no output means allowed).
- The log at `~/.claude/logs/bash.log` shows what any session, subagent, or loop ran.
- Git object files are read-only, so deleting a directory that contains a repo needs `rm -rf`,
  not `rm -r`.

**Login and the CLI**
- The desktop app brings its own CLI to scotty, and sessions opened from the app use the laptop's
  login. Headless runs (the loop) need a one-time standalone login on scotty:
  `~/.claude/bin/claude auth login`.
- That login refreshes itself, but its refresh token has a fixed end date. `claude-loop.sh` refuses
  to start a run whose `--max-days` would go past that date.

**Extended autonomy (`claude-loop.sh`)**
- It runs from the root of an ai-project-template project with a clean git tree, in tmux:
  ```bash
  tmux new-session -d -s cc-loop-<project> '~/.claude/bin/claude-loop.sh --goal-file scratch/loop/goal.md --max-days 2 --budget 10'
  ```
  You launch it yourself; Claude doesn't start loops.
- Each iteration ends by writing one state: `WAITING <jobids>`, `CONTINUE`, `DONE`, or
  `NEEDS_USER <why>`. Plan decision points are `NEEDS_USER` stops unless the goal says which
  decisions Claude may make on its own.
- `--budget` is a soft cap per iteration and includes subagent cost. One turn can overshoot it.
- The model is pinned (`--model`, default `opus`) because the CLI default can change mid-run.
- Audit trail: `scratch/loop/driver.log`, plus a full transcript per iteration in `iter_<n>.jsonl`.

**Working on scotty**
- `/jukebox` is an automount root, so `ls /jukebox` looks empty. Use full paths.
- Long-running work goes in detached tmux sessions named `cc-<purpose>-<id>`. Claude must never
  `tmux attach`, because it hangs the session; it reads the output with `tmux capture-pane`.
- Non-interactive shells have no `conda` function. Use `conda run -p <env>` or source `conda.sh`
  (the path is in `CLAUDE.md`).

## Status

Built and tested on scotty in November 2026 with Claude Code 2.1.3xx. The loop, the hook, auto
mode, and subagents in headless runs have each been smoke-tested; `notes/` has the results. If
you find something that breaks for your setup, open an issue or tell the maintainer.
