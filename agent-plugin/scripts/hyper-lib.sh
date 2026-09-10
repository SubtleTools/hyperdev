#!/usr/bin/env bash
# Shared helpers for space init/adopt/audit.
# Sourced, not executed directly.

set -euo pipefail

# The scaffolded directories and what each is for. Order matters for display.
SPACE_DIRS=(worktrees data notes scratch bin)

dir_purpose() {
  case "$1" in
    worktrees) echo "git worktrees, one per branch (managed by wt)" ;;
    data)      echo "DB dumps, fixtures, large blobs" ;;
    notes)     echo "briefs, handoffs, working docs" ;;
    scratch)   echo "throwaway files; safe to delete at any time" ;;
    bin)       echo "local helper scripts for this project" ;;
    *)         echo "" ;;
  esac
}

# A space has one of two shapes.
#
#   bare  — a bare .git at the root, worktrees in worktrees/, local-only dirs
#           beside them. One repository per space.
#   multi — the root is not a git repository at all; each tracked repository
#           lives in code/<repo-slug>/ with its own bare .git and its own
#           worktrees/. Local-only dirs sit at the root as usual.
#
# In both shapes space files and project files never share a directory —
# adopting an ordinary checkout means converting it.
#
# space_layout <dir> prints "bare", "multi", or nothing.
#
# For bare, core.bare alone is not enough: a plain bare clone (a mirror, a
# hosting remote) is not a space. Require the structure the docs promise — a
# worktrees/ directory beside .git — or the explicit adoption marker.
#
# For multi the marker is mandatory: a directory called code/ is not
# self-identifying the way a bare root is, and guessing would claim ordinary
# directories. The root must additionally have NO .git entry — a root that is
# itself a repository is the bare shape (or a checkout), never multi, whatever
# else sits under code/. Repos under code/ are NOT required: a freshly created
# --multi space (marker + empty code/, no repos added yet) is a real multi
# space the moment it exists, not only once its first repo is added — nothing
# about the shape's identity depends on what it currently holds.
space_layout() {
  local d="${1:-$PWD}"
  # HYPERDEV.md is the legacy marker (pre-rename); spaces adopted under the
  # old plugin name must keep being detected until adopt --apply migrates it.
  if [[ -d "$d/.git" ]]; then
    [[ "$(git --git-dir="$d/.git" config --get core.bare 2>/dev/null)" == "true" ]] || return 1
    if [[ -d "$d/worktrees" || -f "$d/HYPER.md" || -f "$d/HYPERDEV.md" ]]; then
      echo bare
      return 0
    fi
    return 1
  fi
  # No .git entry of any kind (file or directory), the marker, and a code/
  # directory — the only shape left is multi. Whether code/ currently holds
  # any repos is irrelevant to what the root itself is.
  [[ -e "$d/.git" ]] && return 1
  [[ -f "$d/HYPER.md" || -f "$d/HYPERDEV.md" ]] || return 1
  [[ -d "$d/code" ]] || return 1
  echo multi
  return 0
}

# space_repos <root> — one repo slug per line, for a multi-repo space.
# Prints nothing for a bare space (which has no slugs — its single repository
# is the root itself) and nothing for an empty code/ (no repos added yet).
# Discovery is by glob: code/<slug>/.git bare. There is deliberately no config
# file to fall out of sync with the directories.
#
# nullglob is set locally (and restored) so an empty/absent code/ expands the
# glob to nothing rather than the literal pattern string — without it, a
# non-matching glob would fall through to the -d/-e tests below as a literal
# "code/*" path, which happen to fail today but that must not be relied on.
space_repos() {
  local d="${1:-$PWD}" r
  local -a matches
  local restore_nullglob=0
  shopt -q nullglob || restore_nullglob=1
  shopt -s nullglob
  matches=("$d"/code/*/)
  [[ $restore_nullglob -eq 1 ]] && shopt -u nullglob
  for r in "${matches[@]+"${matches[@]}"}"; do
    [[ -d "$r/.git" ]] || continue
    [[ "$(git --git-dir="$r/.git" config --get core.bare 2>/dev/null)" == "true" ]] || continue
    basename "$r"
  done
}

# repo_slug_of <root> <path> — the slug of the repo containing <path>, when
# <path> is at or under <root>/code/<slug>. Prints nothing otherwise (the
# space root itself, a local-only dir, or a bare space have no slug).
repo_slug_of() {
  local root="$1" path="$2" rest
  case "$path" in
    "$root/code/"*) rest="${path#"$root"/code/}" ;;
    *) return 1 ;;
  esac
  rest="${rest%%/*}"
  [[ -n "$rest" ]] || return 1
  echo "$rest"
}

# Where worktrees live for a given root. <root>/worktrees for a bare space;
# <root>/code/<slug>/worktrees for a multi-repo space, which therefore needs
# the slug — without one there is no single answer, so it is an error.
worktrees_dir() {
  local d="${1:-$PWD}" slug="${2:-}"
  if [[ "$(space_layout "$d" 2>/dev/null)" == multi ]]; then
    [[ -n "$slug" ]] || return 1
    echo "$d/code/$slug/worktrees"
    return 0
  fi
  echo "$d/worktrees"
}

# valid_slug <slug> — true when <slug> is a safe code/<slug>/ directory name:
# lowercase alnum, dot, underscore, hyphen, not starting with a separator.
valid_slug() {
  [[ "$1" =~ ^[a-z0-9][a-z0-9._-]*$ ]]
}

# A space is exactly what space_layout accepts: a bare repo with worktrees/
# or the marker beside it. No marker-only fallback — HYPER.md lives at the
# uncommittable bare root, so a marker inside an ordinary checkout is either
# legacy debris or a committed copy in some clone; neither makes that checkout
# a space, and treating it as one would fire the root-guard hooks inside a
# normal working tree.
is_space() {
  space_layout "${1:-$PWD}" >/dev/null 2>&1
}

# Walk up from cwd to find the enclosing space root, if any.
#
# Order matters: a linked worktree contains a .git *file* pointing elsewhere,
# so space_layout correctly rejects it and the walk continues to the real
# root. That is what makes detection work from inside a worktree.
find_space_root() {
  local d="${1:-$PWD}"
  while [[ "$d" != "/" ]]; do
    if is_space "$d"; then
      # A repo of a multi-repo space looks exactly like a bare space on its
      # own — bare .git with worktrees/ beside it — so the walk must not stop
      # there. Only the enclosing multi-repo root is the space root; a repo
      # dir is <root>/code/<slug>, two levels below a root that is itself a
      # space. Checking the grandparent (rather than trusting the name "code")
      # keeps the authority in space_layout.
      local parent grandparent
      parent="$(dirname "$d")"
      grandparent="$(dirname "$parent")"
      if [[ "$(basename "$parent")" == code ]] \
         && [[ "$(space_layout "$grandparent" 2>/dev/null)" == multi ]]; then
        d="$grandparent"
        continue
      fi
      echo "$d"
      return 0
    fi
    d="$(dirname "$d")"
  done
  return 1
}

# True when cwd is the space root itself rather than inside a worktree.
# This is where the dangerous mistakes happen (committing, loose files).
at_space_root() {
  local root
  root="$(find_space_root "$PWD")" || return 1
  [[ "$root" == "$PWD" ]]
}

# write_hyper_md <root> <name> — write the marker/reference for whichever
# layout the root actually has. Callers pass root and name only; the shape is
# detected, never guessed, so an existing multi-repo space re-scaffolded by
# adopt keeps its multi-repo documentation instead of being told it has a
# bare .git and a worktrees/ it does not have.
write_hyper_md() {
  if [[ "$(space_layout "$1" 2>/dev/null)" == multi ]]; then
    write_hyper_md_multi "$1" "$2"
    return
  fi
  write_hyper_md_bare "$1" "$2"
}

write_hyper_md_bare() {
  local root="$1" name="$2"
  cat > "$root/HYPER.md" <<EOF
# $name

Project **space**, bare layout. This directory is not a git worktree —
nothing here is committed. The worktrees live in \`worktrees/\`.

## Layout

| Path | Purpose |
|------|---------|
| \`.git/\` | bare repository (shared object store for all worktrees) |
| \`.claude/\` | Claude settings scoped to this project |
| \`.hyper/\` | plugin metadata; space memory in \`.hyper/memory/\` |
| \`worktrees/\` | $(dir_purpose worktrees) |
| \`data/\` | $(dir_purpose data) |
| \`notes/\` | $(dir_purpose notes) |
| \`scratch/\` | $(dir_purpose scratch) |
| \`bin/\` | $(dir_purpose bin) |

## Rules

- Do not run \`git commit\` from the space root; \`cd\` into a worktree first.
- Create worktrees with \`wt switch <branch>\`, never \`git worktree add\` by hand.
- \`scratch/\` is disposable. Anything you would miss belongs in \`data/\` or \`notes/\`.
- Files here never reach the remote. Secrets are local-only by construction,
  but that also means nothing here is backed up.
- Space memory lives in \`.hyper/memory/\`; \`MEMORY.md\` there is the index.
  Tools without automatic memory loading should read it at session start.

## Naming convention

When the user says "hyper X" or "space X" (e.g. "hyper notes", "space data"),
they mean the \`X/\` directory at the space root — never a same-named
directory inside a worktree, even if one exists there too.
EOF
}

# The default branch of a repo, read from the bare repo's HEAD. Prints "?"
# when HEAD resolves to nothing (a repo with no commits yet) — a table cell
# must always be filled, and "?" is honest where a guessed "main" would not be.
repo_default_branch() {
  local gitdir="$1" b
  b="$(git --git-dir="$gitdir" symbolic-ref --short HEAD 2>/dev/null)" || b=""
  [[ -n "$b" ]] || b="$(git --git-dir="$gitdir" config --get worktrunk.default-branch 2>/dev/null)" || b=""
  echo "${b:-?}"
}

# write_hyper_md_multi <root> <name> — the multi-repo variant. The Repositories
# table is built from space_repos, i.e. from the directories that actually
# exist, so it cannot drift from the layout the way a hand-kept list would.
# "What it is" is left for the user to fill in: the plugin can see a slug and
# a branch, but not what the repository is for, and inventing a description
# would be exactly the unverifiable output the detection rule forbids.
write_hyper_md_multi() {
  local root="$1" name="$2" slug rows=""
  while IFS= read -r slug; do
    [[ -n "$slug" ]] || continue
    rows+="| \`$slug\` | _(describe this repo)_ | \`$(repo_default_branch "$root/code/$slug/.git")\` |"$'\n'
  done < <(space_repos "$root")
  [[ -n "$rows" ]] || rows="| _(none yet)_ | | |"$'\n'

  cat > "$root/HYPER.md" <<EOF
# $name

Project **space**, multi-repo layout. The space root itself is not a git
repository — nothing here is committed. Each tracked repository lives under
\`code/<repo-slug>/\`, with its own bare \`.git\` and its own \`worktrees/\`.

## Layout

| Path | Purpose |
|------|---------|
| \`code/<repo-slug>/.git\` | bare repository for that repo (shared object store for its worktrees) |
| \`code/<repo-slug>/worktrees/<branch>\` | $(dir_purpose worktrees) |
| \`.claude/\` | Claude settings scoped to this project |
| \`.hyper/\` | plugin metadata; space memory in \`.hyper/memory/\` |
| \`data/\` | $(dir_purpose data) |
| \`notes/\` | $(dir_purpose notes) |
| \`scratch/\` | $(dir_purpose scratch) |
| \`bin/\` | $(dir_purpose bin) |

## Repositories

| Slug | What it is | Default branch |
|------|------------|----------------|
${rows}
## Rules

- The space root is **not** a git repository. There is no \`.git\` and no
  \`worktrees/\` here; both live one level down, per repo, under \`code/<slug>/\`.
- Only commit from inside \`code/<slug>/worktrees/<branch>\`; never from the
  space root or from a local-only directory.
- Create worktrees with \`wt switch <branch>\`, never \`git worktree add\` by hand.
  \`wt switch\` must be run from inside \`code/<slug>/\` — it does not resolve a
  repo from the space root.
- \`scratch/\` is disposable. Anything you would miss belongs in \`data/\` or \`notes/\`.
- Files at the space root never reach the remote. Secrets are local-only by
  construction, but that also means nothing here is backed up.
- Space memory lives in \`.hyper/memory/\`; \`MEMORY.md\` there is the index.
  Tools without automatic memory loading should read it at session start.

## Naming convention

When the user says "hyper X" or "space X" (e.g. "hyper notes", "space data"),
they mean the \`X/\` directory at the space root — never a same-named
directory inside a worktree, even if one exists there too.
EOF
}

# add_repo_row_to_hyper_md <root> <slug> — append a row for a newly-added
# repo to the Repositories table in an existing multi-repo HYPER.md. Targeted
# insert, not a rewrite: write_hyper_md_multi regenerates the whole file from
# space_repos, which would blow away any "What it is" text the user already
# filled in for other rows. Idempotent — a row for this slug is never
# duplicated on re-run.
add_repo_row_to_hyper_md() {
  local root="$1" slug="$2" file
  file="$root/HYPER.md"
  [[ -f "$file" ]] || return 0
  grep -qF "| \`$slug\` |" "$file" && return 0
  local branch row
  branch="$(repo_default_branch "$root/code/$slug/.git")"
  row="| \`$slug\` | _(describe this repo)_ | \`$branch\` |"
  node -e '
    const fs = require("fs");
    const [file, row] = process.argv.slice(1);
    const text = fs.readFileSync(file, "utf8");
    const marker = "|------|------------|----------------|\n";
    const i = text.indexOf(marker);
    if (i === -1) process.exit(4);
    const insertAt = i + marker.length;
    let end = text.indexOf("\n\n", insertAt);
    if (end === -1) end = text.indexOf("\n## ", insertAt);
    if (end === -1) process.exit(4);
    const before = text.slice(0, end);
    const after = text.slice(end);
    const cleaned = before.replace(/\n\| _\(none yet\)_ \| \| \|/, "");
    fs.writeFileSync(file, cleaned + "\n" + row + after);
  ' "$file" "$row" 2>/dev/null || return 1
}

# The agent-facing pointer, appended to a fresh AGENTS.md and to any
# pre-existing AGENTS.md / CLAUDE.md that does not mention HYPER.md yet.
# Deliberately a bare directive, not a summary: an unexplained "you must
# read" reliably makes an agent open the file, while an inlined summary
# invites skipping the source and drifts from it over time. HYPER.md stays
# the single source of the rules.
agent_docs_section() {
  cat <<'EOF'

## Repo context

This directory is the root of a hyper space. Before doing anything here, you
must read `HYPER.md` — all the rules for working in this directory live there.
EOF
}

# ensure_agent_docs <root> <name> — give coding agents their standard entry
# points at the space root, without mixing concerns: HYPER.md remains the
# plugin-owned marker and full reference; AGENTS.md is a real, user-editable
# file carrying the agent instructions (Codex and friends read it too);
# CLAUDE.md is a symlink to AGENTS.md so Claude reads the same source.
# Pre-existing regular files are the user's — never replaced; the hyper
# section is appended to each once (idempotent: skipped when the file already
# mentions HYPER.md). Existing symlinks are left untouched.
ensure_agent_docs() {
  local root="$1" name="$2"

  if [[ -L "$root/AGENTS.md" ]]; then
    echo "  exists   AGENTS.md (symlink, left untouched)"
  elif [[ -f "$root/AGENTS.md" ]]; then
    if grep -q 'HYPER\.md' "$root/AGENTS.md" 2>/dev/null; then
      echo "  exists   AGENTS.md (already references HYPER.md)"
    else
      agent_docs_section >> "$root/AGENTS.md"
      echo "  updated  AGENTS.md (appended hyper space section)"
    fi
  else
    {
      printf '# %s — agent instructions\n' "$name"
      agent_docs_section
    } > "$root/AGENTS.md"
    echo "  wrote    AGENTS.md"
  fi

  if [[ -L "$root/CLAUDE.md" ]]; then
    echo "  exists   CLAUDE.md (symlink, left untouched)"
  elif [[ -f "$root/CLAUDE.md" ]]; then
    if grep -q 'HYPER\.md' "$root/CLAUDE.md" 2>/dev/null; then
      echo "  exists   CLAUDE.md (already references HYPER.md)"
    else
      agent_docs_section >> "$root/CLAUDE.md"
      echo "  updated  CLAUDE.md (appended hyper space section)"
    fi
  else
    ln -s AGENTS.md "$root/CLAUDE.md"
    echo "  wrote    CLAUDE.md (symlink → AGENTS.md)"
  fi
}

# ensure_auto_memory <settings-file> <memory-dir> <label> — make the settings
# file point autoMemoryDirectory at the space memory, creating it if absent.
# An existing file is merged, never clobbered: only that one key is set, via
# node (JSON.parse/stringify, 2-space) so every other key survives. No node
# means no safe merge, so the file is left alone and the skip is reported —
# a scaffold step must degrade to a message, never break the flow.
ensure_auto_memory() {
  local file="$1" mem="$2" label="$3" rc=0
  if [[ ! -f "$file" ]]; then
    printf '{\n  "autoMemoryDirectory": "%s"\n}\n' "$mem" > "$file"
    echo "  wrote    $label (autoMemoryDirectory)"
    return 0
  fi
  if ! command -v node >/dev/null 2>&1; then
    echo "  skipped  $label (node unavailable; set autoMemoryDirectory manually)"
    return 0
  fi
  node -e '
    const fs = require("fs");
    const [file, dir] = process.argv.slice(1);
    let obj;
    try { obj = JSON.parse(fs.readFileSync(file, "utf8")); } catch { process.exit(4); }
    if (!obj || typeof obj !== "object" || Array.isArray(obj)) process.exit(4);
    if (obj.autoMemoryDirectory === dir) process.exit(3);
    obj.autoMemoryDirectory = dir;
    fs.writeFileSync(file, JSON.stringify(obj, null, 2) + "\n");
  ' "$file" "$mem" 2>/dev/null || rc=$?
  case $rc in
    0) echo "  updated  $label (autoMemoryDirectory)" ;;
    3) echo "  exists   $label (autoMemoryDirectory already set)" ;;
    *) echo "  skipped  $label (could not parse JSON; set autoMemoryDirectory manually)" ;;
  esac
  return 0
}

# Wire the space memory into Claude Code. Auto memory loads only from the
# directory settings.json names in autoMemoryDirectory — nothing under
# .claude/memory/ is ever read on its own. The value must be an absolute path
# (or start with ~/), so it is computed at write time; moving the space means
# re-running adopt --apply to refresh it.
write_settings_json() {
  local root="$1"
  mkdir -p "$root/.hyper/memory" "$root/.claude"
  ensure_auto_memory "$root/.claude/settings.json" "$root/.hyper/memory" \
    ".claude/settings.json"
}

# Same wiring for a worktree. Settings resolve per project root: a session
# inside a worktree reads the worktree's .claude, not the space's, so each
# worktree needs its own pointer. settings.local.json because the file is
# meant to stay untracked — an absolute path there must never reach the
# remote. That convention only held via the user's global gitignore; without
# a matching entry (any CI, any other machine) the file shows up untracked
# and dirty. .git/info/exclude carries the same "never tracked" guarantee as
# a project .gitignore but is worktree-local config, not a working-tree file
# — so adding it cannot itself show up as an untracked path.
write_worktree_settings() {
  local root="$1" wt="$2"
  mkdir -p "$root/.hyper/memory" "$wt/.claude"
  ensure_auto_memory "$wt/.claude/settings.local.json" "$root/.hyper/memory" \
    "${wt#"$root"/}/.claude/settings.local.json"
  local exclude
  exclude="$(git -C "$wt" rev-parse --git-path info/exclude 2>/dev/null)"
  if [[ -n "$exclude" ]]; then
    mkdir -p "$(dirname "$exclude")"
    if [[ ! -f "$exclude" ]] || ! grep -qxF '.claude/settings.local.json' "$exclude"; then
      printf '%s\n' '.claude/settings.local.json' >> "$exclude"
    fi
  fi
}

# Seed the space memory with a note describing the layout, so future sessions
# in this project know the conventions without relying on the hook alone.
# It lives in .hyper/memory/ — the plugin's tool-agnostic metadata home —
# and loads via the autoMemoryDirectory wiring above.
write_memory_seed() {
  local root="$1" name="$2"
  local mem="$root/.hyper/memory"
  mkdir -p "$mem"

  cat > "$mem/hyper-layout.md" <<EOF
---
name: hyper-layout
description: $name uses the hyper bare space layout; worktrees in worktrees/, root is never committed
metadata:
  type: project
---

\`$root\` is a project space, not a checkout. The \`.git\` there is bare and
the worktrees are in \`worktrees/<branch>\`, created via \`wt switch\`.

Local-only directories at the space root: \`data/\` (dumps, fixtures),
\`notes/\` (briefs, handoffs), \`scratch/\` (disposable), \`bin/\` (helper scripts).
None of it is committed or backed up.

**Why:** keeps a single object store across branches and gives local-only files a
home that cannot accidentally be committed.

**How to apply:** never commit from the space root; put new local files in the
matching directory instead of loose at the root. See \`HYPER.md\`.
EOF

  local index="$mem/MEMORY.md"
  if [[ ! -f "$index" ]]; then
    printf '# Memory index\n\n' > "$index"
  fi
  # Rewrite rather than skip-if-present: an interrupted earlier run can leave
  # an index line pointing at a memory file that was never written, and a
  # plain grep would treat that dangling entry as "already done".
  if grep -q 'hyper-layout.md' "$index" 2>/dev/null; then
    # grep -v exits 1 when nothing survives the filter; an index containing
    # only this entry must still be rewritten (to empty), so ignore the exit
    # code and always move the temp file into place.
    grep -v 'hyper-layout.md' "$index" > "$index.tmp" || :
    mv "$index.tmp" "$index"
  fi
  printf -- '- [Space layout](hyper-layout.md) — worktrees/, local-only dirs, root is never committed\n' >> "$index"
}

# Point worktrunk at the space's default branch, and make bare-repo worktrees
# resolve hooks correctly. Idempotent and non-destructive: an explicit
# existing worktrunk.default-branch is never overwritten, since the caller
# may have set it deliberately (e.g. a branch other than HEAD's symbolic ref).
#
# ensure_worktrunk_config <git-dir> <default-branch>
ensure_worktrunk_config() {
  local gitdir="$1" branch="$2"
  if [[ -z "$(git --git-dir="$gitdir" config --get worktrunk.default-branch 2>/dev/null)" ]]; then
    git --git-dir="$gitdir" config worktrunk.default-branch "$branch"
    git --git-dir="$gitdir" config worktrunk.history "$branch"
    echo "  set      worktrunk.default-branch=$branch"
  fi
  # Worktrees created from a bare repo get a .git *file*, so core.hooksPath
  # resolution differs; point it at the shared hooks dir explicitly.
  git --git-dir="$gitdir" config core.hooksPath "$gitdir/hooks"
}

# Create the directory set. Idempotent: reports created vs already-present.
scaffold_dirs() {
  local root="$1" d layout
  layout="$(space_layout "$root" 2>/dev/null)" || layout=""
  for d in "${SPACE_DIRS[@]}"; do
    # A multi-repo space has no worktrees/ at the root — each repo carries its
    # own under code/<slug>/. Creating one here would invent a directory the
    # layout does not have, and audit would then have to explain it away.
    [[ "$layout" == multi && "$d" == worktrees ]] && continue
    local target="$root/$d"
    if [[ -d "$target" ]]; then
      echo "  exists   $d/"
    else
      mkdir -p "$target"
      # A note beats .gitkeep here: it explains the directory to whoever opens
      # it in six months.
      printf '%s\n' "$(dir_purpose "$d")" > "$target/.what-goes-here"
      echo "  created  $d/"
    fi
  done
  # .hyper/ is plugin-managed metadata, not a user-facing dir, so it stays
  # out of SPACE_DIRS — but every scaffold wires the memory settings.
  write_settings_json "$root"
  return 0
}
