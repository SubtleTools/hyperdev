---
name: audit
description: Report space drift — missing directories, loose files, stale worktrees
argument-hint: "[space-path]"
---

# Audit

Read-only report on a space's health. Changes nothing. In a multi-repo
space, it iterates every repo under `code/<slug>/` and reports worktree and
branch findings per repo.

## Usage

```
/hyper:audit
/hyper:audit ~/work/mosaic/compliance
```

## Run the script

The mechanical checks are scripted. Run it and read the output:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/hyper-audit.sh" [path]
```

It reports, grouped by severity (problems / warnings / info):

- layout drift — missing scaffold directories, missing `HYPER.md`
- worktree entries — ok / orphaned (gitdir missing) / leftover build output
- local branches whose upstream is gone from the remote
- dirty worktrees (uncommitted changes, with a sample of paths)
- `scratch/` size and loose files over 10MB at the space root
- secret-looking filenames at the root — path only, never contents

It always exits 0: it is a report, not a gate.

## What to do with the findings

The script finds; you judge. For each finding, tell the user what it means and
what the fix would be — but **never apply a fix yourself**. This command is
read-only by contract.

1. **Layout gaps** — point at `/hyper:adopt --apply`, which scaffolds
   directories and docs without touching existing files.
2. **Orphaned worktrees** — the remedies are opposite depending on whether the
   work in it matters: `git worktree repair` to recover, or delete if the
   branch was already merged. Ask before recommending either.
3. **Leftover build output in the worktrees dir** — safe to delete, but the
   user deletes it, not you.
4. **Gone branches** — usually merged PRs; suggest `git branch -d <name>` and
   let the user run it. Never suggest `-D` unless they confirm the work landed.
5. **Dirty worktrees** — surface what is uncommitted; it may be work in
   progress, not debris. Do not suggest discarding anything.
6. **Big loose files** — suggest a destination (`data/` for dumps and blobs),
   with the same caveats adopt uses: never move databases or tool-managed
   paths that something reads by exact location.
7. **Secrets** — report the path only. Never open, print, or move the file.
   A secret *tracked in a worktree* is urgent: it reaches the remote; the
   user needs to untrack it and rotate the credential.

For the debris findings (orphans, leftover build output, parked entries,
gone branches, oversized scratch), point the user at `/hyper:cleanup` —
it lists deletion candidates and deletes only per-item confirmed ids.

## Output

Summarize the script's report for the user in a few lines, leading with
problems. If everything is clean, say so and stop.
