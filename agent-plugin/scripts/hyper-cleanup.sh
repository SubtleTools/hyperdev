#!/usr/bin/env bash
# The one command in the plugin that deletes anything. Everything else reports;
# this executes — and only what audit already classifies as debris, only for
# ids named explicitly with --delete, each re-verified at the moment of
# deletion. A stale listing is never trusted: an id that no longer matches its
# candidate class is refused, not deleted.
#
# Usage: hyper-cleanup.sh [space-root] [--delete <id>]... [-i|--interactive]
#
#   no --delete    LIST mode: enumerate deletion candidates with stable ids,
#                  sizes, and evidence. Deletes nothing. Exits 0.
#   --delete <id>  delete exactly that item (repeatable). Exit 0 when every
#                  named id was deleted, 1 when any was refused.
#   -i             interactive: list, then confirm each candidate y/N at the
#                  terminal and delete what was approved. Needs a tty — an
#                  agent session has none and must use AskUserQuestion +
#                  --delete instead.
#
# There is deliberately no --all flag, and there never will be. Interactive
# mode preserves the per-item contract: one question per candidate, default
# No, never a bulk yes.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/hyper-lib.sh"

root=""
delete_ids=()
interactive=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete)
      [[ $# -ge 2 ]] || { echo "--delete requires an id" >&2; exit 1; }
      delete_ids+=("$2")
      shift 2
      ;;
    -i|--interactive)
      interactive=1
      shift
      ;;
    --*)
      echo "unknown flag: $1" >&2
      exit 1
      ;;
    *)
      if [[ -n "$root" ]]; then
        echo "unexpected argument: $1" >&2
        exit 1
      fi
      root="$1"
      shift
      ;;
  esac
done

if [[ -z "$root" ]]; then
  root="$(find_space_root "$PWD")" || {
    echo "not inside a space (no bare .git + worktrees/ found)" >&2
    echo "pass a path explicitly" >&2
    exit 1
  }
fi
root="$(cd "$root" && pwd)"

layout="$(space_layout "$root" 2>/dev/null)" || layout=""

# A multi-repo space root is deliberately not a git repository — the repos
# live under code/<slug>. Only the bare layout must answer to git here.
if [[ "$layout" != multi ]] && ! git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
  echo "not a git repository: $root" >&2
  exit 1
fi

# The repos to iterate, and the id prefix each one contributes. A bare space
# is one unnamed repo at the root with no prefix, so single-repo ids stay
# exactly as they were; a multi-repo space names every id with its slug.
#
#   bare  -> REPO_DIRS=("$root")            REPO_SLUGS=("")
#   multi -> REPO_DIRS=(.../code/<slug>)    REPO_SLUGS=(<slug>)
REPO_DIRS=()
REPO_SLUGS=()
if [[ "$layout" == multi ]]; then
  while IFS= read -r s; do
    [[ -n "$s" ]] || continue
    REPO_DIRS+=("$root/code/$s")
    REPO_SLUGS+=("$s")
  done < <(space_repos "$root")
else
  REPO_DIRS=("$root")
  REPO_SLUGS=("")
fi

# repo_dir_for_slug <slug> — the repo dir an id's slug names, or failure when
# no such repo exists. "" is the bare space's single unnamed repo.
repo_dir_for_slug() {
  local want="$1" i
  for i in "${!REPO_SLUGS[@]}"; do
    if [[ "${REPO_SLUGS[$i]}" == "$want" ]]; then
      echo "${REPO_DIRS[$i]}"
      return 0
    fi
  done
  return 1
}

if [[ $interactive -eq 1 && ${#delete_ids[@]} -gt 0 ]]; then
  echo "-i and --delete are mutually exclusive: interactive mode asks, --delete already knows" >&2
  exit 1
fi
# Interactive confirmation is a terminal conversation. Without a tty the
# prompts would read EOF and silently answer No to everything — refuse
# loudly instead so a scripted caller notices the mistake.
if [[ $interactive -eq 1 ]] && ! [[ -t 0 && -t 1 ]]; then
  echo "interactive mode needs a terminal; in an agent session confirm per item and use --delete <id>" >&2
  exit 2
fi

# --- shared classification --------------------------------------------------
# List mode and delete mode go through the same functions, so a --delete is
# re-verified with exactly the checks that nominated the candidate.

size_of() { du -sh "$1" 2>/dev/null | cut -f1 || echo '?'; }

# Registered worktree paths, compared physically (macOS /var vs /private/var).
# A live registered worktree must never be deleted, whatever its .git looks
# like at the moment of the check.
# Checked against every repo in the space: a path registered by any of them is
# live, whichever repo owns it.
is_registered_worktree() {
  local target p rd
  target="$(cd "$1" 2>/dev/null && pwd -P)" || target="$1"
  for rd in "${REPO_DIRS[@]}"; do
    while IFS= read -r p; do
      [[ -n "$p" ]] || continue
      p="$(cd "$p" 2>/dev/null && pwd -P || echo "$p")"
      [[ "$p" == "$target" ]] && return 0
    done < <(git --git-dir="$rd/.git" worktree list --porcelain 2>/dev/null \
               | sed -n 's/^worktree //p')
  done
  return 1
}

# Same classification hyper-audit.sh uses for worktrees/ entries: live,
# orphan (a .git file whose gitdir is gone), or leftover build output with no
# .git at all. Cleanup adds "missing" and treats anything else as live.
# classify_worktree_entry <name> [repo-dir]
classify_worktree_entry() {
  local w="${2:-$root}/worktrees/$1" wgd
  [[ -d "$w" ]] || { echo missing; return 0; }
  if [[ ! -e "$w/.git" ]]; then
    echo leftover
  elif [[ -f "$w/.git" ]] \
       && wgd="$(sed -n 's/^gitdir: //p' "$w/.git" 2>/dev/null)" \
       && [[ -n "$wgd" && ! -d "$wgd" ]]; then
    echo orphan
  else
    echo live
  fi
}

# branch_exists <name> [repo-dir]
branch_exists() {
  git --git-dir="${2:-$root}/.git" show-ref --verify -q "refs/heads/$1"
}

# "[gone]" from %(upstream:track) — the same signal audit reads.
# branch_upstream_gone <name> [repo-dir]
branch_upstream_gone() {
  local t
  t="$(git --git-dir="${2:-$root}/.git" for-each-ref \
         --format='%(upstream:track)' "refs/heads/$1" 2>/dev/null)" || return 1
  [[ "$t" == "[gone]" ]]
}

# Split a worktree:/branch: id name into slug and bare name. In a multi-repo
# space the id carries the slug ("worktree:<slug>/<name>"); in a bare space it
# never does, so single-repo ids keep working unchanged. Sets id_slug and
# id_name.
split_slug_name() {
  id_slug=""
  id_name="$1"
  if [[ "$layout" == multi && "$1" == */* ]]; then
    id_slug="${1%%/*}"
    id_name="${1#*/}"
  fi
}

# Entry names for worktree:/parked: ids are single path components under a
# fixed parent. Anything else (slash, dot-prefix, empty) is refused rather
# than resolved — an id must never be able to point outside its class's dir.
valid_entry_name() {
  case "$1" in
    ""|.|..|*/*|.*|*$'\n'*) return 1 ;;
    *) return 0 ;;
  esac
}

backup_file="$root/.claude/MEMORY.md.hyper-orig"
preflight_file="$root/.hyper-convert.preflight"

# --- LIST mode --------------------------------------------------------------

if [[ ${#delete_ids[@]} -eq 0 ]]; then
  lines=()
  cand_ids=()
  cand() { cand_ids+=("$1"); lines+=("$(printf '%-26s %-8s %s' "$1" "$2" "$3")"); }

  # One pass per repo. The id gains a "<slug>/" prefix only in a multi-repo
  # space, so ids in a single-repo space are byte-identical to before.
  for i in "${!REPO_DIRS[@]}"; do
    rd="${REPO_DIRS[$i]}"
    pfx="${REPO_SLUGS[$i]:+${REPO_SLUGS[$i]}/}"
    [[ -d "$rd/worktrees" ]] || continue
    for w in "$rd/worktrees"/*/; do
      [[ -d "$w" ]] || continue
      wname="$(basename "$w")"
      case "$(classify_worktree_entry "$wname" "$rd")" in
        orphan)   cand "worktree:$pfx$wname" "$(size_of "$w")" "ORPHANED worktree — gitdir missing" ;;
        leftover) cand "worktree:$pfx$wname" "$(size_of "$w")" "no .git — leftover build output" ;;
      esac
    done
  done

  if [[ -d "$root/.claude/worktrees" ]]; then
    for w in "$root/.claude/worktrees"/*/; do
      [[ -d "$w" ]] || continue
      wname="$(basename "$w")"
      is_registered_worktree "$w" && continue
      cand "parked:$wname" "$(size_of "$w")" "parked by conversion under .claude/worktrees/ — not a registered worktree"
    done
  fi

  [[ -f "$backup_file" ]] \
    && cand "backup:memory-index" "$(size_of "$backup_file")" ".claude/MEMORY.md.hyper-orig — pre-conversion memory index backup"

  [[ -f "$preflight_file" ]] \
    && cand "evidence:preflight" "$(size_of "$preflight_file")" ".hyper-convert.preflight — conversion capture; reconcile before deleting"

  for i in "${!REPO_DIRS[@]}"; do
    rd="${REPO_DIRS[$i]}"
    pfx="${REPO_SLUGS[$i]:+${REPO_SLUGS[$i]}/}"
    while IFS= read -r b; do
      [[ -n "$b" ]] || continue
      cand "branch:$pfx$b" "-" "local branch whose upstream is gone from the remote"
    done < <(git --git-dir="$rd/.git" for-each-ref \
               --format='%(refname:short) %(upstream:track)' refs/heads 2>/dev/null \
             | sed -n 's/ \[gone\]$//p' || true)
  done

  if [[ -d "$root/scratch" ]]; then
    # .what-goes-here is scaffold, not user content — a pristine scratch/ is
    # not a cleanup candidate.
    n="$(find "$root/scratch" -mindepth 1 -maxdepth 1 ! -name .what-goes-here 2>/dev/null | wc -l | tr -d ' ')"
    [[ "$n" -gt 0 ]] \
      && cand "scratch:contents" "$(size_of "$root/scratch")" "$n entr$([[ "$n" -eq 1 ]] && echo y || echo ies) in scratch/ (the directory itself stays)"
  fi

  echo "Space:  $root"
  echo
  if [[ ${#lines[@]} -eq 0 ]]; then
    echo "Nothing to clean."
    exit 0
  fi
  if [[ $interactive -eq 0 ]]; then
    echo "Deletion candidates — nothing has been deleted; this is a list."
    echo "Delete with --delete <id>, one id per item, after the user confirms each."
    echo
    for line in "${lines[@]}"; do echo "  $line"; done
    exit 0
  fi

  # Interactive: one question per candidate, default No. The approved ids run
  # through the exact same delete path as --delete, re-verification included.
  echo "Deletion candidates — you will be asked about each one. Default is No."
  echo
  i=0
  for line in "${lines[@]}"; do
    echo "  $line"
    printf '  delete %s? [y/N] ' "${cand_ids[$i]}"
    IFS= read -r answer || answer=""
    case "$answer" in
      y|Y|yes|YES) delete_ids+=("${cand_ids[$i]}") ;;
    esac
    echo
    i=$((i + 1))
  done

  if [[ ${#delete_ids[@]} -eq 0 ]]; then
    echo "Nothing selected; nothing deleted."
    exit 0
  fi
fi

# --- DELETE mode ------------------------------------------------------------

deleted=0
refused=0
refuse() {
  echo "refused $1: $2"
  refused=$((refused + 1))
}

for id in "${delete_ids[@]}"; do
  class="${id%%:*}"
  name="${id#*:}"
  if [[ "$class" == "$id" ]]; then
    refuse "$id" "not an id — ids look like class:name and come from list mode"
    continue
  fi

  case "$class" in
    worktree)
      split_slug_name "$name"
      if ! rd="$(repo_dir_for_slug "$id_slug")"; then
        refuse "$id" "no repo '$id_slug' in this space"
        continue
      fi
      if ! valid_entry_name "$id_name"; then
        refuse "$id" "invalid entry name"
        continue
      fi
      w="$rd/worktrees/$id_name"
      kind="$(classify_worktree_entry "$id_name" "$rd")"
      if [[ "$kind" == "missing" ]]; then
        refuse "$id" "no such entry under ${id_slug:+code/$id_slug/}worktrees/"
        continue
      fi
      if [[ "$kind" == "live" ]] || is_registered_worktree "$w"; then
        refuse "$id" "LIVE registered worktree — cleanup never deletes a live worktree; use git worktree remove deliberately if you mean it"
        continue
      fi
      sz="$(size_of "$w")"
      rm -rf "$w"
      # An orphan leaves stale metadata under .git/worktrees; drop it so
      # `git worktree list` matches reality again.
      if [[ "$kind" == "orphan" ]]; then
        git --git-dir="$rd/.git" worktree prune 2>/dev/null || true
      fi
      echo "deleted $id ($sz)"
      deleted=$((deleted + 1))
      ;;

    parked)
      if ! valid_entry_name "$name"; then
        refuse "$id" "invalid entry name"
        continue
      fi
      p="$root/.claude/worktrees/$name"
      if [[ ! -d "$p" ]]; then
        refuse "$id" "no such parked entry under .claude/worktrees/"
        continue
      fi
      if is_registered_worktree "$p"; then
        refuse "$id" "registered worktree — not a parked leftover"
        continue
      fi
      sz="$(size_of "$p")"
      rm -rf "$p"
      echo "deleted $id ($sz)"
      deleted=$((deleted + 1))
      ;;

    backup)
      if [[ "$name" != "memory-index" ]]; then
        refuse "$id" "unknown backup id (only backup:memory-index exists)"
        continue
      fi
      if [[ ! -f "$backup_file" ]]; then
        refuse "$id" "not present (.claude/MEMORY.md.hyper-orig)"
        continue
      fi
      sz="$(size_of "$backup_file")"
      rm -f "$backup_file"
      echo "deleted $id ($sz)"
      deleted=$((deleted + 1))
      ;;

    evidence)
      if [[ "$name" != "preflight" ]]; then
        refuse "$id" "unknown evidence id (only evidence:preflight exists)"
        continue
      fi
      if [[ ! -f "$preflight_file" ]]; then
        refuse "$id" "not present (.hyper-convert.preflight)"
        continue
      fi
      sz="$(size_of "$preflight_file")"
      rm -f "$preflight_file"
      echo "deleted $id ($sz)"
      deleted=$((deleted + 1))
      ;;

    branch)
      # A branch name may itself contain slashes (feat/x), so the slug is
      # split off only when it names a real repo — otherwise the whole string
      # is the branch name in the space's single repo.
      split_slug_name "$name"
      if ! rd="$(repo_dir_for_slug "$id_slug")"; then
        if [[ "$layout" == multi ]]; then
          refuse "$id" "no repo '$id_slug' in this space"
          continue
        fi
        rd="$root"
        id_name="$name"
      fi
      if ! git check-ref-format --branch "$id_name" >/dev/null 2>&1; then
        refuse "$id" "invalid branch name"
        continue
      fi
      if ! branch_exists "$id_name" "$rd"; then
        refuse "$id" "no such local branch"
        continue
      fi
      if ! branch_upstream_gone "$id_name" "$rd"; then
        refuse "$id" "upstream is not gone — not a cleanup candidate"
        continue
      fi
      sha="$(git --git-dir="$rd/.git" rev-parse --short "refs/heads/$id_name" 2>/dev/null || echo '?')"
      # -d only, never -D: git's merged-ness check is the safety here. If -d
      # refuses, the branch has commits nothing else reaches — a human call.
      if out="$(git --git-dir="$rd/.git" branch -d -- "$id_name" 2>&1)"; then
        echo "deleted $id (was $sha)"
        deleted=$((deleted + 1))
      else
        case "$out" in
          *"not fully merged"*)
            refuse "$id" "contains commits not on any other branch — refusing; delete manually with git branch -D $name if you are sure" ;;
          *)
            refuse "$id" "git refused: $out" ;;
        esac
      fi
      ;;

    scratch)
      if [[ "$name" != "contents" ]]; then
        refuse "$id" "unknown scratch id (only scratch:contents exists)"
        continue
      fi
      s="$root/scratch"
      if [[ ! -d "$s" ]]; then
        refuse "$id" "no scratch/ directory"
        continue
      fi
      n="$(find "$s" -mindepth 1 -maxdepth 1 ! -name .what-goes-here 2>/dev/null | wc -l | tr -d ' ')"
      if [[ "$n" -eq 0 ]]; then
        refuse "$id" "scratch/ is already empty"
        continue
      fi
      sz="$(size_of "$s")"
      # Contents only — the directory itself is part of the space scaffold,
      # and so is its .what-goes-here note. Report success only when the
      # recount proves the deletion happened.
      find "$s" -mindepth 1 -maxdepth 1 ! -name .what-goes-here \
        -exec rm -rf -- {} + 2>/dev/null || true
      left="$(find "$s" -mindepth 1 -maxdepth 1 ! -name .what-goes-here 2>/dev/null | wc -l | tr -d ' ')"
      if [[ "$left" -gt 0 ]]; then
        refuse "$id" "$left of $n entries could not be removed"
        continue
      fi
      echo "deleted $id ($n entries, $sz)"
      deleted=$((deleted + 1))
      ;;

    *)
      refuse "$id" "unknown id class '$class' — ids come from list mode"
      ;;
  esac
done

echo
echo "Summary: $deleted deleted, $refused refused."
[[ $refused -eq 0 ]] && exit 0
exit 1
