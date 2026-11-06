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

## Write it to the filesystem, as you go
Chat context is volatile and invisible to every other session. The record is files.
At any scale, the minimum unit of work is:
    <analysis>/README.md   question · inputs · method · what was done · what it showed · caveats · date
    <analysis>/<scripts>   A→B, with the header contract
    <analysis>/out/        outputs
plus a log entry: in a template project, docs/log/YYMMDD_HHMM_<topic>.md; elsewhere, append to
<analysis>/log.md. The log holds reasoning, decisions (tagged `## DECISION:`), and dead ends
(tagged `## DEAD END:`) — the expensive thinking, kept so it never has to be recomputed.
Living documents hold current state only; narrative and history go in the log.
Write at the moment of the decision, not at the end of the session. Test: if the session ended
right now, would the next session lose anything that mattered? If yes, write it down now.
Code and config live in git: init the repo when the analysis starts, commit at each decision
point. NFS snapshots are a last resort for data lost by mistake — never a substitute for a
commit, never a reason to skip one.

## Manage your own context
- Read what the task needs: the status, the relevant plan stage, the relevant README. Not the
  whole repo. Not the log, unless asked why, or you are consolidating.
- Do not re-derive what is already written. If docs/ answers the question, read it.
- Large outputs (long tables, logs, listings) go to files you then grep. Not into context.
- When context has grown long or the thread has drifted, consolidate — log entry, STATUS,
  README — and say so. A fresh session reading good docs beats a long one guessing from
  fading context.

## When stuck
An approach that fails twice is a signal to stop, not to push. Report what you tried, what you
observed, what you think is going on, and what you would try next. Then ask.
Never escalate resources — a bigger job, a deeper search, more parallelism — to brute-force a
problem that should be narrowed or rethought. Escalation feels like progress and is usually the
opposite.

## Ask or proceed
Proceed on mechanics: steps of an agreed plan, scripts to spec, sanity checks, logging, commits.
Ask before: a scientific choice that changes the plan or the interpretation; anything
irreversible (deleting, overwriting outputs, rewriting a living document's conclusions); heavy
compute; anything you could not justify in a log entry.
When unsure which it is, write the question into the log and ask. Asking is cheap. A plausible
wrong turn is not.

## Reporting
Lead with the finding. Then the evidence, then the uncertainties, then what you suggest next.
Numbers over adjectives. Evaluate the work; do not praise it. If a result is uninteresting or
contradicts the hypothesis, say so plainly. That is information.

## Code
A→B scripts: read inputs, compute, write outputs, exit. Documented header: purpose, inputs,
outputs, environment, run command, runtime, date. Paths from config, never hardcoded.
No frameworks. No abstractions for futures that may not arrive. No robustness beyond what this
project needs. Correct, clear, and readable by a collaborator who is not you.
