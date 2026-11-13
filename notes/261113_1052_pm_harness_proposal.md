# Proposal: project-manager harness, automatic audits, layered docs, output layout, plot legends
261113 10:52 · mode: interactive · human: user · status: DRAFT — nothing applied
Scope: claude-config (CLAUDE.md, rules/method.md, new agents/) and ai-project-template (CLAUDE.md,
code/README.md, docs/log/README.md, .gitignore, new check script and project hook).

## Evidence this draws on
- **PD project** (/jukebox/pena/mike/261012_PD_Enhancer_Analysis), 261111–12:
  - **Audits worked when run.** In docs/log/261112_2345_documentation_audit_3.md, five parallel audit
    subagents ran with saved briefs and a model/effort table. They found real errors: a STATUS.md
    self-contradiction resting on 7.8 vs 7.7 percentile points, and wrong p-values in background.md.
    The top-level session's spot-checks cut false positives: 71 "broken references" turned out to
    be 2 real ones. Two auditors also corrected wrong premises in their own briefs.
  - **Legends already exist.** analysis/261111_enhancer_conservation/out/ ships fig*.pdf + .png +
    .txt.
  - **Logging is thin.** There are 20 project log entries against 89 commits. No analysis has its
    own log; reasoning goes to the project log or nowhere. 7 briefs are saved project-wide.
  - **One analysis is a project in its own right, but flat.** The conservation analysis has 28
    numbered scripts and 93 files flat in out/, plus 8 `_tmp*` directories inside out/. It has its
    own research/, logs/ (job output), loop goal and cleanup list.
- **Claude Code docs** (checked 261113; quotes in the session scratchpad, spot-checked):
  - **Nesting:** subagents nest by default, "up to three layers below the main conversation"
    (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`). A definition's `tools: Agent(worker, auditor)` limits
    which types it can spawn. Interactively, "only the top-level subagent's summary returns to you".
  - **Concurrency:** 20 concurrent subagents per session.
  - **Context:** subagents load the CLAUDE.md hierarchy and rules (unless `omitClaudeMd`), not auto
    memory.
  - **Definitions:** ~/.claude/agents/*.md frontmatter takes name, description, tools, model,
    effort, hooks, … The body is the system prompt. The per-call `model`/`effort` overrides the
    definition's.
  - **Hooks:** `SubagentStop` (matcher = agent type) gets `last_assistant_message`,
    `agent_transcript_path`, `stop_hook_active`, and can return `decision: block` so the subagent
    keeps working. A hook cannot spawn an auditor for the parent; `agent`-type hooks are themselves
    small verifiers. Injecting into the parent after a return goes via PostToolUse on `Agent`, which
    fires at launch for background agents.
  - **Agent teams:** experimental, and teammates cannot spawn teammates.

## Critical evaluation, idea by idea

**1. The top-level session as project manager (PM): briefs, delegation, consolidation.** Agree.
This is mostly a sharpening of the existing "Subagents" section.
- The risk is the one method.md exists for. A PM that reads only summaries is the shortest path to
  overclaiming. In the PD project, the contradiction lived in STATUS.md, the most synthesized
  document.
- So the PM must keep two duties that cannot be delegated:
  - deciding what a result means;
  - spot-checking any finding before acting on it (audit 3's 71 → 2 shows why).
- Delegating consolidation is fine as drafting. The PM reviews the diff before committing. A
  change to a conclusion (background.md, a results.md interpretation) still goes to the user.

**2. Logging and output instructions for every subagent.** Agree, but don't make the PM retype
them in each brief. That is where they will drift.
- Put the contract in **agent definition files**. They load only when that role runs, so they cost
  nothing in the always-loaded CLAUDE.md.
- The brief then carries only the task: question, inputs, done-when, where the brief itself is
  saved.

**3. Automatic independent audit when a subagent finishes a body of work.** Agree, with a scope
limit and an honest account of what can be automatic.
- **Scope.** Audit anything that produces a number, plot or claim headed for the living docs. Do
  not audit mechanical work (downloads, format conversion, inventories); a deterministic check
  covers that. Auditing everything roughly doubles cost and trains everyone to skim audits.
- **Independence.**
  - The auditor gets the question, the code and the outputs, not the analyst's conclusions. The
    Agent tool's own guidance warns that "an agent handed your hypothesis tends to return it
    confirmed".
  - The auditor uses opus/high and looks at plots (PNG) as well as tables.
  - It writes verdicts per claim; it does not fix.
- **What can be truly automatic.**
  - A hook can mechanically block a subagent from finishing until conventions are met: log entry
    written, legends present, out/ layout.
  - A hook cannot launch the auditor; the PM (or manager) does that. Making the PM's audit
    step hard to skip needs a second hook: block the PM's turn from ending while an analyst's work
    has no audit record. I'd hold that for phase 2 and see first whether the agent definitions alone
    get audits run.

**4. Analyses as projects in miniature, with the same practices at every level.** Agree on *same
formats*, disagree on *same file count*.
- A full docs/ tree (background, plan, data, results, STATUS) per analysis is the kind of overhead
  that gets skipped, which is the failure we're fixing.
- Proposed: each analysis has
  - **one README** that is its living doc (question, inputs, method/stages, planned outputs
    including plots, reading the result, status, results, caveats);
  - **its own `log/`** in exactly the project log format, holding subagent briefs and audits.
- **Roll-up rule.**
  - The analysis README holds the detail.
  - The project gets one results.md line per result, and a project log entry only when an analysis
    decision changes the project plan. That entry links to the analysis log.
- Subagents log into the log/ of the analysis they work in. Same format, with two added header
  fields: role and brief.

**5. Managers that spawn managers.** Possible (depth 3: PM → manager → analyst → helper), but use
sparingly.
- **Cost:** each layer adds cost and loses detail. Interactively you see only the top manager's
  summary, so transparency must come from the files. That is the strongest argument for the
  logging contract.
- **Lifetime:** a manager subagent lives inside the PM's turn and dies with the session. For a
  scope that spans days or Slurm waits, the "sub-manager" should instead be a separate session or
  a claude-loop rooted at that analysis. The analysis-as-mini-project layout makes that natural.
- **Recursion:** managers should not spawn managers. The `manager` definition allows only
  `Agent(analyst, auditor, Explore)`.

**6. Subfolders in out/.** Agree, with one change: no `docs/` inside out/.
- Docs belong at the analysis root (README, log/); out/ holds products.
- Proposed: `tables/`, `plots/`, `reports/`, `objects/` (large, ignored), `jobs/` (Slurm stdout/err
  and .exit markers, ignored).
- Temporary files go to scratch/, never out/ (the 8 `_tmp*` directories).

**7. Every plot with a legend beside it (x.pdf + x.txt).** Agree, and already practiced in the PD
project. Three additions:
- **The same code writes the legend.** It is built from computed values (n, statistics, inputs,
  script, date), never hand-typed, so it cannot drift from the plot.
- **Add x.png.** Agents can view images; PDFs are awkward for them. This is what lets an auditor
  actually check that the plot shows what the legend and table say.
- **Plan plots up front.** The analysis README lists planned plots under "Reading the result", so
  that outcome A vs B is stated in terms of a figure before it exists.

**Cross-cutting.** Enforce with mechanisms where prose has already failed (logging, layout,
legends), and keep prose for judgment. Keep the always-loaded CLAUDE.md short: role detail lives in
agent files and convention detail in the template's code/README.md.

## Drafts

### A. claude-config/CLAUDE.md — replace the "Subagents" section
```markdown
## Working as project manager
On any task bigger than a few steps you are the project manager. You decompose, brief, delegate,
audit, and consolidate, and you own the judgment: what a result means, and what goes into the
living docs.
- Delegate contained work to subagents by role: `analyst` (code, results, plots for one analysis),
  `auditor` (independent check of an analyst's work), `manager` (a multi-stage scope that needs its
  own analysts and audits), `Explore` (read-only search). Their contracts — where to log, where
  outputs go, how to report — are in ~/.claude/agents/; the brief carries only the task.
- Before spawning, save the brief in the analysis's `log/briefs/YYMMDD_HHMM_<role>_<topic>.md`
  (or the project's `docs/log/briefs/`). The brief is the agent's whole context: goal, inputs,
  done-when, what to leave out, how to mark uncertainty.
- Set `model` and `effort` on every spawn:
  - `haiku`, `low`: mechanical and high-volume (fetching, listing, format conversion).
  - `sonnet`, `medium`: reading to understand and summarize; routine analysis to a clear spec.
  - `opus`, `high`: analysis needing judgment; every audit; synthesis across sources.
  - `fable`: only when the user specifies, or after `opus` has failed (about twice the price).
  Step up a tier when the material is subtle, and record why.
- Audit before it counts: every analyst result headed for docs/ gets an `auditor` run first, briefed
  with the question, code and outputs, not the analyst's conclusions. Mechanical work is exempt.
- Audit findings are a source, not a result: spot-check what you will act on before acting.
- A multi-stage scope that finishes within this session can go to a `manager`. One that spans days
  or Slurm waits goes to its own session or loop rooted at the analysis folder.
- Consolidation can be drafted by a subagent; you review the diff before it is committed. Changes to
  conclusions (background.md, results interpretation) go to the user first.
- Condensing a pile of documents into one need-to-know document: the `digest-docs` skill.
```

### B. claude-config/rules/method.md — three small additions
- Under **Verify before you interpret**, add:
  > Independent audit: a result headed for the living docs is checked by an agent that did not
  > produce it, given the question, code and outputs, not the author's conclusions. Its findings are
  > checked in turn before anything is changed on their strength.
- Under **Write it to the filesystem**, replace the minimum-unit block with:
  ```
  <analysis>/README.md   the analysis's living doc: question · inputs · method · planned outputs ·
                         reading the result · status · results · caveats · date
  <analysis>/log/        YYMMDD_HHMM_<topic>.md entries (same format as a project log), briefs/, audits
  <analysis>/<scripts>   A→B, with the header contract, numbered in run order
  <analysis>/out/        tables/ · plots/ · reports/ · objects/ · jobs/   (temporary files go to scratch)
  ```
  An analysis is a project in miniature: its README and log hold the detail. It rolls up into the
  project as one results line per result, plus a project log entry when it changes the plan.
- Under **Code**, add:
  > Plots are outputs like tables: each `x.pdf` ships with `x.png` and a legend `x.txt` written by
  > the same code from computed values (what is plotted, n, statistics, inputs, script, date).

### C. ~/.claude/agents/analyst.md (new)
```markdown
---
name: analyst
description: Carries out one contained piece of analysis (code, tables, plots, write-up) inside one analysis folder, following its conventions, and logs it. Use for implementation and results generation. The brief names the analysis folder, question, inputs and done-when.
tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch, Agent(Explore)
---
You are an analyst on a research team. A project manager gave you one contained task. You own doing
it correctly and leaving a record another scientist could audit without talking to you.

Start: read the brief, the analysis README, and the project's docs/STATUS.md. If the brief's premise
contradicts what you find, say so in your report and do not adopt it.

Work, inside your analysis folder only (temporary files in the project's scratch/):
- Scripts are A→B with the header contract, numbered in run order; paths from config.
- Outputs go to out/tables, out/plots, out/reports, out/objects, out/jobs, never loose in out/.
- Every plot: x.pdf + x.png + x.txt, the legend written by the same code from computed values.
- Small first: run on a subset, check shapes and known positives, then run in full.

Before you finish, in this order:
1. Write log/YYMMDD_HHMM_<topic>.md (timestamp from `date`), in the project log format, with
   `role: analyst · brief: <path> · model: <model>` in the header. Did / Observed (numbers) / Reasoning /
   DECISION / DEAD END / Next.
2. Update the README's Status and Results sections: current state only.
3. Report in 15 lines or fewer: what was done; key observed numbers; every output path; what is
   inferred vs observed, with confidence; what an auditor should check first.

Never: edit project-level docs/, touch other analyses, delete or overwrite outputs you did not
create, or interpret beyond what the outputs show. A scientific choice the brief did not settle is a
question in your report, not a decision you make.
```

### D. ~/.claude/agents/auditor.md (new)
```markdown
---
name: auditor
description: Independently audits an analyst's finished work (code, outputs, plots, log, claims) before its results enter the project docs. Use after every analyst body of work that produces a result. The brief gives the question, the analysis folder and the paths to audit, not the analyst's conclusions.
tools: Read, Write, Bash, Glob, Grep
---
You are an independent auditor. You did not do this work, and your value is in not taking it on
trust. Read the files yourself; a summary you were given is a claim to check, not evidence.

Check, in this order:
1. Does the code do what the README and log say? Read the scripts, not just their headers.
2. Do the numbers reproduce? Recompute a sample of key values from out/tables or the inputs.
3. Do the plots show what their legends and the tables say? View the PNGs.
4. Is the inference sound? Check n, multiple testing, confounds, batch, the choice of background or
   null, and whether the claim outruns the evidence. Overclaiming is the costliest error here.
5. Conventions: run `code/check_conventions.sh <analysis dir>` if the project has it.

Write log/YYMMDD_HHMM_audit_<topic>.md in that analysis's log/, with header
`role: auditor · brief: <path> · model: <model>`. For each claim give a verdict, CONFIRMED / PLAUSIBLE /
WRONG / UNVERIFIED, with evidence (path:line or the recomputed value). Write nothing else; do not fix.
Report in 10 lines or fewer: the verdict counts, every WRONG, and the one thing most likely to mislead.
```

### E. ~/.claude/agents/manager.md (new)
```markdown
---
name: manager
description: Runs a multi-stage scope (one analysis, or one plan stage) that needs several analysts and audits, within this session. Decomposes, briefs, delegates, audits, and consolidates that scope's docs. Use when a scope is too big for one analyst but small enough to finish in this session.
tools: Read, Write, Edit, Bash, Glob, Grep, Agent(analyst, auditor, Explore)
---
You are a manager for one scope of a research project. You hold the same standards as the project
manager above you: you delegate execution, and you keep judgment and the record.

1. Decompose the scope into stages in the analysis README (Question · Inputs · Method · Outputs ·
   Reading the result), before anything runs.
2. For each stage, save a brief in log/briefs/ and spawn an `analyst`. Set model and effort.
3. When an analyst finishes a result, spawn an `auditor` with the question and paths, not the
   analyst's conclusions. Spot-check every WRONG and anything you will act on.
4. Keep the analysis README current, and write your own log entry (`role: manager`).
5. Stop at any scientific choice the brief did not settle, and return it as a question.
Report in 20 lines or fewer: results with audit verdicts, open questions, decisions needed, and the
paths of the README and log entries.
```

### F. Template — code/README.md "code/analysis/" section (replaces the current tree)
```
code/analysis/<name>/
├── README.md     the analysis's living doc. Sections: header (date · stage · owner) · Question ·
│                 Inputs (what was checked) · Method · Planned outputs (incl. plots) · Reading the
│                 result · Status · Results · Caveats
├── log/          YYMMDD_HHMM_<topic>.md, same format as docs/log; briefs/ holds subagent briefs;
│                 audits are entries named *_audit_<topic>.md
├── NN_<step>.*   scripts, numbered in run order
└── out/
    ├── tables/   small derived tables (committed if < 5 MB)
    ├── plots/    x.pdf + x.png + x.txt legend (committed if small)
    ├── reports/  rendered summaries (committed if small)
    ├── objects/  large intermediates — rds, h5ad, npz (gitignored)
    └── jobs/     Slurm stdout/err and <jobid>.exit markers (gitignored)
```
Temporary files go in `scratch/<analysis>/`, never in out/. Batch-driven projects nest by data
state: `out/thru_<batch>/{tables,plots,…}`.

A plot helper is copied into each project, about ten lines per language. It saves pdf + png and
writes the legend from a string the plotting code assembles from computed values:
```python
def save_plot(fig, name, legend, outdir):   # legend: built from computed n, stats, inputs
    fig.savefig(f"{outdir}/{name}.pdf"); fig.savefig(f"{outdir}/{name}.png", dpi=150)
    open(f"{outdir}/{name}.txt", "w").write(legend.strip() + "\n")
```
(An equivalent R helper uses ggsave twice and writeLines.)

### G. Template — CLAUDE.md
- **Layout:** `code/analysis/` becomes "one folder per analysis, each a project in miniature: README
  (its living doc) + log/ + numbered scripts + out/{tables,plots,reports,objects,jobs}".
- **Session protocol, end of session:** add "1a. Each analysis touched has its own log entry and a
  current README. 1b. Results headed for results.md have an audit entry."
- **Rules, roll-up:** "detail stays in the analysis; the project gets one results.md line per result
  and a project log entry only when an analysis changes the plan".

### H. Template — docs/log/README.md
- Header line gains `role: pm | manager | analyst | auditor · brief: <path or —>`.
- New "where" paragraph: project-level work → docs/log/; work inside an analysis →
  code/analysis/<name>/log/.

### I. Template — mechanical enforcement (new)
- **`code/check_conventions.sh [dir…|--changed]`**, an A→B lint that prints violations and exits 1
  if any. It checks that:
  - the README has the required sections;
  - log/ has at least one entry;
  - every out/plots pdf/png has a .txt;
  - no loose files or `_tmp*` sit in out/;
  - every script carries a `purpose :` header line.

  `--changed` checks the analyses with uncommitted changes.
- **Template `.claude/settings.json`:** a `SubagentStop` hook with matcher `analyst|manager` runs
  the check with `--changed` and returns `decision: block`, plus the violations, so the subagent
  fixes them before finishing. It allows the stop when `stop_hook_active` is true, so it never
  loops. Project hooks need workspace trust (the first-session dialog).
- **.gitignore:** `!code/analysis/**/out/plots/` and `!…/reports/` replace `!…/out/final/`.
  `objects/` and `jobs/` stay ignored.

### Phase 2 (only if audits get skipped)
A `Stop` hook on the main session that blocks ending the turn while an analyst log entry from this
session has no matching `*_audit_*` entry. Hold until phase 1 has run on real work.

## Decisions for the user
1. Audit scope: results-bearing work only (recommended), or every subagent?
2. Agent definitions in ~/.claude/agents/ (every project, recommended), or per project in the
   template's .claude/agents/?
3. Commit plots/ and reports/ to git when small (recommended), or keep all of out/ ignored except
   tables?
4. Phase 1 now, phase 2 later (recommended), or both now?
5. Migrate the PD project to the new layout? Not part of this change; it would be its own task.

## Applied: phase 1, 261113 (user: "Yes, apply phase 1"; recommended choices 1-4, no PD migration)
- **claude-config:**
  - CLAUDE.md: "Subagents" replaced by "Working as project manager".
  - method.md: independent audit, the analysis-folder unit, plot legends.
  - agents/analyst.md, auditor.md, manager.md.
  - README updated.
- **template:**
  - code/README.md: analysis layout, README sections, roll-up, plot section with save_plot in
    Python and R.
  - CLAUDE.md: layout, PM delegation, end-of-session steps.
  - docs/log/README.md: "Where" paragraph, role/brief header fields, grep covers analysis logs.
  - .gitignore: tables/plots/reports tracked, objects/ and jobs/ ignored at any depth (this also
    fixes thru_<batch>/tables, which were ignored before); .claude/settings.local.json ignored.
  - code/check_conventions.sh and .claude/settings.json (SubagentStop hook for analyst|manager).
- **Tested** in a throwaway project built from the template:
  - a conforming analysis passes, rc 0;
  - a broken one gives 13 violations, rc 1;
  - --changed finds both;
  - hook mode blocks on the first stop via the transcript's Write paths (with nothing uncommitted),
    allows the second stop (stop_hook_active), and stays silent when nothing was touched;
  - .gitignore ignores objects/jobs at any depth and tracks plots/tables.
- **Ran on the PD conservation analysis** (read-only): 0.6 s on NFS. It reports missing README
  sections, no analysis log, 86 loose files in out/ (now one line), 8 _tmp dirs, 3 scripts without
  headers.
- **Not tested:** a live Claude session firing the hook (that needs a template project opened in a
  session, past the workspace-trust dialog), and whether the agent definitions get picked up as
  subagent_type (they load at session start).

## Live test 261113 11:07 (user: "Yes, after login")
Project /jukebox/scratch/md6347/tests/pm_harness_261113 was built from the template. Its hook was
instrumented to append to scratch/hook_fired.log. Headless: `claude -p` with opus, auto mode,
$5 cap. The request was phrased as the user would phrase it ("work as the project manager your
instructions describe"), with no steps named. Run: end=success, $1.36, 12 turns, 5 min, models
opus-5-5 + sonnet-5-5.
- **Role files** were loaded at session start (init lists analyst, auditor, manager).
- **Delegation:** the PM wrote the analysis README up to "Reading the result" before anything ran,
  then saved each brief to log/briefs/ before spawning.
  - analyst: sonnet/medium;
  - auditor: opus/high.
- **The auditor's brief** carried no conclusions ("you get no conclusions from me").
- **The auditor:**
  - viewed all 3 PNGs and recomputed every number in its own R;
  - added checks of its own (Welch, HC3, wt overlap);
  - gave 19 verdicts: 15 CONFIRMED, 2 PLAUSIBLE, 2 WRONG. One WRONG: the README claimed mtcars was in
    data.md, and it wasn't. The other: the analyst's log called the pooled CIs "separate-variance".
  - flagged an understated caveat: 4- and 8-cyl cars overlap in wt only over 3.17–3.19.
- **The PM:**
  - spot-checked the audit's numbers before acting;
  - fixed both WRONGs;
  - strengthened the caveat (DECISION logged);
  - kept the auditor's hp check as a caveat, not a result, because it was not pre-specified;
  - left background.md for the user;
  - updated data.md, plan A1, results.md and STATUS;
  - committed twice.
- **Plots:** 3 × pdf/png/txt via save_plot. Legends are sprintf'd from computed values (F, p, n,
  slope, script, date).
- **Hook:** fired once, when the analyst stopped (11:09:22), with empty output: the analyst
  conformed on its first try. So the hook loads and runs in a headless session in a fresh project,
  but the live **block** path was not exercised; only the synthetic test covers it.
  `check_conventions.sh` on the final folder: ok.
- **Minor:** the PM's log header said "mode: interactive · human: Mike" for a headless run.
  Cosmetic.
- Verdict: phase 1 works as designed on a small task. The next real test is a multi-stage analysis
  with a manager.
