# Approval prompts in autonomous work, and model "downgrades" · mode: interactive · human: user
Sessions examined: 4c38b126 (PD enhancer panels) and a9a90141 (enhancer conservation), both on
261111. Docs: code.claude.com permission-modes, permissions, auto-mode-config, model-config,
settings-reference#switchmodelsonflag; support.claude.com/en/articles/15363606. They were read by a
sonnet/medium claude-code-guide agent, then checked against `claude auto-mode defaults` (CLI 2.1.321).

## Observed
- Both sessions had cwd = /mnt/cup/people/md6347/claude-test with no additionalDirectories. Every
  Edit/Write in both went to /jukebox/pena/mike/261012_PD_Enhancer_Analysis: 233 in 4c38b126 and 17
  in a9a90141.
- Default auto-mode allow rule "Local Operations": project scope = "the repository the session started
  in — wandering into ... other repos is scope escalation". Docs: acceptEdits prompts for edits outside
  the working dir / additionalDirectories. Auto mode's handling of those edits is not documented.
- Ask rules (curl, wget, pip install, conda install/create, mv, rm, scancel, chown) "always force a
  permission prompt, even in auto mode". a9a90141 needed exactly these: conda create, curl downloads,
  scripted REST queries. It asked the user how to handle prompts.
- autoMode is read only from user settings (~/.claude/settings.json), managed settings and --settings,
  never from project settings. autoMode.allow takes prose exceptions to soft_deny; "$defaults" keeps
  the built-ins.
- Default soft_deny rules that hit scientific work: "Code from External" (executing downloaded code)
  and "Untrusted Code Integration". The default allow rule "Declared Dependencies" covers only installs
  from manifests the repo already declares.

## Model fallback (the "ramp")
- On every request, the more capable models run safety classifiers that cover dual-use biology. On a
  flag, Claude Code switches to the fallback model, and the picker stays there for the rest of the
  conversation. Observed: Fable 5.2 -> Opus 5 (4c38b126; 1199 of 1259 turns then ran on Opus 5), and
  Opus 5.5 -> Opus 5 (a9a90141; 118 of 135 turns). Both were tagged `[bio]`.
- The app wrote `"switchModelsOnFlag": true` to user settings when the user accepted "switch
  automatically" at the first flag (file mtime = flag time, 23:14:52Z). It also reformatted the file;
  the content was otherwise unchanged.
- No setting disables the classifiers. `false` only asks instead of switching, and in -p runs a flag
  becomes an error. Opus 5 has no fallback: a flag there ends the request. No researcher allowlist is
  documented. /feedback is the channel.
- DECISION (pending user): keep `true`, because unattended loops would otherwise error out on a flag.

## Proposed (pending user)
Start sessions in the project folder. Add additionalDirectories for the user's work areas. Drop
curl/wget/pip/conda/mv from ask. Add autoMode.allow entries for public data downloads, user-owned env
installs, running established bioinformatics tools, and project scope = the user's work areas.
Review the result with `claude auto-mode critique`.

## Applied 261111 ~23:20 (user: "make the proposed changes, but also get rid of scancel from the ask list")
- additionalDirectories: the three work areas, each in /jukebox and real-path form. /jukebox/pena is a
  symlink to /mnt/cup/labs/pena, and the docs say symlink-resolved writes outside the working dirs
  prompt. Matching Edit(//...) allow rules were added too.
- ask is now only rm and chown. curl, wget, pip install, conda install/create, mv and scancel were removed.
- environment "Trusted compute": scancel of the user's own jobs, by ID or name, is routine;
  cancelling all of them at once, or anyone else's, is not.
- autoMode.allow: "$defaults" plus 4 entries (project scope = work areas, public data downloads,
  installs into user-owned envs, running established tools). Effective: environment 26, allow 20,
  soft_deny 72, hard_deny 2.
- Verified: settings hot-reloaded into the running session, and all six paths were accepted as
  working directories (NFS is fine). Not verified: `claude auto-mode critique`, which needs
  standalone auth.
- Found: the standalone CLI login is dead. "OAuth session expired and could not be refreshed",
  expiresAt reset to 0, though refreshTokenExpiresAt = 2026-12-05. The loop's launch check compares
  only dates, so it would not catch this. The user must run `claude auth login`.
- claude-test/.claude/settings.local.json collected about 24 "always allow" rules: mostly exact
  one-off strings, plus broad `python3 -c ' *` / `python3 -I -c ' *` / `python3 -`. Those are
  suspended in auto mode but active in other modes. Left for the user to prune.
