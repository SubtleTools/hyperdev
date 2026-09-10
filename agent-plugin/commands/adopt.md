---
name: adopt
description: Adopt a repo into the space layout — scaffolds a bare repo additively, or converts an ordinary checkout by wrapping it in the space structure
argument-hint: "[space-path] [--apply]"
---

# Adopt

Brings an existing repository into the space layout. A space has exactly one
of two shapes — single-repo (bare `.git` at the root, the working tree in
`worktrees/<branch>`) or multi-repo (no `.git` at the root, each repo bare
under `code/<slug>/`) — so what adopt does depends on what it finds:

- **Already bare** (a space, or a plain bare repo opting in): additive
  scaffold. Creates missing dirs and docs, lists loose entries at the root
  with suggested destinations. Never moves or regenerates anything.
- **Ordinary checkout**: **conversion**. The repo becomes bare and the entire
  working tree is wrapped into `worktrees/<branch>`. Space files and project
  files never share a directory, so decorating the checkout is not an option —
  wrapping it is.
- **Already multi-repo** (`code/*/.git` bare, no root `.git`): additive
  scaffold, same spirit as case 1 — see [Case 3](#case-3-multi-repo-space-additive-scaffold).

In all cases, dry run by default: without `--apply` nothing changes.
**Nothing is ever deleted, in any mode, on any path.**

## Usage

```
/hyper:adopt                      # dry run on the enclosing space
/hyper:adopt --apply              # apply (scaffold, or convert)
/hyper:adopt ~/work/foo --apply
```

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/hyper-adopt.sh" [path] [--apply]
```

## Case 1: bare repo or existing space — additive scaffold

The dry run prints which of `worktrees/ data/ notes/ scratch/ bin/` and
`HYPER.md` would be created, then scans the root for loose entries and
`worktrees/` for debris (orphaned or dead checkouts).

With `--apply` it creates the missing directories, writes `HYPER.md`,
seeds `.hyper/memory/hyper-layout.md`, and wires `autoMemoryDirectory`
into the space's `.claude/settings.json` (see [Space memory](#space-memory)).
Existing files are left alone — an existing `HYPER.md` or memory seed is
reported as `exists` and never regenerated, so user edits survive a re-adopt.

The loose-entry scan only *suggests* destinations; it never moves anything.
The heuristics key off file extensions and directory names, and they cannot
tell a dump you still need from one you forgot to delete. Several categories
are explicitly do-not-move: live databases (`-wal`/`-shm` sidecars present),
tool-managed dirs (`node_modules`, build output), local secrets (`.env`,
keys), unknown dot-directories, and checkouts (which belong in `worktrees/`,
moved with `git worktree move`, never `mv`).

When running this for the user:

1. Run the dry run and show the output.
2. Go through the loose entries with the user and agree on a destination for
   each. Ask when a file's purpose is unclear rather than guessing.
3. Run with `--apply` to create the scaffold.
4. Move the agreed files with explicit `mv` commands, one per file, so each is
   visible and reversible. Never batch-move on inference alone.

Large files and anything that looks like a database dump or credentials
deserve an explicit confirmation before moving.

## Space memory

Space memory lives at `.hyper/memory/` and loads through the
`autoMemoryDirectory` key the scaffold writes into the space's
`.claude/settings.json` and each worktree's `.claude/settings.local.json` —
settings resolve per project root, so a session inside a worktree reads the
worktree's file, not the space's. Claude Code requires the value to be an
absolute path, so **moving the space means re-running
`/hyper:adopt --apply`** to refresh it. Project-scope settings take effect
only after the workspace trust dialog is accepted.

## Case 2: ordinary checkout — conversion

The dry run prints the full **conversion plan**: the branch, the target
`worktrees/<branch>/`, where every top-level entry goes, how `.claude/` is
split (project config moves with the project; the space-level memory seed is
regenerated at the root, under `.hyper/memory/`), and what happens to each
pre-existing linked worktree. Read it; nothing has happened yet.

With `--apply`, the conversion:

1. Moves the whole working tree — tracked files, uncommitted modifications,
   untracked files, `node_modules`, everything — into `worktrees/<branch>/`
   via a staging directory.
2. Sets `core.bare=true` and registers `worktrees/<branch>` as a worktree of
   the now-bare repo.
3. Moves pre-existing linked worktrees under `worktrees/` with
   `git worktree move` (each named after its branch). Orphaned worktrees and
   name collisions are reported and left untouched.
4. Scaffolds `data/ notes/ scratch/ bin/` and regenerates `HYPER.md` and
   the memory seed (unconditionally — the old files describe a shape that no
   longer exists).
5. Wires `autoMemoryDirectory` into the space's `.claude/settings.json` and,
   after the guarantees verify, the new worktree's `.claude/settings.local.json`
   (see [Space memory](#space-memory)).

### Preflight refusals

`--apply` refuses to start (and the dry run lists every refusal it would hit)
when any of these hold:

- detached HEAD
- rebase, merge, or cherry-pick in progress
- `.gitmodules` present — submodule gitdir pointers do not survive the depth
  change; deinit submodules first
- the current directory is inside the repo being converted
- a leftover `.hyper-convert/` staging dir from an unfinished conversion
- `worktrees/<branch>` already exists
- unmerged/conflicted index entries
- refs or the stash list cannot be read — what cannot be read cannot be
  guaranteed, so the conversion stops before touching anything
- a tracked *file* named `worktrees`, `data`, `notes`, `scratch`, or `bin`
  at the root (it would collide with the scaffold)
- the root is not writable

Two behaviors of a conversion worth knowing in advance:

- Entries under a legacy `.claude/worktrees/` that are **not** registered
  worktrees (build litter, dead checkouts) are left at the space root's
  `.claude/worktrees/` for you to inspect — they are announced, never moved
  or deleted.
- Some tools anchor caches on the git common dir and will later drop
  directories like `.turbo/` at the bare root. Audit flags them tool-managed;
  they are safe to delete, never to move.

### Data-safety guarantees

1. **Commits** — `.git` is never rewritten; every ref and object survives
   because nothing touches them.
2. **Stashes** — same: they live in `.git`, which only gains
   `core.bare=true` and a fetch refspec.
3. **Uncommitted modifications** — stay dirty. The index is rebuilt from HEAD
   after the move (`git reset`), so pre-existing modifications remain
   modifications.
4. **Untracked files** — move with everything else and stay untracked.

All four are **verified**, not assumed. Before mutating anything the script
captures every ref with its hash, the stash count and `refs/stash` hash,
`git status --porcelain`, and a full file inventory (also written to
`.hyper-convert.preflight` so a crashed run leaves evidence). Afterwards
it re-checks each: refs byte-for-byte, stash count and hash, status parity
in the new worktree, and that every pre-conversion path can be located under
the worktree, the space root, or a moved worktree's new prefix. Any mismatch
prints a loud block showing exactly what differs and exits non-zero — and
because nothing is ever deleted, everything needed to reconcile by hand is
still on disk. If the `git worktree add` step fails, the conversion rolls
itself back (un-bares the repo, moves everything home); a failure after that
prints exactly what remains in staging and how to finish or abandon by hand.

## Case 3: multi-repo space, additive scaffold

At a directory that already looks multi-repo — at least one bare
`code/*/.git`, no `.git` at the root — adopt scaffolds additively, same
contract as Case 1: local-only dirs, `HYPER.md` (the multi-repo template) if
missing, AGENTS.md/CLAUDE.md, settings, and worktrunk config per repo under
`code/<slug>/`. Existing files are left alone.

**Converting an existing single-repo space into a multi-repo one is not
supported in this release.** If you are asked to do that, say so explicitly
rather than attempting a workaround — there is no code path for it.

### Agent instructions for a conversion

Converting is safe but not trivial to undo. When running this for the user:

1. **Always run the dry run first and show the user the full plan** — the
   worktree target, the per-entry moves, and any refusals.
2. **Get explicit confirmation before `--apply`.** Never convert on inference
   from "set this project up"; the user must see the plan and say yes.
3. **After a conversion, walk the user through everything it parked or
   announced** — leftover `.claude/worktrees/` entries, the
   `MEMORY.md.hyper-orig` backup — and offer to clean each one up with an
   explicit, per-item command. The conversion never deletes; tidying is this
   conversation's job, not the script's.
3. If the preflight refuses, help resolve the cause (finish the rebase,
   deinit submodules, `cd` out) rather than working around the check.
4. After conversion, relay the final summary: project files are now in
   `worktrees/<branch>/`, and the user's shell must `cd` there.
