#!/usr/bin/env bash
# SessionStart hook: if this session is inside a space, tell Claude how the
# layout works. Silent (exit 0, no output) when not in a space, so the hook
# costs nothing in unrelated projects.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/hyper-lib.sh" 2>/dev/null || exit 0

root="$(find_space_root "$PWD")" || exit 0
name="$(basename "$root")"
layout="$(space_layout "$root" 2>/dev/null)" || layout=bare
wt_abs="$root/worktrees"

# Legacy (pre-rename) spaces may still carry the old marker and metadata dir;
# point at whichever actually exists so the advice is followable as printed.
marker="HYPER.md"
[[ ! -f "$root/HYPER.md" && -f "$root/HYPERDEV.md" ]] && marker="HYPERDEV.md"

# Recommend wt only when it is actually installed; otherwise show the raw
# command so the advice is followable as printed.
if command -v wt >/dev/null 2>&1; then
  wt_make="\`wt switch <branch>\`, not \`git worktree add\`"
else
  wt_make="\`git worktree add worktrees/<branch> <branch>\` (worktrunk's \`wt switch\` automates this)"
fi

# The directory to run toolchain detection against. Only set when cwd maps to
# exactly one working tree — a worktree. The bare root has none, and picking
# one of its worktrees to scan would report an arbitrary branch's toolchain.
tree=""

if [[ "$layout" == multi ]]; then
  # Multi-repo: every position must name the layout, list the repos, and say
  # where `wt switch` works — it resolves a repo from inside code/<slug>/ and
  # nowhere else, which is the mistake this shape invites.
  repos="$(space_repos "$root" | paste -sd, - | sed 's/,/, /g')"
  [[ -n "$repos" ]] || repos="(none)"
  slug="$(repo_slug_of "$root" "$PWD" 2>/dev/null)" || slug=""

  if [[ -n "$slug" && "$PWD" == "$root/code/$slug/worktrees/"* ]]; then
    rest="${PWD#"$root"/code/"$slug"/worktrees/}"
    wt_name="${rest%%/*}"
    tree="$root/code/$slug/worktrees/$wt_name"
    cat <<EOF
Worktree \`$wt_name\` of repo \`$slug\`, in multi-repo space $name ($root).
Repos here: $repos. Normal git applies in this worktree.
Space-level local-only dirs: data/, notes/, scratch/, bin/. Sibling worktrees
of this repo are in $root/code/$slug/worktrees/.
\`wt switch\` runs inside \`code/<slug>/\`, never from the space root.
EOF

  elif [[ -n "$slug" ]]; then
    cat <<EOF
Repo \`$slug\` of multi-repo space $name ($root) — cwd is the repo root, not a
worktree. The .git here is bare; worktrees live in code/$slug/worktrees/<branch>.
Repos here: $repos.

- Do not run git commit/add here. cd into code/$slug/worktrees/<branch> first.
- Create branches with $wt_make — from inside \`code/$slug/\`, which is where
  \`wt switch\` resolves this repo.

See $root/$marker.
EOF

  elif at_space_root; then
    cat <<EOF
Project space: $root (cwd is the space ROOT of a multi-repo space, not a worktree).

The root itself is not a git repository — there is no .git and no worktrees/
at this level, and nothing here is ever committed. Each repo lives in
code/<slug>/ with its own bare .git and its own worktrees/<branch>.

Repos here: $repos.

- Do not run git commit/add here. cd into code/<slug>/worktrees/<branch> first.
- Create branches with $wt_make, run from inside \`code/<slug>/\` — \`wt switch\`
  does not resolve a repo from the space root.
- New local-only files go in: data/ (dumps, fixtures), notes/ (briefs, docs),
  scratch/ (disposable), bin/ (helper scripts) — not loose at the root.

See $root/$marker.
EOF

  else
    rel="${PWD#"$root"/}"
    cat <<EOF
In \`$rel/\` of multi-repo space $name ($root) — a local-only directory, not a
worktree. Nothing here is committed or backed up. Code lives in
$root/code/<slug>/worktrees/<branch>; repos here: $repos.
\`wt switch\` runs inside \`code/<slug>/\`, never from the space root.
EOF
  fi

elif [[ "$PWD" == "$wt_abs"/* ]]; then
  rest="${PWD#"$wt_abs"/}"
  wt_name="${rest%%/*}"
  tree="$wt_abs/$wt_name"
  cat <<EOF
Worktree \`$wt_name\` of space $name ($root).
Space-level local-only dirs: data/, notes/, scratch/, bin/. Sibling
worktrees are in $wt_abs/. Normal git applies here.
EOF

elif at_space_root; then
  # Bare root: the failure modes are real (committing against a bare repo,
  # dumping loose files), so spend the tokens here.
  cat <<EOF
Project space: $root (cwd is the space ROOT, not a worktree).

The .git here is bare — there is no working tree and nothing at this level is
ever committed. Worktrees live in worktrees/<branch>.

- Do not run git commit/add here. cd into worktrees/<branch> first.
- Create branches with $wt_make.
- New local-only files go in: data/ (dumps, fixtures), notes/ (briefs, docs),
  scratch/ (disposable), bin/ (helper scripts) — not loose at the root.

See $root/$marker.
EOF

else
  # Under the space root but not in a worktree: a local-only directory
  # (data/, notes/, scratch/, bin/) — the root is bare, so nothing else
  # exists at this level.
  rel="${PWD#"$root"/}"
  cat <<EOF
In \`$rel/\` of space $name ($root) — a local-only directory, not a
worktree. Nothing here is committed or backed up. Code lives in
$wt_abs/<branch>.
EOF
fi

# Reactive Context: also say HOW to build/lint/test, not just where things
# live. Everything below is best-effort — a detection failure must never break
# session start, and unknown keys are omitted rather than guessed.
if [[ -n "$tree" ]]; then
  facts="$(bash "$(dirname "${BASH_SOURCE[0]}")/hyper-stack.sh" detect "$tree" 2>/dev/null)" || facts=""
  stack="$(sed -n 's/^STACK=//p' <<<"$facts")"
  if [[ -n "$stack" && "$stack" != unknown ]]; then
    pm="$(sed -n 's/^PM=//p' <<<"$facts")"
    [[ "$pm" == unknown ]] && pm=""
    lint_tool="$(sed -n 's/^LINT_TOOL=//p' <<<"$facts")"

    # Node stacks report script names; Go reports full commands. Label the
    # list accordingly so nobody runs `pnpm run go test ./...`.
    entries="" label="Scripts"
    for key in LINT FORMAT TYPECHECK TEST; do
      v="$(sed -n "s/^$key=//p" <<<"$facts")"
      [[ -z "$v" ]] && continue
      [[ "$v" == *" "* ]] && label="Checks"
      entries+="${entries:+, }$v"
    done

    line="Toolchain: $stack${pm:+ ($pm)}."
    [[ -n "$entries" ]] && line+=" $label: $entries."
    [[ -n "$lint_tool" ]] && line+=" Lint tool: $lint_tool."
    echo
    echo "$line"

    # Check-hook status, from the same config the PostToolUse hook reads,
    # with the same precedence: nearest tree first, then the space root.
    # At each location hyper.json wins over the legacy hyperdev.json name —
    # the same fallback hyper-check.sh applies.
    cfg=""
    [[ -f "$tree/.claude/hyper.json" ]] && cfg="$tree/.claude/hyper.json"
    [[ -z "$cfg" && -f "$tree/.claude/hyperdev.json" ]] && cfg="$tree/.claude/hyperdev.json"
    [[ -z "$cfg" && -f "$root/.claude/hyper.json" ]] && cfg="$root/.claude/hyper.json"
    [[ -z "$cfg" && -f "$root/.claude/hyperdev.json" ]] && cfg="$root/.claude/hyperdev.json"
    if [[ -z "$cfg" ]]; then
      echo "No check hook configured — run /hyper:tools to set one up."
    elif command -v node >/dev/null 2>&1; then
      # Summarizes the effective checks only when the hook would actually run
      # something; disabled, command-less, or unparseable configs stay silent.
      # Same precedence as hyper-check.sh: a "checks" array wins over the
      # legacy "check" object, and array entries are on unless enabled:false.
      desc="$(node -e '
        try {
          const cfg = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
          let list = [];
          if (Array.isArray(cfg.checks) && cfg.checks.length) {
            list = cfg.checks.filter(c => c && typeof c === "object" && c.enabled !== false);
          } else if (cfg.check && cfg.check.enabled) {
            list = [cfg.check];
          }
          const names = list.map(c => c.run || c.command).filter(Boolean).map(String);
          if (names.length === 1) process.stdout.write(names[0]);
          else if (names.length > 1)
            process.stdout.write(names.length + " checks: " + names.join(", "));
        } catch (e) {}
      ' "$cfg" 2>/dev/null)" || desc=""
      [[ -n "$desc" ]] && echo "Check hook: ON ($desc)."
    fi
  fi
fi

exit 0
