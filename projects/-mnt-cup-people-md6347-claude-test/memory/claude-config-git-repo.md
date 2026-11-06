---
name: claude-config-git-repo
description: "~/.claude is a git repo (since 2026-11-06) tracking CLAUDE.md, rules/, settings.json, memory; commit config edits there with behavior-naming messages"
metadata:
  node_type: memory
  type: project
  originSessionId: 70cc380c-6748-4855-96d8-f866629b8376
  modified: 2026-11-06T19:29:05.668Z
---

`~/.claude` is a local git repo (branch `main`, baseline 2026-11-06). Allowlist `.gitignore`
tracks CLAUDE.md, settings*.json, rules/, agents/, commands/, skills/, hooks/, and
projects/*/memory/; secrets (sessions/, backups/, *.key, .credentials.json) are explicitly
excluded at the end of the file. Git identity is set repo-locally. No remote yet: scotty has
no `gh` and no SSH keys, so Mike must set up auth and give a URL first.

**Why:** Mike wants method.md / CLAUDE.md history as data: each change recorded with a
message naming the behavior it targets.

**How to apply:** After editing any tracked file under ~/.claude, commit it there with such
a message. Still open as of 2026-11-06: permission-list tightening (show diff first), remote.
See [[git-not-snapshots]].
