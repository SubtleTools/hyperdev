# hyper

> **Canonical source.** This directory is the canonical source of the hyper
> agent plugin, kept in Claude Code plugin format. It is installed via the
> svallory-plugins marketplace, which vendors this directory as a git subdir.
> Per-harness builds (Codex, OpenCode, Cursor, Pi) are planned — see
> [TODO.md](TODO.md).

Project spaces and real-time toolchain feedback for Claude Code. Implements
the two principles of the [Hyper Coding](https://hyperdev.saulo.engineer)
methodology a plugin can deliver today: **Tools Integration** and
**Real-time Feedback**.

## What is a space

A space gives a project a fixed shape: the git repo (or repos), every
worktree, and a small set of local-only directories (`data/`, `notes/`,
`scratch/`, `bin/`) for files that must never be committed. `HYPER.md` at
the space root is the opt-in marker. A space has exactly one of two shapes:

**Single-repo** — the root itself is the bare repo:

```text
<space>/
├── .git/         bare — no working tree
├── .claude/      settings (wire the space memory)
├── .hyper/    plugin metadata; space memory in .hyper/memory/
├── worktrees/    one checkout per branch
├── data/  notes/  scratch/  bin/
└── HYPER.md
```

**Multi-repo** — no `.git` at the root; each tracked repo is its own bare
repo under `code/<slug>/`, discovered by globbing `code/*/.git` (no
repos config file):

```text
<space>/
├── code/
│   ├── <slug>/
│   │   ├── .git/                bare — no working tree
│   │   └── worktrees/<branch>/  one checkout per branch
│   └── <slug>/...
├── .claude/      settings (wire the space memory)
├── .hyper/    plugin metadata; space memory in .hyper/memory/
├── data/  notes/  scratch/  bin/
└── HYPER.md
```

The root is not a working tree in either shape, so nothing there can be
committed — not by accident, not by a stray `git add -A`. Local-only files
get a home that is *structurally* incapable of reaching the remote. Space
files and project files never share a directory: project code lives in a
worktree, the space's local-only files live beside it.

Adopting an ordinary checkout therefore means **converting** it: the repo
becomes bare, the entire working tree — dirty state, untracked files,
`node_modules`, everything — moves to `worktrees/<branch>`, and existing
linked worktrees are brought in via `git worktree move`. Commits and stashes
live in `.git`, which the conversion never rewrites; uncommitted changes and
untracked files are verified by comparing `git status` before and after, with
a loud warning on any mismatch. It refuses to run mid-rebase/merge/cherry-pick,
on a detached HEAD, or with submodules present, and nothing is ever deleted,
in any mode, on any path.

## Install

```
/plugin install hyper@svallory-plugins
```

## Commands

| Command | What it does |
|---|---|
| `/hyper:help` | What the plugin is, all commands, and the standard setup flow |
| `/hyper:init <repo-url> [space-name] [--default-branch <name>]` | Create a new space from a git remote — or `--multi <name>` for an empty multi-repo space, or `<repo-url> --slug <slug>` to add a repo to one |
| `/hyper:adopt [space-path] [--apply]` | Adopt an existing repo: scaffold a bare repo additively (single- or multi-repo), or convert an ordinary checkout into a space — dry run first, nothing ever deleted |
| `/hyper:audit [space-path]` | Read-only drift report: missing dirs, loose files, stale worktrees |
| `/hyper:cleanup [space-path]` | Delete what audit reports — candidates listed first, every deletion confirmed per item and re-verified; the plugin's one deleting command |
| `/hyper:tools [project-path]` | Detect the project's own toolchain and wire up the check hook |
| `/hyper:plan <feature> [phase]` | 4-phase spec-driven workflow — Define, Design, Decompose, Develop — with artifacts in `notes/specs/` |
| `/hyper:gen [template] [dest]` | Generate files from a project template — deterministic copy, agent authoring only inside marked prompt regions |

## Hooks

Three hook scripts ship. Each is a silent no-op until its own opt-in, and the
opt-ins differ:

- **SessionStart** — injects space context (layout, worktrees, toolchain)
  at the start of each session. Its opt-in is the space itself: it fires once
  the project has the space markers (`HYPER.md`, or a `worktrees/`
  directory beside the bare `.git`), with or without `.claude/hyper.json`.
- **PostToolUse** — after every `Edit`/`Write`/`NotebookEdit`, runs the
  project's *own* linter or typechecker and feeds failures straight back; a
  companion hook flags dependency drift after `Edit`/`Write` on a manifest.
  Both opt in via the project's `.claude/hyper.json`:

```jsonc
{
  "check": {
    "enabled": true,
    "run": "typecheck",            // package script — or an explicit "command"
    "extensions": [".ts", ".tsx"],
    "timeout": 60
  },
  "deps": { "enabled": true }
}
```

Multiple checks go in a `"checks"` array, each with its own filter.
`/hyper:tools` writes this file for you from what it detects.

## Principles

**Report only what is verifiable. Absence means unknown, never a default.**

Detection omits any key it cannot prove: a missing lint command means "this
project has no lint script", not "try `npm run lint`". With no lockfile and no
`packageManager` field the package manager is `unknown` and the check hook
declines to run rather than defaulting to npm. A wrong check that fails on every edit gets ignored
within a day — and the real failures get ignored with it.

Nothing is ever deleted — except by `/hyper:cleanup`, which deletes only
what audit classifies as debris, one explicitly confirmed id at a time. Audit
and adopt's loose-file scan only report — a human acts. The one operation that moves files, converting a checkout into a
space, prints its full plan as a dry run and runs only on an explicit
`--apply`, then verifies `git status` survived the move unchanged.

## Methodology coverage

What the plugin sets up from the five [Hyper Coding](https://hyperdev.saulo.engineer)
pillars, honestly scored:

| Pillar | Status | What exists | What's missing |
|---|---|---|---|
| Tools Integration | ✅ | `/hyper:tools` + check hook: the project's own linter/typechecker/tests, detected never guessed, four stacks (node, go, rust, python) | security scanning, SAST, architecture-compliance checks |
| Real-time Feedback | ✅ | per-edit check hook: halted execution (exit 2) with the specific failure, multi-command `checks` array | per-file routing (fast `eslint <file>`) |
| Reactive Context | 🟡 | SessionStart injects layout + toolchain + check status; space auto-memory at `.hyper/memory/` loads every session | task-scoped injection (a task's docs/schemas appearing when it starts) |
| Engineered Friction | 🟡 | deps hook (new dependency → justify or remove, once per session); plan-develop's `deviations.md` gate | complexity scoring, formal simplicity-first enforcement |
| Deterministic First | 🟡 | `/hyper:gen`: verbatim-outside-prompt-regions templates built from exemplars | starter kits, a real generation engine |

Toolkit components: `hyper plan` → `/hyper:plan` (full four-phase flow,
native format only); `hyper gen` → `/hyper:gen` (templates, no engine);
`hyper tools` → `/hyper:tools` (checks only — see `TODO.md` for the
recommended-tools catalog plan); `hyper watch` and `hyper dash` are
deliberately not stubbed — they need real infrastructure a plugin cannot
fake.

What the plugin adds beyond the methodology: the space itself — structural
separation of project and local files, with a conversion that verifies four
data-safety guarantees (commits, stashes, uncommitted changes, full file
inventory) before declaring success.
