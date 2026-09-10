---
name: init
description: Create a new project space, or adopt the repo already at cwd — bare repo, worktrees, and local-only directories
argument-hint: "<repo-url> [space-name] | --new <space-name> [--default-branch <name>] | --multi <space-name> | <repo-url> --slug <slug> | [--apply]"
---

# Init

Creates a project space, or brings the repo already at the current directory
into the space layout. A space has exactly one of two shapes:

- **Single-repo** — bare `.git` at the root, no code there, checkouts in
  `worktrees/`.
- **Multi-repo** — no `.git` at the root; each tracked repo is its own bare
  repo under `code/<slug>/`, checkouts in `code/<slug>/worktrees/`.

Local-only dirs sit at the root in both shapes, which can never be committed.

## Usage

```bash
/hyper:init git@github.com:org/repo.git
/hyper:init git@github.com:org/repo.git myname --default-branch develop
/hyper:init --new myproject                  # no repo yet — start from nothing
/hyper:init                                  # cwd is already a repo — adopt it
/hyper:init --apply                          # same, applied (not just a dry run)
/hyper:init --multi myspace                  # empty multi-repo space, no repos yet
/hyper:init git@github.com:org/repo.git --slug api   # add a repo to a multi-repo space
/hyper:init --new myproject --slug api               # same, from nothing
```

## What it does

Run the script from the directory that should hold (or already holds) the
space:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/hyper-init.sh" <repo-url> [name] [--default-branch <b>]
bash "${CLAUDE_PLUGIN_ROOT}/scripts/hyper-init.sh" --new <name> [--default-branch <b>]
bash "${CLAUDE_PLUGIN_ROOT}/scripts/hyper-init.sh" [--apply]
```

With no `<repo-url>`, no `[space-name]`, and no `--new`, init checks whether
cwd is already a git repository (`git rev-parse --git-dir`). If it is, this
is the adopt path (see [`/hyper:adopt`](adopt.md) for full behavior and
agent instructions — same script, same dry-run-by-default contract,
same data-safety guarantees for a checkout conversion): it delegates to
`hyper-adopt.sh`, dry run unless `--apply` is passed. If cwd is not a repo,
it prints usage and exits — there is nothing to adopt and no `<repo-url>` to
clone.

Otherwise (a `<repo-url>` or `--new` was given), it creates a new space:

1. `git clone --bare` into `<name>/.git`, then set the standard remote fetch
   refspec and fetch — a bare clone has no remote-tracking branches otherwise.
   With `--new` there is no remote: it runs `git init --bare` instead and
   seeds an empty initial commit (a worktree cannot exist without one), so
   the space works immediately; the closing output shows how to attach an
   `origin` later. `--new` refuses up front when `git config user.name` /
   `user.email` are unset — committing needs an identity, and failing later
   would leave a half-built space.
2. Record `worktrunk.default-branch` and `worktrunk.history` in the repo config.
3. Create `worktrees/ data/ notes/ scratch/ bin/`, each with a
   `.what-goes-here` note.
4. Write `HYPER.md`, seed `.hyper/memory/hyper-layout.md`, and wire
   `autoMemoryDirectory` into the space's `.claude/settings.json`.
5. Create the default-branch worktree via `wt switch`, falling back to
   `git worktree add` when `wt` is unavailable — then write the same
   `autoMemoryDirectory` into that worktree's `.claude/settings.local.json`.

## Multi-repo spaces

`--multi <name>` creates an **empty** multi-repo space: `<name>/` with
`HYPER.md` (the multi-repo template), the local-only dirs, AGENTS.md/CLAUDE.md,
and no `.git` at all — no repos yet.

`<repo-url> --slug <slug>` (or `--new <name> --slug <slug>`), run from
anywhere inside an existing multi-repo space (the root, a local-only dir, or
anywhere under `code/`, including inside another repo's own worktree), adds
that repo as `<root>/code/<slug>/`: a bare clone (or `git init --bare` for
`--new`), the worktrunk config, a first worktree at
`code/<slug>/worktrees/<default-branch>`, and an appended row in the
`HYPER.md` Repositories table for `<slug>`. The row is inserted by a small
script; if `node` is unavailable, init prints
`skipped HYPER.md Repositories row (edit it manually)` on stderr and still
exits 0 — the repo itself is fully set up either way, only the table row is
best-effort.

`--slug` refuses: an invalid slug (must match `[a-z0-9][a-z0-9._-]*`); no
enclosing space at all; a **single-repo** (bare) space — `--slug` only
applies to multi-repo spaces; and a slug that already exists under `code/`.

## Space memory

Space memory lives at `.hyper/memory/` and loads through the
`autoMemoryDirectory` key written into the space's `.claude/settings.json`
and the worktree's `.claude/settings.local.json` — settings resolve per
project root, so a session inside a worktree reads the worktree's file.
Claude Code requires the value to be an absolute path, so **moving the space
means re-running `/hyper:adopt --apply`** to refresh it. Project-scope
settings take effect only after the workspace trust dialog is accepted.

## Notes

- Refuses to overwrite an existing path (new-space modes only).
- There is no `--layout` flag: spaces have exactly one shape. Bringing an
  existing checkout into that shape is a conversion, not a clone — run
  `/hyper:init` with no arguments from inside it (or `/hyper:adopt` directly;
  same script).
- Adopting a checkout is a **conversion** with real preflight refusals
  (detached HEAD, submodules, in-progress rebase/merge, etc.) and
  data-safety guarantees verified after `--apply`. Always show the dry-run
  plan and get explicit confirmation before passing `--apply` — see
  [`/hyper:adopt`](adopt.md#agent-instructions-for-a-conversion) for the
  full checklist.
- Worktree placement comes from the user's worktrunk config
  (`worktree-path = "{{ repo_path }}/../worktrees/..."`), which is why the
  script invokes `wt -C <space>` so that template resolves inside it.
- Report the final path and the worktree to `cd` into
  (`<space>/worktrees/<default-branch>`). For `--slug`, report
  `<space>/code/<slug>/worktrees/<default-branch>` instead. For `--multi`,
  there is no worktree yet — report the space root.
