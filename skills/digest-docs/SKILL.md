---
name: digest-docs
description: Condense a large set of documents (old chatbot logs, notes, email threads, exported chats, papers) into one compact need-to-know document, with subagents doing the reading so this context holds only conclusions. Use when the inputs are too many or too long to read here, or when the user asks to digest, compact, or summarize a pile of files.
---

# Digest a document set

Subagents do the reading. This session keeps the plan, the merge decisions, and the check.
Originals are never modified or moved.

## 1. Decide what the digest is for
Before anything is read, write the decomposition (method.md) at the top of the work README.
The **Question** is who reads the digest and what they need to do with it; that decides what
survives. If the user hasn't said, ask. It is the one choice here that changes the outcome.

Work directory: in a template project, `code/analysis/YYMMDD_digest_<topic>/`; elsewhere a
`digest_<topic>/` folder beside the requested output. Ask before creating it inside a directory
you didn't create.

## 2. Inventory without reading
List the inputs with size, type, and date into `inventory.tsv` (NFS traversal rules apply).
Estimate tokens as bytes/4. Open one or two files only far enough to learn the format.
If they are structured exports (JSON chat dumps, HTML, mailboxes), write a small A→B script that
converts them to plain text, keeping speaker and timestamp and dropping boilerplate. Agents read
the converted text.

## 3. Batch
Group inputs so each batch is coherent (one project, period, or thread) and roughly 50–150k
tokens. Keep chronological order within a batch so corrections follow what they correct.
Write the plan to `batches.tsv`.

## 4. Extract: one subagent per batch, in parallel
Model and effort per CLAUDE.md: usually `sonnet`/`medium`, `haiku`/`low` if purely mechanical.
Save each brief as `briefs/<batch>.md`. Each agent writes `notes/<batch>.md` with:
- **Facts and decisions**: one line each, status `current` or `superseded by <ref>`, and a source
  pointer (`file:line` or `file @ timestamp`).
- **Open questions** and **contradictions**, with pointers to both sides.
- **Dropped**: what kinds of material were left out, and roughly how much.

In chat logs, the assistant's statements are claims, not facts. Mark who said each thing
(`user` / `assistant`) and whether it was later confirmed, corrected, or acted on. An unconfirmed
assistant claim is at most `unverified`.

Each agent returns a few lines: counts and anything surprising. The notes stay on disk.

## 5. Merge
One `opus`/`high` agent (or this session, if the notes are small) reads all the notes and writes
the digest:
- Organized by topic, not by source or date.
- Superseded items resolved by date. Contradictions it cannot resolve are listed, not settled
  silently.
- Every claim keeps a compact source pointer so it can be audited.
- Short. The test is need-to-know for the reader named in step 1; history goes in an appendix or
  stays in notes/.

## 6. Verify: a different agent from the one that merged
It gets the digest and the originals, not the notes. It checks a sample of claims against their
sources (at least 15, or 10%, whichever is larger) and skims a sample of source files for
anything important the digest missed. It reports claims checked, mismatches, and omissions.
Fix what it finds. If mismatches cluster in one batch or exceed a few percent, redo that step
rather than patching lines.

## 7. Record
README: the decomposition, inputs (count, size, date range), batching, models and effort used,
verification numbers, caveats. In a project, a log entry naming the briefs and outputs. Keep
inventory, briefs, notes, and the verification report: they are how someone audits the digest.
