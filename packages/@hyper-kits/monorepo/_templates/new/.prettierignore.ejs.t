---
to: .prettierignore
condition: formatter === 'prettier'
---
# Dependencies and lock files
node_modules/
<% if (packageManager === 'bun') { -%>
bun.lockb
<% } else if (packageManager === 'npm') { -%>
package-lock.json
<% } else if (packageManager === 'yarn') { -%>
yarn.lock
<% } else if (packageManager === 'pnpm') { -%>
pnpm-lock.yaml
<% } -%>

# Build outputs
dist/
build/
coverage/
.moon/
*.tsbuildinfo

# Generated files
**/*.min.js
**/*.min.css
**/*.bundle.js

<% if (testFramework === 'jest') { -%>
# Test snapshots (should be formatted but excluded for safety)
# **/__snapshots__/**
<% } -%>

# Logs and temporary files
*.log
.DS_Store
.env*
!.env.example

# IDE and editor files
.vscode/
.idea/

# OS generated files
Thumbs.db

# Documentation that should maintain specific formatting
CHANGELOG.md
CONTRIBUTING.md