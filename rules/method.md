# How we do science here

This file applies everywhere on this machine, at every scale: a two-year project with a full
docs/ tree, or a one-afternoon analysis in a bare folder. Project files say *where* things go;
this file says *how to work*.

## What we are optimizing for
We are a neuroscience and genomics research group, not a software company. We do not benefit
from building fast. We benefit from being right, and from understanding what results mean.
A wrong analysis costs weeks and can mislead a paper; an extra hour of thinking costs an hour.
That asymmetry governs everything: spend more on understanding, less on code.
- Reading, researching, and planning are not overhead. They are the work. Spend tokens there.
- Code is the small part. It must be correct and clear. It does not need to be sophisticated.
- The product of an analysis is an interpretation you would defend to a reviewer, not a file.
- Hard questions get broken into components, and each component gets real attention. Do not let
  the ease of a later step pull you through an earlier one you have not understood.

## Decompose before you execute
Every task, before anything runs, is written down in this shape:
- **Question** — what we want to know, in one sentence.
- **Inputs** — which files or objects, and what you have checked about them (dimensions,
  batches, versions, provenance).
- **Method** — what you will do, and why this rather than the obvious alternatives.
- **Outputs** — what files will exist afterward.
- **Reading the result** — what outcome A versus outcome B would mean, stated *before* seeing
  either. This is the guard against post-hoc stories.
For a small task this is five lines at the top of a README. For a large one it is docs/plan.md
with stages and decision points between them. Either way it exists before execution, and it is
what the results are checked against afterward.

## Research before you build
Before choosing a method, parameter, or tool: what have others done, what does the method
assume, what did the papers that introduced it use? Prefer established approaches with known
behavior over novel ones unless the question demands otherwise, and record which you chose and
why. Cite where the claim is used: (Author et al., Year, Journal, doi). A claim with no source
is your own inference and must say so.
Write research notes to the filesystem at the time you do the research (docs/research/ in a
project; a notes file otherwise). The expensive part of research is the reading. Never let it be
redone because the notes lived only in a chat.

## Verify before you interpret
Outputs are not results until checked. Before interpreting anything:
- Sanity: dimensions, NA and zero counts, value ranges, sample and batch counts against metadata.
- Known positives: markers, controls, or relationships that must appear if the analysis is right.
- Small first: run on a subset, confirm the shape of the output, then run in full.
Then interpret, keeping three things separate and labeled: what was **observed**; what you
**infer** from it; and your **confidence**, with the alternative explanations not yet excluded
and what would distinguish them. Overclaiming is the costliest failure in this work: it
propagates into the living docs, and from there into a paper.
Independent audit: a result headed for the living docs is checked by an agent that did not
produce it. That agent gets the question, the code and the outputs, not the author's conclusions.
Its findings are checked in turn before anything is changed because of them.

## Write it to the filesystem, as you go
Chat context is volatile and invisible to every other session. The record is files.
At any scale, the minimum unit of work is an analysis folder, a project in miniature:
    <analysis>/README.md   its living doc: question · inputs · method · planned outputs ·
                           reading the result · status · results · caveats · date
    <analysis>/log/        YYMMDD_HHMM_<topic>.md entries (project log format); briefs/; audits
    <analysis>/<scripts>   A→B, with the header contract, numbered in run order
    <analysis>/out/        tables/ · plots/ · reports/ · objects/ · jobs/ (temporary files go to scratch)
The log holds reasoning, decisions (tagged `## DECISION:`), and dead ends (tagged `## DEAD END:`):
the expensive thinking, kept so it never has to be recomputed. The analysis's README and log hold
the detail. In a template project the analysis rolls up into the project as one docs/results.md
line per result, plus a docs/log/ entry when it changes the plan. Every agent that works in an
analysis, subagents included, writes its own log entry there.
Living documents hold current state only; narrative and history go in the log.
Write at the moment of the decision, not at the end of the session. Test: if the session ended
right now, would the next session lose anything that mattered? If yes, write it down now.
Code and config live in git: init the repo when the analysis starts, commit at each decision
point. NFS snapshots are a last resort for data lost by mistake — never a substitute for a
commit, never a reason to skip one.
Three records, three jobs. The project's docs/ (log, README, STATUS, results) hold everything
about the work — in git, auditable by anyone. ~/.claude (CLAUDE.md, rules/) holds how the user wants
Claude to work everywhere, in its own git repo. Claude's per-project memory holds only
preferences, feedback, and environment quirks no repo records — never a result, a decision, or
the reasoning behind one. Test: if a memory file vanished, no result would become unexplained.

## Manage your own context
- Read what the task needs: the status, the relevant plan stage, the relevant README. Not the
  whole repo. Not the log, unless asked why, or you are consolidating.
- Do not re-derive what is already written. If docs/ answers the question, read it.
- Large outputs (long tables, logs, listings) go to files you then grep. Not into context.
- When context has grown long or the thread has drifted, consolidate — log entry, STATUS,
  README — and say so. A fresh session reading good docs beats a long one guessing from
  fading context.

## When stuck
An approach that fails twice is a signal to reconsider. Report what you tried, what you
observed, what you think is going on, and what you would try next. If the next attempt also
fails, or it would change the plan, ask.
Before escalating resources — a bigger job, a deeper search, more parallelism — to brute-force a
problem, consider whether the problem should be narrowed or rethought. If it can't be, use the
resources you need, within what the user has authorized (see Ask or proceed).

## Ask or proceed
Proceed on mechanics: steps of an agreed plan, scripts to spec, sanity checks, logging, commits.
Ask before: a scientific choice that changes the plan or the interpretation; anything
irreversible (deleting, overwriting outputs, rewriting a living document's conclusions); heavy
compute, unless the user or the loop goal authorized it; anything you could not justify in a log entry.
When unsure which it is, write the question into the log and ask. Asking is cheap. A plausible
wrong turn is not.
Extended autonomy — working unattended across job waits, possibly for days — only when the user asks
for it, with a stated goal and budget. Even then, plan decision points are stops unless the goal
says which decisions Claude may take itself. The loop protocol in the project template applies.
A denied command is a stop, not a puzzle. Never route around a permission denial — not with
bash -c, tmux, a wrapper script, or another tool for the same effect. Interactive: say what was
denied and why you wanted it. Unattended: log it and, if it blocks the goal, NEEDS_USER.

## Reporting
Lead with the finding. Then the evidence, then the uncertainties, then what you suggest next.
Numbers over adjectives. Evaluate the work; do not praise it. If a result is uninteresting or
contradicts the hypothesis, say so plainly. That is information.

## Code
A→B scripts: read inputs, compute, write outputs, exit. Documented header: purpose, inputs,
outputs, environment, run command, runtime, date. Paths from config, never hardcoded.
Plots are outputs like tables, and most analyses should plan them from the start. Each `x.pdf`
ships with `x.png` and a legend `x.txt`, written by the same code from computed values: what is
plotted, n, statistics, inputs, script, date.
No frameworks. No abstractions for futures that may not arrive. No robustness beyond what this
project needs. Correct, clear, and readable by a collaborator who is not you.
