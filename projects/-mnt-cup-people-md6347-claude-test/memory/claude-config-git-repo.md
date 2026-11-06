---
name: claude-config-git-repo
description: "~/.claude is a git repo (since 2026-11-06) tracking CLAUDE.md, rules/, settings.json, hooks/, bin/, notes/, memory; commit config edits there with behavior-naming messages"
metadata:
  node_type: memory
  type: project
  originSessionId: 70cc380c-6748-4855-96d8-f866629b8376
  modified: 2026-11-06T21:22:49.453Z
---

`~/.claude` is a local git repo (branch `main`, baseline 2026-11-06). Allowlist `.gitignore`
tracks CLAUDE.md, settings*.json, rules/, hooks/, bin/, notes/, agents/, commands/, skills/, and
projects/*/memory/; secrets (sessions/, backups/, *.key, .credentials.json) are explicitly excluded
at the end of the file. Git identity is set repo-locally. No remote yet: scotty has no `gh` and no
SSH keys, so Mike must set up auth and give a URL first.

What lives there as of 2026-11-06: `hooks/bash-guard.sh` (PreToolUse on Bash: audit log at
`~/.claude/logs/bash.log`, denies recursive/forced deletes and git history rewrites on the whole
command string), `bin/claude` (wrapper over the desktop-app CLI under `~/.claude/remote/ccd-cli`),
`bin/claude-loop.sh` (unattended driver, launched by Mike via tmux), and
`notes/261106_hpc_setup_review.md` (the design record and smoke-test findings).

**Why:** Mike wants method.md / CLAUDE.md history as data: each change recorded with a
message naming the behavior it targets.

**How to apply:** After editing any tracked file under ~/.claude, commit it there with such
a message. Still open as of 2026-11-06: a remote; Mike's global git identity (template
projects' first commit fails without one); whether /jukebox/scratch is purged.
See [[git-not-snapshots]].
