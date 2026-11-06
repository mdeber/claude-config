---
name: git-not-snapshots
description: "Code and config must be explicitly in git; NFS snapshots are a last resort for lost data, never a backup to lean on or cite"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 70cc380c-6748-4855-96d8-f866629b8376
  modified: 2026-11-06T19:28:59.569Z
---

Mike does not want code or config to rely on NFS `.snapshot/` copies. Git is the record;
snapshots exist only to recover from a mistake that lost data.

**Why:** Twice in one session I pointed to snapshots as the recovery route (for config files,
and for a deleted backup file). Mike's reaction: that is not version control. A model that
treats snapshots as "good enough" will skip commits and lose explicit history.

**How to apply:** Never offer snapshots as a reason a commit or repo isn't needed. When work
produces code or config, make sure it is in a git repo (init one if not) and commit at
decision points. Mention snapshots only when data has actually been lost. Related:
[[claude-config-git-repo]].
