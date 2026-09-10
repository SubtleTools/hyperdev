---
name: help
description: What hyper is, what commands exist, and the standard flow for getting a project set up
argument-hint: ""
---

# Help

Summarize the plugin for the user, then point them at the right first step.
Keep it short — this is orientation, not the manual.

## What to tell the user

**hyper** implements the [Hyper Coding methodology](https://hyperdev.saulo.engineer)
for Claude Code. Two ideas:

1. **Spaces.** A space wraps a project: bare `.git` at the root, every
   checkout under `worktrees/<branch>`, and local-only dirs (`data/` `notes/`
   `scratch/` `bin/`) that can never be committed — dumps, briefs, and
   secrets get a home that is structurally incapable of reaching the remote.
   Space files and project files never mix. A **multi-repo space** wraps
   several repos instead of one: no `.git` at the root, each repo bare under
   `code/<slug>/` with its own `worktrees/`.
2. **Toolchain integration.** The project's *own* linter/typechecker runs
   after every edit and failures feed straight back to the agent — plus
   friction on new dependencies, session context injection, spec-driven
   planning, and template-driven generation.

## Commands

| Command | What it does |
|---|---|
| `/hyper:init <repo-url>` | create a new space from a remote — or `--new <name>` from nothing — or `--multi <name>` for an empty multi-repo space — or `<repo-url> --slug <slug>` to add a repo to an existing multi-repo space |
| `/hyper:adopt [path]` | bring an existing repo into the layout — scaffolds a bare repo (single- or multi-repo), **converts** an ordinary checkout (dry run first, four data-safety guarantees) |
| `/hyper:tools` | detect the project's toolchain, wire the per-edit check hook, recommend new tools by aspect |
| `/hyper:audit` | read-only health report: drift, debris, stale branches, secrets |
| `/hyper:cleanup` | delete what audit found — candidates listed first, confirmed per item; the one command that deletes |
| `/hyper:plan <feature>` | four-phase spec-driven workflow: Define → Design → Decompose → Develop |
| `/hyper:gen <template>` | generate files from project templates, verbatim outside marked regions |

Hooks (automatic): SessionStart context injection inside a space; per-edit
check hook and new-dependency friction hook, both opt-in via
`.claude/hyper.json`.

## The standard flow

For an existing project:

1. `/hyper:adopt` — dry run. Show the user the plan (for an ordinary
   checkout this is a **conversion** — get explicit confirmation), then
   `--apply`.
2. `/hyper:tools` — detect the toolchain, agree on the check commands,
   write `.claude/hyper.json`, and **prove the hook can fail** (inject an
   error, expect exit 2).
3. `/hyper:audit` — periodically, to catch drift and debris.
4. `/hyper:plan` when starting a feature; `/hyper:gen` when the team
   has patterns worth templating.

For a brand-new setup: `/hyper:init <repo-url>` instead of step 1 — or `/hyper:init --new <name>` when no repo exists yet.

## If the user asks for more

- Layout rules and conventions: the `hyper` skill, or `HYPER.md` in
  their space.
- Domain language and design rules: `docs/concepts.md` in the plugin.
- What maps to which Hyper Coding pillar: the "Methodology coverage" section
  of the plugin README.
