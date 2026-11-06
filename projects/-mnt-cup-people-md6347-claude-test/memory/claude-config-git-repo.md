---
name: claude-config-git-repo
description: ~/.claude is a git repo pushed to github.com/mdeber/claude-config; template at /jukebox/scratch/md6347/tools/project-template pushed to mdeber/ai-project-template; commit config edits with behavior-naming messages and push
metadata:
  node_type: memory
  type: project
  originSessionId: 70cc380c-6748-4855-96d8-f866629b8376
  modified: 2026-11-06T21:41:03.062Z
---

`~/.claude` is a git repo (branch `main`, baseline 2026-11-06), remote `origin` =
`git@github.com:mdeber/claude-config.git` (private). Allowlist `.gitignore` tracks CLAUDE.md,
settings*.json, rules/, hooks/, bin/, notes/, agents/, commands/, skills/, projects/*/memory/;
secrets (sessions/, backups/, *.key, .credentials.json) are excluded at the end of the file.

The project template lives at `/jukebox/scratch/md6347/tools/project-template` (renamed from
pni-project-template on 2026-11-06), remote `git@github.com:mdeber/ai-project-template.git`.

GitHub on scotty: key `~/.ssh/id_ed25519_github` via `~/.ssh/config`; no `gh`. Global git identity
is Mike DeBerardine / md6347@princeton.edu; `init.defaultBranch main`. Mike's GitHub login is
`mdeber`; his Princeton login `md6347` is only the server account and never reaches GitHub.

What lives in ~/.claude: `hooks/bash-guard.sh` (audit log + deny on destructive commands),
`bin/claude` (wrapper over the app-shipped CLI), `bin/claude-loop.sh` (unattended driver, launched
by Mike via tmux), `notes/261106_hpc_setup_review.md` (design record and smoke-test findings).

**Why:** Mike wants config history as data, versioned in git and off a single machine.

**How to apply:** After editing any tracked file under ~/.claude or the template, commit with a
message naming the behavior it targets, then `git push`. /jukebox/scratch is not purged (Mike, 2026-11-06).
`skills/synced/` and `plugins/synced/` are claude.ai downloads, ignored.
See [[git-not-snapshots]].
