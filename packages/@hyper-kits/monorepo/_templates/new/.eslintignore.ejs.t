---
to: .eslintignore
condition: linter === 'eslint'
---
# Dependencies
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
**/*.d.ts
!src/**/*.d.ts

# Configuration files that may have different rules
*.config.js
*.config.mjs
babel.config.js
prettier.config.js

# Logs and temporary files
*.log
.DS_Store
.env*
!.env.example

# IDE and editor files
.vscode/
.idea/
*.swp
*.swo

# OS generated files
Thumbs.db