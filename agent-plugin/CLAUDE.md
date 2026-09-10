# agent-plugin — rules for working on the hyper plugin

The plugin in this directory ships to users through the `svallory-plugins`
Claude Code marketplace (a `git-subdir` pointer at this path on `main`).
It is bash + markdown with its own test suite and CI — the monorepo's
moon/bun toolchain is not involved.

## Hard rules

- **Never develop in `~/.claude/plugins/marketplaces/`.** That clone
  auto-updates and will discard uncommitted work. Develop here, commit, push.
- **Run `agent-plugin/tests/run.sh` before committing.** 487 assertions;
  `.github/workflows/agent-plugin.yml` enforces the same suite plus
  `bash -n` and `shellcheck --severity=warning` in CI.
- **Test hooks by piping real hook JSON into the script** — never by running
  the command in your shell, which has an environment hooks don't inherit
  (proto/mise/nvm shims, homebrew PATH):

  ```bash
  echo '{"tool_input":{"file_path":"/abs/path/to/real.ts"}}' \
    | bash agent-plugin/scripts/hyper-check.sh; echo "exit=$?"
  ```

  A hook proves itself with exit 2 on a deliberate error. Exit 0 alone is
  not evidence — a build-cache replay or a silent decline also exits 0.
- **Detection emits only what is verifiable.** Absence means unknown; never
  add a fallback default. A wrong check command fails on every edit and
  trains users to ignore the hook — worse than no check.
- **Nothing deletes or moves user files automatically.** The two exceptions
  are explicit: `adopt --apply` converts (plan first, four verified
  data-safety guarantees), and `/hyper:cleanup` deletes only per-item
  confirmed, re-verified ids.
- **Renames are breaking changes.** The marketplace entry name, command
  prefix, `HYPER.md` marker, `.hyper/` dir, and `.claude/hyper.json` are
  user-facing contract; legacy `hyperdev` names must stay recognized (see
  `tests/test-l-legacy.sh`).

## Process

- After any substantial change, re-run the clean-room test: give a
  context-free subagent only the goal and this plugin's path, pointed at a
  **messy real project** (live databases, build caches, stray files) — not a
  clean fixture. Treat its findings as hypotheses; reproduce before acting.
  `docs/build-report.md` records both the process and the times it caught
  real bugs (and the times a confident finding was simply wrong).
- Domain language lives in `docs/concepts.md`; the improvement backlog in
  `TODO.md`. Keep both current — vocabulary drift was a real, recurring bug
  source.
