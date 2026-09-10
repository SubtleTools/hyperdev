---
name: hyper
description: Use when working in or setting up a project space — a bare git repo with worktrees/ and local-only directories. Covers where files belong, why the space root is never committed, and how worktrees are created. Triggers on "space", "worktree layout", "where should this file go", "bare repo", "wt switch".
---

# Project Spaces

A space gives a project a fixed shape: every worktree in one place, plus
directories for files that must never be committed.

A space has exactly one of two layouts, single-repo or multi-repo. In both,
space files and project files never share a directory — project code lives
in a worktree, the space's local-only directories live beside it.

## The layout

**Single-repo** — the space root itself is the bare repo:

```text
<space>/
├── .git/         bare repo — shared object store, no working tree
├── .claude/      settings scoped to this project (wire the space memory)
├── .hyper/    plugin metadata; space memory in .hyper/memory/
├── worktrees/    one worktree per branch, created by `wt switch`
│   ├── main/
│   └── fix-thing/
├── data/  notes/  scratch/  bin/
└── HYPER.md
```

**Multi-repo** — the root holds no `.git`; each tracked repo is its own bare
repo under `code/<slug>/`:

```text
<space>/
├── code/
│   ├── <slug>/
│   │   ├── .git/                bare repo for this repo
│   │   └── worktrees/<branch>/  one worktree per branch
│   └── <slug>/...
├── .claude/      settings scoped to this project (wire the space memory)
├── .hyper/    plugin metadata; space memory in .hyper/memory/
├── data/  notes/  scratch/  bin/
└── HYPER.md
```

There is no repos config file — repos are discovered by globbing
`code/*/.git`.

The root is not a working tree in either layout. Nothing there can be committed
— not by accident, not by a stray `git add -A`. Local-only files get a home
structurally incapable of reaching the remote. There is no `.gitignore` to
maintain and no protection to erode: the safety is structural, which is the
point.

An ordinary checkout is not a space and cannot be decorated into one.
`/hyper:adopt` **converts** it: the repo becomes bare and the whole working
tree moves to `worktrees/<branch>` — dirty state, untracked files,
`node_modules`, everything. Existing linked worktrees are moved in with
`git worktree move`. The conversion prints its full plan as a dry run, refuses
unsafe states (detached HEAD, rebase/merge/cherry-pick in progress,
submodules), verifies `git status` before and after, and never deletes
anything.

## Am I in one

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/hyper-stack.sh" detect   # toolchain
```

For the layout, `hyper-lib.sh` exposes `space_layout <dir>` (prints `bare`,
`multi`, or nothing) and `worktrees_dir <dir> [slug]` (the `slug` is required
in a multi-repo space — there is no single answer without one). Rules of
thumb:

- `.git` is a **directory** with `core.bare=true`, with a `worktrees/` dir or
  `HYPER.md` beside it → a single-repo space. A bare repo with *neither* is a
  plain mirror or hosting remote, not a space — `space_layout` prints nothing
  for it.
- `.git` is a **directory**, not bare → an ordinary checkout; not a space
  until `/hyper:adopt` converts it.
- `.git` is a **file** → you are in a linked worktree, not a space root.
- **No** `.git` at the root, `HYPER.md` present, and a `code/` directory →
  a multi-repo space. Repos under `code/` are optional — an empty `code/`
  is still a multi-repo space the moment `hyper init --multi` creates it;
  `space_repos <dir>` lists the slugs actually found (globbing
  `code/*/.git`, bare only).

A plain bare repository is *not* treated as a space until it opts in by having
`HYPER.md` or a top-level `worktrees/`. Without that gate every mirror on
the machine would claim to be one. Same principle for multi-repo: a directory
with no `.git` and no marker is just a directory, never assumed to be a space.

## The corollary

**Nothing at the space root is backed up.** A dump in `data/` exists on
exactly one disk.

## Where a file goes

| The file is… | Put it in |
|---|---|
| a DB dump, CSV fixture, tarball, sample dataset | `data/` |
| a review brief, handoff doc, design note, scratch writing | `notes/` |
| output you will not miss tomorrow | `scratch/` |
| a script you run against this project | `bin/` |
| part of the codebase | a worktree — it gets committed |

In a multi-repo space, "a worktree" means `code/<slug>/worktrees/<branch>` —
the local-only dirs are still at the space root, never inside `code/<slug>/`.

When unsure between `notes/` and `scratch/`: if losing it would cost you more
than ten minutes, it is not scratch.

**"hyper X" / "space X" means the space root's `X/`.** When the user says
"hyper notes", "space data", etc., they mean the directory at the space
root — never a same-named directory inside a worktree, even if one exists
there too.

## Rules

- **Never commit from the space root.** The bare repo has no index in the
  usual sense; `cd` into a worktree first.
- **Create worktrees with `wt switch <branch>`**, not `git worktree add`. The
  user's worktrunk config controls placement and strips branch prefixes, so
  `fix/foo` becomes `worktrees/foo`. Doing it by hand puts the tree in the
  wrong place and skips post-start hooks (dependency install, hooksPath fix).
- **`scratch/` is disposable.** Anything there may be deleted without warning.
- Worktrees have their own `.claude/` and `CLAUDE.md`; those *are* committed.
  Space-level `.claude/` is local and shared across all worktrees. Space
  memory lives in `.hyper/memory/`, wired via `autoMemoryDirectory` in the
  space's `.claude/settings.json` and each worktree's
  `.claude/settings.local.json` (the value must be absolute — moving the
  space means re-running `/hyper:adopt --apply`).

## Which command, in what order

There is no single "set this project up" command. For an existing project:

1. `/hyper:adopt <path>` — dry run first, read the output. On an ordinary
   checkout this prints a **conversion plan** (every root entry and where it
   moves); on a bare repo it lists what would be scaffolded.
2. For a conversion, walk the user through the plan and get explicit
   confirmation. For a bare space, act on the loose-file suggestions **one at
   a time**, confirming each — they are heuristics; several categories are
   explicitly "leave in place".
3. `/hyper:adopt <path> --apply` — convert, or create the scaffold.
4. `/hyper:tools <path>` — detect the toolchain and wire the check hook.
5. `/hyper:audit <path>` — the judgement checks, any time after.

`/hyper:init` is only for creating a *new* space from a remote. It does
not apply to a project that already exists on disk.

Nothing in the plugin deletes anything, with one controlled exception:
`/hyper:cleanup` deletes what audit classifies as debris — orphaned
worktrees, parked leftovers, gone branches, scratch contents — one explicitly
confirmed id at a time, re-verified at deletion time.

## Commands

- `/hyper:help` — orientation: what the plugin is, all commands, the
  standard flow. Point new users here first.
- `/hyper:init <repo-url> [name]` — create a new space
- `/hyper:init --multi <name>` — create a new, empty multi-repo space
- `/hyper:init <repo-url> --slug <slug>` (or `--new <name> --slug <slug>`) —
  from inside an existing multi-repo space, add a repo at `code/<slug>/`
- `/hyper:adopt [path] [--apply]` — scaffold a bare repo into a space, or
  convert an ordinary checkout into one; at a directory that already looks
  multi-repo, scaffold it additively (see [`/hyper:adopt`](../../commands/adopt.md))
- `/hyper:audit [path]` — report drift, read-only. The mechanical checks
  are scripted (`hyper-audit.sh`); judging each finding is not.
- `/hyper:cleanup [path]` — the audit-findings executor and the one
  command that deletes: lists candidates with stable ids, deletes only ids
  named explicitly, each confirmed per item and re-verified before `rm`.
- `/hyper:tools [path]` — detect the project toolchain and wire the
  check hook. See the `hyper-tooling` skill; the commands are
  project-specific and must be detected or asked about, never assumed. The
  same config file gates the deps friction hook, which asks for one sentence
  of justification when an edit adds a new dependency.
- `/hyper:plan <feature> [phase]` — the four-phase spec workflow: Define,
  Design, Decompose, Develop. Artifacts live under `notes/specs/`.
- `/hyper:gen [template] [dest]` — generate files from a project template;
  deterministic copy, agent authoring only inside marked prompt regions.

## Detecting a space

See "Am I in one" above for the layout rules. `HYPER.md` is the
explicit marker, but a single-repo space is also recognised from structure
alone — a bare `.git` with a top-level `worktrees/` beside it — so spaces
predating this plugin still work without the marker. A multi-repo space has
no such structural fallback for `space_layout`: it requires `HYPER.md` (or
the legacy `HYPERDEV.md`) plus a `code/` directory — `/hyper:adopt`, unlike
`space_layout`, *does* recognize an unmarked multi-shaped directory (see
`/hyper:adopt` case C) and writes the marker as part of scaffolding it.

To find the root from anywhere inside, walk up until that shape appears. A
linked worktree has a `.git` *file*, so it is skipped and the walk continues to
the real root. In a multi-repo space, `find_space_root` resolves from inside
`code/<slug>/worktrees/<branch>/...`, from `code/<slug>/`, from a local-only
dir, or from the root itself — except a brand-new `--multi` space with no
repos yet, which only resolves from the root (nothing under `code/` to walk
up through). When `cwd` is the root itself, take extra care — that is where
commits and loose files go wrong.

## Worktrunk interaction

Placement comes from the user-level worktrunk config, roughly:

```toml
worktree-path = "{{ repo_path }}/../worktrees/{{ branch | replace('fix/', '') | ... | sanitize }}"
```

`repo_path` is the worktree `wt` runs from, so `../worktrees/` resolves to the
space's `worktrees/`. Because this is user-level, it applies to every
project — a space must use that directory name for `wt` to work correctly.

Worktrees of a bare repo get a `.git` *file* rather than a directory, which
breaks relative `core.hooksPath`. The worktrunk `post-start` hook fixes it with
`git config core.hooksPath "$(git rev-parse --git-common-dir)/hooks"`.

In a multi-repo space, `repo_path` is `code/<slug>/`, so the same config
resolves to `code/<slug>/worktrees/<branch>` — which is why `wt switch` has
to run from inside `code/<slug>/` (or one of its worktrees): worktrunk
resolves the repo from cwd, and cwd at the space root has no repo to resolve.
