---
to: .husky/pre-commit
condition: setupGitHooks === true
---
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Run Moon tasks on affected files
echo "🌚 Running pre-commit hooks..."

<% if (linter === 'eslint' || linter === 'biome') { -%>
echo "⚡ Running linting..."
moon run :lint --affected --concurrency 4 || exit 1

<% } -%>
<% if (formatter === 'prettier' || formatter === 'dprint' || formatter === 'biome-integrated') { -%>
echo "🎨 Running formatting..."
moon run :format --affected --concurrency 4 || exit 1

<% } -%>
echo "🔍 Running type checking..."
moon run :typecheck --affected --concurrency 4 || exit 1

echo "✅ Pre-commit hooks passed!"