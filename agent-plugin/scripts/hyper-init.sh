#!/usr/bin/env bash
# Create a new project space — from a git remote, from nothing, or by
# adopting the repo already at cwd. Also grows a multi-repo space by adding
# a repo to it.
# Usage: hyper-init.sh <repo-url> [space-name] [--default-branch <name>]
#        hyper-init.sh --new <space-name>  [--default-branch <name>]
#        hyper-init.sh --multi <space-name> [--default-branch <name>]
#        hyper-init.sh <repo-url> --slug <slug> [--default-branch <name>]
#        hyper-init.sh --new <space-name> --slug <slug> [--default-branch <name>]
#        hyper-init.sh [--apply]

set -euo pipefail
here="$(dirname "${BASH_SOURCE[0]}")"
source "$here/hyper-lib.sh"

repo_url=""
name=""
default_branch=""
new_mode=0
apply=0
multi_mode=0
slug=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --default-branch) default_branch="$2"; shift 2 ;;
    --new) new_mode=1; shift ;;
    --apply) apply=1; shift ;;
    --multi) multi_mode=1; shift ;;
    --slug) slug="$2"; shift 2 ;;
    --layout)
      echo "--layout was removed: spaces are always bare; adopt converts an existing checkout" >&2
      exit 2 ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)
      if [[ -z "$repo_url" ]]; then repo_url="$1"
      elif [[ -z "$name" ]]; then name="$1"
      else echo "unexpected argument: $1" >&2; exit 2
      fi
      shift ;;
  esac
done

# ---------------------------------------------------------------------------
# --multi: create an empty multi-repo space. Its own branch — no repo/name
# ambiguity with the single-repo modes below.
# ---------------------------------------------------------------------------
if [[ $multi_mode -eq 1 ]]; then
  if [[ -n "$slug" ]]; then
    echo "--multi creates the space; use --slug on a later run to add a repo" >&2
    exit 2
  fi
  if [[ -n "$name" ]]; then
    echo "unexpected argument: $name (--multi takes only a space name)" >&2
    exit 2
  fi
  name="$repo_url"
  if [[ -z "$name" ]]; then
    echo "usage: hyper-init.sh --multi <space-name> [--default-branch <name>]" >&2
    exit 2
  fi
  root="$PWD/$name"
  if [[ -e "$root" ]] && [[ -n "$(find "$root" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
    echo "refusing to use non-empty path: $root" >&2
    exit 1
  fi

  echo "Creating multi-repo space: $root"
  mkdir -p "$root/code" "$root/.claude"

  # Marker before scaffold: space_layout (and so scaffold_dirs's own
  # auto-detection of "no root worktrees/") needs HYPER.md + code/ to
  # recognize the multi shape, and both already exist at this point.
  write_hyper_md_multi "$root" "$name"
  scaffold_dirs "$root"
  ensure_agent_docs "$root" "$name"
  write_memory_seed "$root" "$name"

  echo
  echo "Space ready: $root"
  echo
  echo "Next steps:"
  echo "  cd $root"
  echo "  hyper init <repo-url> --slug <slug>   add a repo to this space"
  echo "  hyper init --new <name> --slug <slug> add a brand-new repo to this space"
  exit 0
fi

# ---------------------------------------------------------------------------
# --slug: add a repo to an existing multi-repo space. Requires running from
# inside one (root, a local-only dir, or anywhere under code/).
# ---------------------------------------------------------------------------
if [[ -n "$slug" ]]; then
  if ! valid_slug "$slug"; then
    echo "invalid slug: $slug (must match [a-z0-9][a-z0-9._-]*)" >&2
    exit 2
  fi

  # space_layout recognizes an empty --multi space (marker + no .git + code/
  # dir) without needing a repo under code/ yet, so find_space_root works for
  # the very first --slug on a freshly-created space the same as any other.
  space_root="$(find_space_root "$PWD")" || {
    echo "not inside a multi-repo space (no HYPER.md + code/ found)" >&2
    echo "use hyper-init.sh --multi <name> to create one first" >&2
    exit 1
  }
  if [[ "$(space_layout "$space_root" 2>/dev/null)" != multi ]]; then
    echo "$space_root is a bare (single-repo) space — --slug only applies to multi-repo spaces" >&2
    exit 1
  fi

  repo_dir="$space_root/code/$slug"
  if [[ -e "$repo_dir" ]]; then
    echo "refusing: code/$slug already exists" >&2
    exit 1
  fi

  if [[ $new_mode -eq 1 ]]; then
    if [[ -n "$name" ]]; then
      echo "unexpected argument: $name (--new --slug takes no space name)" >&2
      exit 2
    fi
    [[ -z "$default_branch" ]] && default_branch=main
    if ! { git config user.name >/dev/null && git config user.email >/dev/null; }; then
      echo "git user.name/user.email not configured — set them first:" >&2
      echo "  git config --global user.name 'Your Name'" >&2
      echo "  git config --global user.email you@example.com" >&2
      exit 1
    fi
    echo "Adding repo $slug (new, empty) to $space_root"
    mkdir -p "$repo_dir"
    git init -q --bare -b "$default_branch" "$repo_dir/.git"
    tree="$(git --git-dir="$repo_dir/.git" mktree </dev/null)"
    commit="$(git --git-dir="$repo_dir/.git" commit-tree "$tree" -m "chore: initial commit")"
    git --git-dir="$repo_dir/.git" update-ref "refs/heads/$default_branch" "$commit"
  elif [[ -n "$repo_url" ]]; then
    echo "Adding repo $slug (clone of $repo_url) to $space_root"
    mkdir -p "$repo_dir"
    git clone --bare "$repo_url" "$repo_dir/.git"
    git --git-dir="$repo_dir/.git" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    git --git-dir="$repo_dir/.git" fetch origin
    if [[ -z "$default_branch" ]]; then
      default_branch="$(git --git-dir="$repo_dir/.git" symbolic-ref --short HEAD 2>/dev/null || echo main)"
    fi
  else
    echo "usage: hyper-init.sh <repo-url> --slug <slug> [--default-branch <name>]" >&2
    echo "       hyper-init.sh --new <name> --slug <slug> [--default-branch <name>]" >&2
    exit 2
  fi

  ensure_worktrunk_config "$repo_dir/.git" "$default_branch"

  echo "Creating worktree for $default_branch..."
  if command -v wt >/dev/null 2>&1; then
    ( cd "$repo_dir" && wt switch "$default_branch" ) || {
      echo "  wt failed; falling back to git worktree add" >&2
      git --git-dir="$repo_dir/.git" worktree add "$repo_dir/worktrees/$default_branch" "$default_branch"
    }
  else
    git --git-dir="$repo_dir/.git" worktree add "$repo_dir/worktrees/$default_branch" "$default_branch"
  fi

  if [[ -d "$repo_dir/worktrees/$default_branch" ]]; then
    write_worktree_settings "$space_root" "$repo_dir/worktrees/$default_branch"
  fi

  add_repo_row_to_hyper_md "$space_root" "$slug" || \
    echo "  skipped  HYPER.md Repositories row (edit it manually)" >&2

  echo
  echo "Repo ready: $repo_dir"
  echo
  echo "Next steps:"
  echo "  cd $repo_dir/worktrees/$default_branch"
  exit 0
fi

# No repo/name given at all: cwd itself may already be a repo (bare space or
# an ordinary checkout) that the user meant to bring into the layout, rather
# than a brand-new space to create beneath it. Delegate to adopt, which
# already does this safely (dry run by default, verified conversion). --apply
# only makes sense in this branch — it is adopt's flag, not clone/--new's.
if [[ $new_mode -eq 0 && -z "$repo_url" && -z "$name" ]]; then
  if git rev-parse --git-dir >/dev/null 2>&1; then
    if [[ "$(git config --get core.bare 2>/dev/null)" == "true" ]]; then
      # Bare: cwd is already the space (or a plain bare repo opting in) —
      # adopt's case A does not move anything, so no need to leave it.
      target="$PWD"
    else
      # An ordinary checkout: conversion moves everything under cwd into
      # worktrees/<branch>/, which a live shell sitting inside it would not
      # survive. Resolve the target before leaving it, then cd out so
      # adopt's own preflight (which refuses cwd-inside-target) passes.
      target="$(git rev-parse --show-toplevel)"
      cd ..
    fi
    if [[ $apply -eq 1 ]]; then
      exec bash "$here/hyper-adopt.sh" "$target" --apply
    else
      exec bash "$here/hyper-adopt.sh" "$target"
    fi
  fi
  echo "usage: hyper-init.sh <repo-url> [space-name] [--default-branch <name>]" >&2
  echo "       hyper-init.sh --new <space-name>  [--default-branch <name>]" >&2
  echo "       hyper-init.sh [--apply]           # adopt the repo at cwd" >&2
  exit 2
fi

if [[ $apply -eq 1 ]]; then
  echo "--apply only applies with no other arguments (adopting cwd)" >&2
  exit 2
fi

if [[ $new_mode -eq 1 ]]; then
  # --new takes a name, not a url. The positional slot is shared, so a second
  # positional is a usage error rather than a silently ignored value.
  if [[ -n "$name" ]]; then
    echo "unexpected argument: $name (--new takes only a space name)" >&2
    exit 2
  fi
  name="$repo_url"
  repo_url=""
  if [[ -z "$name" ]]; then
    echo "usage: hyper-init.sh --new <space-name> [--default-branch <name>]" >&2
    exit 2
  fi
elif [[ -z "$repo_url" ]]; then
  echo "usage: hyper-init.sh <repo-url> [space-name] [--default-branch <name>]" >&2
  echo "       hyper-init.sh --new <space-name>  [--default-branch <name>]" >&2
  exit 2
fi

# Derive space name from the repo when not given: strip .git and any path.
if [[ -z "$name" ]]; then
  name="$(basename "$repo_url" .git)"
fi

root="$PWD/$name"

if [[ -e "$root" ]]; then
  echo "refusing to overwrite existing path: $root" >&2
  exit 1
fi

# A brand-new repo needs an initial commit (a worktree cannot exist without
# one), and committing needs an identity. Check before creating anything, so
# a missing identity cannot leave a half-built space behind.
if [[ $new_mode -eq 1 ]] && ! { git config user.name >/dev/null && git config user.email >/dev/null; }; then
  echo "git user.name/user.email not configured — set them first:" >&2
  echo "  git config --global user.name 'Your Name'" >&2
  echo "  git config --global user.email you@example.com" >&2
  exit 1
fi

echo "Creating space: $root"

mkdir -p "$root"

if [[ $new_mode -eq 1 ]]; then
  [[ -z "$default_branch" ]] && default_branch=main
  echo "Initializing empty bare repository..."
  git init -q --bare -b "$default_branch" "$root/.git"

  # Seed an empty initial commit so the default-branch worktree can exist.
  tree="$(git --git-dir="$root/.git" mktree </dev/null)"
  commit="$(git --git-dir="$root/.git" commit-tree "$tree" -m "chore: initial commit")"
  git --git-dir="$root/.git" update-ref "refs/heads/$default_branch" "$commit"
else
  echo "Cloning bare repository..."
  git clone --bare "$repo_url" "$root/.git"

  # A bare clone fetches only refs/heads/* into refs/heads/*, which leaves no
  # remote-tracking branches. Set the standard fetch refspec so `git fetch`,
  # `wt`, and branch tracking behave like a normal clone.
  git --git-dir="$root/.git" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  git --git-dir="$root/.git" fetch origin

  # Determine the default branch from the remote HEAD unless overridden.
  if [[ -z "$default_branch" ]]; then
    default_branch="$(git --git-dir="$root/.git" symbolic-ref --short HEAD 2>/dev/null || echo main)"
  fi
fi
ensure_worktrunk_config "$root/.git" "$default_branch"

echo "Scaffolding directories..."
mkdir -p "$root/.claude"
scaffold_dirs "$root"

write_hyper_md "$root" "$name"
ensure_agent_docs "$root" "$name"
write_memory_seed "$root" "$name"

echo "Creating worktree for $default_branch..."
if command -v wt >/dev/null 2>&1; then
  # `switch` creates the worktree if it does not exist. No -c: the branch
  # already exists from the clone. -C runs wt against the space so the
  # user's `{{ repo_path }}/../worktrees/` template resolves inside it.
  wt -C "$root" switch "$default_branch" || {
    echo "  wt failed; falling back to git worktree add" >&2
    git --git-dir="$root/.git" worktree add "$root/worktrees/$default_branch" "$default_branch"
  }
else
  git --git-dir="$root/.git" worktree add "$root/worktrees/$default_branch" "$default_branch"
fi

# Settings resolve per project root, so the worktree needs its own pointer at
# the space memory. Guarded: wt may have placed the worktree elsewhere, and a
# missed pointer must not break init.
if [[ -d "$root/worktrees/$default_branch" ]]; then
  write_worktree_settings "$root" "$root/worktrees/$default_branch"
fi

echo
echo "Space ready: $root"
echo
echo "Next steps:"
echo "  cd $root/worktrees/$default_branch"
echo "  /hyper:tools   wire the project's linter/typechecker into the check hook"
if [[ $new_mode -eq 1 ]]; then
  echo "  no remote yet — when one exists:"
  echo "    git --git-dir=$root/.git remote add origin <url>"
  echo "    git --git-dir=$root/.git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'"
fi
