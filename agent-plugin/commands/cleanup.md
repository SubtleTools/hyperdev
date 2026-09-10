---
name: cleanup
description: Delete what audit found — orphaned worktrees, parked leftovers, gone branches, scratch contents — every deletion confirmed per item
argument-hint: "[space-path]"
---

# Cleanup

The audit-findings executor: the **one** command in the plugin that deletes
anything. Audit reports; cleanup acts — and only on what audit already
classifies as debris, only for ids the user confirmed, each re-verified at
deletion time. There is no `--all` flag, deliberately, and never will be.

In a multi-repo space, cleanup iterates every repo. Worktree and branch ids
there are prefixed with the slug — `worktree:<slug>/<name>` and
`branch:<slug>/<name>` — so an id names which repo it belongs to.
Space-level ids (`parked:<name>`, `backup:memory-index`,
`evidence:preflight`, `scratch:contents`) are never slug-prefixed in either
layout — they belong to the space, not a repo. Single-repo worktree/branch
ids are unchanged.

## Usage

```
/hyper:cleanup
/hyper:cleanup ~/work/mosaic/compliance
```

## The id classes

The script (`hyper-cleanup.sh`) knows exactly six kinds of debris — the
same classifications `hyper-audit.sh` makes, nothing of its own:

| Id | What it is |
|---|---|
| `worktree:<name>` (or `worktree:<slug>/<name>` in a multi-repo space) | `worktrees/` entry that is ORPHANED (gitdir missing) or leftover build output (no `.git`). A live registered worktree is refused loudly. |
| `parked:<name>` | entry under the legacy `.claude/worktrees/` that conversion parked — not a registered worktree |
| `backup:memory-index` | `.claude/MEMORY.md.hyper-orig`, the pre-conversion memory index backup |
| `evidence:preflight` | `.hyper-convert.preflight`, a conversion's capture file |
| `branch:<name>` (or `branch:<slug>/<name>` in a multi-repo space) | local branch whose upstream is gone. Deleted with `git branch -d` **only** — never `-D`; an unmerged branch is refused with instructions for the human. |
| `scratch:contents` | the contents of `scratch/` (the directory itself stays) |

## The flow

1. **List.** Run list mode and show the user everything found, with sizes and
   evidence:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/hyper-cleanup.sh" [path]
   ```

   No `--delete` means nothing is deleted — it is safe to run any time. If it
   prints "Nothing to clean.", say so and stop.

2. **Let the user pick from the list** with AskUserQuestion, multiSelect:
   one option per candidate — label is the id, description is the size and
   evidence from the listing — so the user selects exactly what to remove in
   one interaction. More than 4 candidates: split into multiple multiSelect
   questions, grouped by class (`worktree:` items together, `branch:` items
   together, disposables together). Never infer consent from "clean it up"
   alone for `worktree:`, `parked:`, or `branch:` items — they must appear as
   options the user actually picked. `scratch:contents` and
   `evidence:preflight` may be presented as one combined option — they are
   disposable by contract.

   (A human at a terminal gets the same per-item flow from the script itself:
   `hyper-cleanup.sh -i` asks y/N per candidate, default No. It requires a
   tty, so agent sessions cannot use it — that is what AskUserQuestion is
   for.)

3. **Delete**, one visible step per confirmed id:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/hyper-cleanup.sh" [path] --delete <id>
   ```

   Each id is re-verified against its candidate class at deletion time — the
   script never trusts the earlier listing.

4. **Re-run list mode** and show the user the clean result.

5. **If an id is refused**, relay the script's reason verbatim. A refusal
   means the re-verification found the world changed since the listing — a
   worktree came alive, a branch grew commits. Never retry with force, never
   escalate `-d` to `-D`, never fall back to a raw `rm`.

## Output

Per item: `deleted <id> (<size>)` or `refused <id>: <reason>`, then a summary
line. Exit 0 when everything named was deleted, 1 when anything was refused.
